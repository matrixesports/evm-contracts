// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Rewards.sol";

/** @dev Info stored each level
 * if you want to give out multiple rewards at a level then have the id correspond to a lootbox
 * xpToCompleteLevel: xp required to go from level x->x+1;
 * if info is for the last level then xpToCompleteLevel must be 0
 * freeReward: free reward id to give at level x
 * premiumReward: premium reward id to give at level x
 */
struct LevelInfo {
    uint256 xpToCompleteLevel;
    uint256 freeReward;
    uint256 premiumReward;
}

/** @dev Info stored on each user for each season
 * xp: how much xp the user has
 * claimedPremiumPass: true if a user has claimed their first premium pass reward
 * need this because once a user gets a premium pass then
 * they can claim a premium reward after which they should not be able to
 * sell it but still be able to claim other premium rewards
 * claimed: has user claimed reward for given level and prem status
 */
struct User {
    uint256 xp;
    bool claimedPremiumPass;
    mapping(uint256 => mapping(bool => bool)) claimed;
}

/// @dev used when there is an error while creating a new season
error IncorrectSeasonDetails(address admin);
/// @dev used when user is trying to claim a reward for a level at which they are not
error NotAtLevelNeededToClaimReward(uint256 seasonId, address user, uint256 actualLevel, uint256 requiredLevel);
/// @dev used when user does not have premium pass and they are trying to redeem a premum reward
error NeedPremiumPassToClaimPremiumReward(uint256 seasonId, address user);
/// @dev used when reward has already been claimed by a user
error RewardAlreadyClaimed(uint256 seasonId, address user);

/**
 * @title A Battle Pass contract representing a Battle Pass as used in games.
 * @author rayquaza7
 * @notice
 * Each creator gets 1 unique contract
 * Allows for creating multiple seasons
 * Tracks user progress across each level and season
 * Allows for giving out rewards at each level
 * Rewards can be NFTs/Tokens/Lootboxes
 * Allows for delegation of tokens to other users in a creator's community
 */
contract BattlePass is Rewards {
    /// @dev emitted when a new season is created
    /// @param seasonId new season id
    event NewSeason(uint256 indexed seasonId);

    /// @dev crafting address, upgradeable by admin
    address public crafting;
    /// @dev current season id
    uint256 public seasonId;

    /// @dev seasonId->level->LevelInfo
    mapping(uint256 => mapping(uint256 => LevelInfo)) public seasonInfo;
    /// @dev user->seasonId->User, store user info for each season
    mapping(address => mapping(uint256 => User)) public userInfo;

    constructor(string memory _uri) Rewards(_uri) {}

    /*//////////////////////////////////////////////////////////////////////
                                ADMIN 
    //////////////////////////////////////////////////////////////////////*/

    /// @notice change crafting address
    /// @param newCrafting new crafting address
    function setCrafting(address newCrafting) external onlyOwner {
        crafting = newCrafting;
    }

    /// @notice give xp to a user upon completion of quests
    /// @dev only owner can give xp
    /// @param _seasonId season id for which xp is to be given
    /// @param xp how much xp to give
    /// @param user user to give xp to
    function giveXp(
        uint256 _seasonId,
        uint256 xp,
        address user
    ) external onlyOwner {
        userInfo[user][_seasonId].xp += xp;
    }

    /// @notice change xp required to complete a level
    /// @dev can set xp after season has been created; only owner can change xp
    /// @param _seasonId season id to change the xp for
    /// @param _level level for which the xp needs to be changed
    /// @param xp the new xp required to complete _level
    function setXp(
        uint256 _seasonId,
        uint256 _level,
        uint256 xp
    ) external onlyOwner {
        seasonInfo[_seasonId][_level].xpToCompleteLevel = xp;
    }

    /**
     * @notice create a new season
     * @dev only owner can call it
     * @param levelInfo info about each level, levelInfo[0] corresponds to info on level 0
     * last level must have xpToCompleteLevel == 0
     * last level is levelInfo.length - 1, since arrays are 0 indexed and levelInfo[0] contains info on 0 level
     * @return current season id
     */
    function newSeason(LevelInfo[] calldata levelInfo) external onlyOwner returns (uint256) {
        seasonId++;
        uint256 lastLevel = levelInfo.length - 1;
        if (levelInfo[lastLevel].xpToCompleteLevel != 0) revert IncorrectSeasonDetails(msg.sender);
        for (uint256 x; x <= lastLevel; x++) {
            seasonInfo[seasonId][x].xpToCompleteLevel = levelInfo[x].xpToCompleteLevel;
            addReward(seasonId, x, false, levelInfo[x].freeReward);
            addReward(seasonId, x, true, levelInfo[x].premiumReward);
        }
        emit NewSeason(seasonId);
        return seasonId;
    }

    /**
     * @notice claim reward upon reaching a new level
     * @dev
     * revert if trying to claim reward for level at which the user is not
     * revert if reward is already claimed
     * revert if trying to redeem premium reward and user is not eligible for it
     * if user has premium pass and it is their first time claiming a premium reward then
     * burn 1 pass from their balance and set claimedPremiumPass to be true
     * @param _seasonId for which the reward is to be claimed
     * @param user user address that is claiming the reward
     * @param _level the level for which reward is being claimed
     * @param premium true if premium reward is to be claimed, false otherwise
     */
    function claimReward(
        uint256 _seasonId,
        address user,
        uint256 _level,
        bool premium
    ) external onlyOwner {
        if (level(user, _seasonId) < _level) {
            revert NotAtLevelNeededToClaimReward(_seasonId, user, level(user, _seasonId), _level);
        }

        User storage tempUserInfo = userInfo[user][_seasonId];

        if (tempUserInfo.claimed[_level][premium]) {
            revert RewardAlreadyClaimed(_seasonId, user);
        }
        tempUserInfo.claimed[_level][premium] = true;

        if (premium) {
            if (isUserPremium(user, _seasonId)) {
                if (!tempUserInfo.claimedPremiumPass) {
                    tempUserInfo.claimedPremiumPass = true;
                    _burn(user, _seasonId, 1);
                }
                _mint(user, seasonInfo[_seasonId][_level].premiumReward, 1, "");
            } else {
                revert NeedPremiumPassToClaimPremiumReward(_seasonId, user);
            }
        } else {
            _mint(user, seasonInfo[_seasonId][_level].freeReward, 1, "");
        }
    }

    /// @notice add/update reward for a level and season
    /// @dev only owner can change it
    /// @param _seasonId season id to change the reward for
    /// @param _level level for which the reward needs to be changed
    /// @param premium true if adding/updating premium reward
    /// @param id new reward id
    function addReward(
        uint256 _seasonId,
        uint256 _level,
        bool premium,
        uint256 id
    ) public onlyOwner {
        if (premium) {
            seasonInfo[_seasonId][_level].premiumReward = id;
        } else {
            seasonInfo[_seasonId][_level].freeReward = id;
        }
    }

    /*//////////////////////////////////////////////////////////////////////
                            READ/VIEW
    //////////////////////////////////////////////////////////////////////*/

    /// @notice check if the user has a premium pass
    /// @dev a user is not considered premium until they either own one premium pass
    /// or already have claimed a premium reward.
    /// @param user user address
    /// @param _seasonId season id for which the user might have a premium pass
    /// @return true if user has a premium pass, false otherwise
    function isUserPremium(address user, uint256 _seasonId) public view returns (bool) {
        if (userInfo[user][_seasonId].claimedPremiumPass || balanceOf[user][_seasonId] >= 1) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice calculate level of a user for a given season
    /// @dev break when xpToCompleteLevel is 0 since that means that the user is at last level
    /// @param user user address to calculate the level for
    /// @param _seasonId season for which level is to be calculated
    /// @return userLevel current user level
    function level(address user, uint256 _seasonId) public view returns (uint256 userLevel) {
        uint256 cumulativeXP = seasonInfo[_seasonId][userLevel].xpToCompleteLevel;
        uint256 userXp = userInfo[user][_seasonId].xp;
        while (cumulativeXP <= userXp) {
            userLevel++;
            uint256 xpToNextLevel = seasonInfo[_seasonId][userLevel].xpToCompleteLevel;
            if (xpToNextLevel == 0) break;
            cumulativeXP += xpToNextLevel;
        }
    }

    /// @notice is reward claimed by user for given season id, level and prem status
    /// @return true if reward has been claimed
    function isRewardClaimed(
        address user,
        uint256 _seasonId,
        uint256 _level,
        bool premium
    ) public view returns (bool) {
        return userInfo[user][_seasonId].claimed[_level][premium];
    }
}
