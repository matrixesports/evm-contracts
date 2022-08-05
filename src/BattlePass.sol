// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Rewards.sol";

/**
 * @dev stores info for each level
 * xpToCompleteLevel: xp required to levelup, x->x+1;
 * at the final level the xpToCompleteLevel must be 0
 * freeReward: free reward id to give at level x
 * premiumReward: premium reward id to give at level x
 * use lootbox (with 1 lootboxOption) to give multiple rewards at level x
 */
struct LevelInfo {
    uint256 xpToCompleteLevel;
    uint256 freeRewardId;
    uint256 freeRewardQty;
    uint256 premiumRewardId;
    uint256 premiumRewardQty;
}

/**
 * @dev stores user info
 * xp: user's xp
 * claimedPremiumPass: set to true when the user claims their *first* premium reward
 * user can claim premium rewards when claimedPremiumPass is true or when the user owns a premium pass
 * if a user owns a premium pass and claims their first premium reward,
 * it is burned and claimedPremiumPass is set to true.
 * if the user owns a premium pass and claimedPremiumPass is true, then no premium pass gets burned
 * this is because a user cannot sell the premium pass after redeeming premium rewards
 * claimed: true when reward is claimed at level and status {free or prem}
 */
struct User {
    uint256 xp;
    bool claimedPremiumPass;
    // level->prem?->claimed?
    mapping(uint256 => mapping(bool => bool)) claimed;
}

/// @dev use when an error occurrs while creating a new season
error IncorrectSeasonDetails();

/// @dev use when user claims a reward for a level at which they are NOT
error NotAtLevelNeededToClaimReward();

/// @dev use when user claims a premium reward without owning a premium pass or claimedPremiumPass is false
error NeedPremiumPassToClaimPremiumReward();

/// @dev use when user claims an already claimed reward
error RewardAlreadyClaimed();

/**
 * @title A Battle Pass
 * @author rayquaza7
 * @notice
 * Battle Pass is a system that rewards users for completing creator specific quests
 * during established time periods known as seasons
 * Each creator gets 1 unique Battle Pass and the contract allows multiple seasons
 * Tracks user progress at each level and across seasons
 * Allows for giving out rewards at specified levels
 * Rewards can be { NFTs, Tokens, Lootboxes, Redeemables }
 */
contract BattlePass is Rewards {
    /// @dev current active seasonId
    uint256 public seasonId;

    /// @dev seasonId->level->LevelInfo
    mapping(uint256 => mapping(uint256 => LevelInfo)) public seasonInfo;

    /// @dev user->seasonId->User
    mapping(address => mapping(uint256 => User)) public userInfo;

    /// @dev crafting is allowed to mint burn tokens in battle pass
    constructor(string memory _uri, address _crafting)
        Rewards(_uri, _crafting)
    {}

    /// @notice gives xp to a user upon completion of quests
    /// @dev only owner can give xp
    /// @param _seasonId seasonId for which to give xp
    /// @param xp amount of xp to give
    /// @param user user to give xp to
    function giveXp(uint256 _seasonId, uint256 xp, address user)
        external
        onlyOwner
    {
        userInfo[user][_seasonId].xp += xp;
    }

    /// @notice sets required xp to levelup
    /// @param _seasonId seasonId for which to change xp
    /// @param _level level at which to change xp
    /// @param xp new xp required to levelup
    function setXp(uint256 _seasonId, uint256 _level, uint256 xp)
        external
        onlyOwner
    {
        seasonInfo[_seasonId][_level].xpToCompleteLevel = xp;
    }

    /**
     * @notice creates a new season
     * @dev only owner can call it
     * @param levelInfo info about each level, levelInfo[0] corresponds to info on a level 0
     * last level must be (levelInfo.length - 1) and must have xpToCompleteLevel == 0
     * @return current active seasonId
     */
    function newSeason(LevelInfo[] calldata levelInfo)
        external
        onlyOwner
        returns (uint256)
    {
        seasonId++;
        uint256 lastLevel = levelInfo.length - 1;
        if (levelInfo[lastLevel].xpToCompleteLevel != 0) {
            revert IncorrectSeasonDetails();
        }
        for (uint256 x; x <= lastLevel; x++) {
            seasonInfo[seasonId][x].xpToCompleteLevel =
                levelInfo[x].xpToCompleteLevel;
            if (levelInfo[x].freeRewardId != 0) {
                addReward(
                    seasonId,
                    x,
                    false,
                    levelInfo[x].freeRewardId,
                    levelInfo[x].freeRewardQty
                );
            }
            if (levelInfo[x].premiumRewardId != 0) {
                addReward(
                    seasonId,
                    x,
                    true,
                    levelInfo[x].premiumRewardId,
                    levelInfo[x].premiumRewardQty
                );
            }
        }

        return seasonId;
    }

    /// @notice sets a reward for a seasonId and at level
    /// @dev only owner can set rewards
    /// @param _seasonId seasonId for which to change the reward
    /// @param _level level at which to change the reward
    /// @param premium true when setting a premium reward
    /// @param id new reward id
    /// @param qty new reward qty
    function addReward(
        uint256 _seasonId,
        uint256 _level,
        bool premium,
        uint256 id,
        uint256 qty
    )
        public
        onlyOwner
    {
        if (premium) {
            seasonInfo[_seasonId][_level].premiumRewardId = id;
            seasonInfo[_seasonId][_level].premiumRewardQty = qty;
        } else {
            seasonInfo[_seasonId][_level].freeRewardId = id;
            seasonInfo[_seasonId][_level].freeRewardQty = qty;
        }
    }

    /**
     * @notice claims a reward for a seasonId and at level
     * @dev reverts when:
     * user claims a reward for a level at which they are NOT
     * user claims an already claimed reward
     * user claims a premium reward, but is NOT eligible for it
     * when a user has a premium pass and it is their first time claiming a premium reward then
     * burn 1 pass from their balance and set claimedPremiumPass to be true
     * a user can own multiple premium passes just like any other reward
     * it will NOT be burned if the user has already claimed a premium reward
     * @param _seasonId seasonId for which to claim the reward
     * @param _level level at which to claim the reward
     * @param premium true when claiming a premium reward
     */
    function claimReward(uint256 _seasonId, uint256 _level, bool premium)
        external
    {
        address user = _msgSender();
        if (level(user, _seasonId) < _level) {
            revert NotAtLevelNeededToClaimReward();
        }

        User storage tempUserInfo = userInfo[user][_seasonId];

        if (tempUserInfo.claimed[_level][premium]) {
            revert RewardAlreadyClaimed();
        }
        tempUserInfo.claimed[_level][premium] = true;

        if (premium) {
            if (seasonInfo[_seasonId][_level].premiumRewardId == 0) {
                return;
            }
            if (isUserPremium(user, _seasonId)) {
                if (!tempUserInfo.claimedPremiumPass) {
                    tempUserInfo.claimedPremiumPass = true;
                    _burn(user, _seasonId, 1);
                }
                _mint(
                    user,
                    seasonInfo[_seasonId][_level].premiumRewardId,
                    seasonInfo[_seasonId][_level].premiumRewardQty,
                    ""
                );
            } else {
                revert NeedPremiumPassToClaimPremiumReward();
            }
        } else {
            if (seasonInfo[_seasonId][_level].freeRewardId == 0) {
                return;
            }
            _mint(
                user,
                seasonInfo[_seasonId][_level].freeRewardId,
                seasonInfo[_seasonId][_level].freeRewardQty,
                ""
            );
        }
    }

    /*//////////////////////////////////////////////////////////////////////
                            UTILS
    //////////////////////////////////////////////////////////////////////*/

    /// @notice checks if a user has premium pass
    /// @dev user is considered premium when:
    ///     they own one premium pass or
    ///     they have already claimed a premium reward
    /// @param user user address
    /// @param _seasonId seasonId for which to check for premium pass
    /// @return true when user has premium status
    function isUserPremium(address user, uint256 _seasonId)
        public
        view
        returns (bool)
    {
        if (
            userInfo[user][_seasonId].claimedPremiumPass
                || balanceOf[user][_seasonId] >= 1
        ) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice gets user level for a seasonId
    /// @dev breaks at the last level, where xpToCompleteLevel is 0
    /// @param user user address for which to get level
    /// @param _seasonId seasonId for which to get level
    /// @return userLevel current user level
    function level(address user, uint256 _seasonId)
        public
        view
        returns (uint256 userLevel)
    {
        uint256 maxLevelInSeason = getMaxLevel(_seasonId);
        uint256 userXp = userInfo[user][_seasonId].xp;
        uint256 cumulativeXP;
        for (uint256 x; x < maxLevelInSeason; x++) {
            cumulativeXP += seasonInfo[_seasonId][x].xpToCompleteLevel;
            if (cumulativeXP > userXp) {
                break;
            }
            userLevel++;
        }
    }

    /// @notice gets the max level for a seasonId
    /// @dev max level is reached when xpToCompleteLevel == 0
    function getMaxLevel(uint256 _seasonId)
        public
        view
        returns (uint256 maxLevel)
    {
        uint256 xpToCompleteLevel =
            seasonInfo[_seasonId][maxLevel].xpToCompleteLevel;
        while (xpToCompleteLevel != 0) {
            maxLevel++;
            xpToCompleteLevel =
                seasonInfo[_seasonId][maxLevel].xpToCompleteLevel;
        }
    }

    /// @notice checks a user claim status on a reward for a seasonId and at level
    /// @param user user address for which to check
    /// @param _seasonId seasonId for which to check
    /// @param _level level at which to check
    /// @param premium true when checking for premium rewards
    /// @return true when reward is claimed
    function isRewardClaimed(
        address user,
        uint256 _seasonId,
        uint256 _level,
        bool premium
    )
        external
        view
        returns (bool)
    {
        return userInfo[user][_seasonId].claimed[_level][premium];
    }
}
