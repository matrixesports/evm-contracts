// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./Rewards.sol";

enum LOOTDROP_TYPE {
    STANDARD,
    GIVEAWAY
}

enum LOOTDROP_REQUIREMENTS {
    REPUTATION,
    SEASONXP
}

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

struct LootdropInfo {
    uint256 id;
    uint256 qty;
    LOOTDROP_TYPE lootdropType;
    LOOTDROP_REQUIREMENTS lootdropReq;
    uint256 threshold;
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

error InvalidLootdrop();

error LootdropRequirments();

error LootdropAlreadyClaimed();

/**
 * @title A Battle Pass
 * @author rayquaza7 && BoManev
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

    uint256 public lootdropId;

    /// @dev seasonId -> level -> LevelInfo
    mapping(uint256 => mapping(uint256 => LevelInfo)) public seasonInfo;

    /// @dev user -> seasonId -> User
    mapping(address => mapping(uint256 => User)) public userInfo;

    /// @dev lootdropId -> LootdropInfo
    mapping(uint256 => LootdropInfo) public lootdropInfo;

    /// @dev user -> lootdropId
    mapping(address => uint256) public lootdropClaims;

    /// @dev crafting is allowed to mint burn tokens in battle pass
    constructor(uint256 _creatorId, address _crafting, address _owner) Rewards(_creatorId, _crafting, _owner) {}

    /*//////////////////////////////////////////////////////////////
                                METATX
    //////////////////////////////////////////////////////////////*/

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
     * @param _premium true when claiming a premium reward
     */
    function claimReward(uint256 _seasonId, uint256 _level, bool _premium) external {
        address user = _msgSender();
        if (level(user, _seasonId) < _level) {
            revert NotAtLevelNeededToClaimReward();
        }

        User storage tempUserInfo = userInfo[user][_seasonId];

        if (tempUserInfo.claimed[_level][_premium]) {
            revert RewardAlreadyClaimed();
        }
        tempUserInfo.claimed[_level][_premium] = true;

        if (_premium) {
            if (seasonInfo[_seasonId][_level].premiumRewardId == 0) {
                return;
            }
            if (isUserPremium(user, _seasonId)) {
                if (!tempUserInfo.claimedPremiumPass) {
                    tempUserInfo.claimedPremiumPass = true;
                    burn(user, _seasonId, 1);
                }
                mint(user, seasonInfo[_seasonId][_level].premiumRewardId, seasonInfo[_seasonId][_level].premiumRewardQty);
            } else {
                revert NeedPremiumPassToClaimPremiumReward();
            }
        } else {
            if (seasonInfo[_seasonId][_level].freeRewardId == 0) {
                return;
            }
            mint(user, seasonInfo[_seasonId][_level].freeRewardId, seasonInfo[_seasonId][_level].freeRewardQty);
        }
    }

    /**
     * @notice claims a reward for a seasonId and at level with atomic open and redeem
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
     * @param _premium true when claiming a premium reward
     */
    function claimRewardAtomic(uint256 _seasonId, uint256 _level, bool _premium) external returns (uint256) {
        address user = _msgSender();
        if (level(user, _seasonId) < _level) {
            revert NotAtLevelNeededToClaimReward();
        }

        User storage tempUserInfo = userInfo[user][_seasonId];

        if (tempUserInfo.claimed[_level][_premium]) {
            revert RewardAlreadyClaimed();
        }
        tempUserInfo.claimed[_level][_premium] = true;
        uint256 rewardId;
        uint256 rewardQty;
        if (_premium) {
            if (seasonInfo[_seasonId][_level].premiumRewardId == 0) {
                return 0;
            }
            if (isUserPremium(user, _seasonId)) {
                rewardId = seasonInfo[_seasonId][_level].premiumRewardId;
                rewardQty = seasonInfo[_seasonId][_level].premiumRewardQty;
                if (!tempUserInfo.claimedPremiumPass) {
                    tempUserInfo.claimedPremiumPass = true;
                    burn(user, _seasonId, 1);
                }
            } else {
                revert NeedPremiumPassToClaimPremiumReward();
            }
        } else {
            if (seasonInfo[_seasonId][_level].freeRewardId == 0) {
                return 0;
            }
            rewardId = seasonInfo[_seasonId][_level].freeRewardId;
            rewardQty = seasonInfo[_seasonId][_level].freeRewardQty;
        }

        if (rewardInfo[rewardId].rewardType == REWARD_TYPE.LOOTBOX) {
            mint(user, rewardId, rewardQty);
            return openLootbox(rewardId);
        }
        if (rewardInfo[rewardId].rewardType == REWARD_TYPE.REDEEMABLE) {
            return 0;
        }
        mint(user, rewardId, rewardQty);
        return 0;
    }

    /*//////////////////////////////////////////////////////////////
                                PASS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice creates a new season
     * @dev only owner can call it
     * @param levelInfo info about each level, levelInfo[0] corresponds to info on a level 0
     * last level must be (levelInfo.length - 1) and must have xpToCompleteLevel == 0
     * @return current active seasonId
     */
    function newSeason(LevelInfo[] calldata levelInfo) external onlyOwner returns (uint256) {
        seasonId++;
        uint256 lastLevel = levelInfo.length - 1;
        if (levelInfo[lastLevel].xpToCompleteLevel != 0) {
            revert IncorrectSeasonDetails();
        }
        for (uint256 x; x <= lastLevel; x++) {
            seasonInfo[seasonId][x].xpToCompleteLevel = levelInfo[x].xpToCompleteLevel;
            if (levelInfo[x].freeRewardId != 0) {
                addReward(seasonId, x, false, levelInfo[x].freeRewardId, levelInfo[x].freeRewardQty);
            }
            if (levelInfo[x].premiumRewardId != 0) {
                addReward(seasonId, x, true, levelInfo[x].premiumRewardId, levelInfo[x].premiumRewardQty);
            }
        }

        return seasonId;
    }

    /// @notice sets required xp to levelup
    /// @param _seasonId seasonId for which to change xp
    /// @param _level level at which to change xp
    /// @param xp new xp required to levelup
    function setXp(uint256 _seasonId, uint256 _level, uint256 xp) external onlyOwner {
        seasonInfo[_seasonId][_level].xpToCompleteLevel = xp;
    }

    /// @notice sets a reward for a seasonId and at level
    /// @dev only owner can set rewards
    /// @param _seasonId seasonId for which to change the reward
    /// @param _level level at which to change the reward
    /// @param _premium true when setting a premium reward
    /// @param _id new reward id
    /// @param _qty new reward qty
    function addReward(uint256 _seasonId, uint256 _level, bool _premium, uint256 _id, uint256 _qty) public onlyOwner {
        if (rewardInfo[_id].limit == 0) {
            revert InvalidId(_id);
        }
        if (_premium) {
            seasonInfo[_seasonId][_level].premiumRewardId = _id;
            seasonInfo[_seasonId][_level].premiumRewardQty = _qty;
        } else {
            seasonInfo[_seasonId][_level].freeRewardId = _id;
            seasonInfo[_seasonId][_level].freeRewardQty = _qty;
        }
    }

    /// @notice gives xp to a user upon completion of quests
    /// @dev only owner can give xp
    /// @param _seasonId seasonId for which to give xp
    /// @param _xp amount of xp to give
    /// @param _user user to give xp to
    function giveXp(uint256 _seasonId, uint256 _xp, address _user) external onlyOwner {
        userInfo[_user][_seasonId].xp += _xp;
    }

    /*//////////////////////////////////////////////////////////////
                                UTILS
    //////////////////////////////////////////////////////////////*/

    /// @notice checks if a user has premium pass
    /// @dev user is considered premium when:
    ///     they own one premium pass or
    ///     they have already claimed a premium reward
    /// @param _user user address
    /// @param _seasonId seasonId for which to check for premium pass
    /// @return true when user has premium status
    function isUserPremium(address _user, uint256 _seasonId) public view returns (bool) {
        if (userInfo[_user][_seasonId].claimedPremiumPass || balanceOf[_user][_seasonId] >= 1) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice gets user level for a seasonId
    /// @dev breaks at the last level, where xpToCompleteLevel is 0
    /// @param _user user address for which to get level
    /// @param _seasonId seasonId for which to get level
    /// @return userLevel current user level
    function level(address _user, uint256 _seasonId) public view returns (uint256 userLevel) {
        uint256 maxLevelInSeason = getMaxLevel(_seasonId);
        uint256 userXp = userInfo[_user][_seasonId].xp;
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
    function getMaxLevel(uint256 _seasonId) public view returns (uint256 maxLevel) {
        uint256 xpToCompleteLevel = seasonInfo[_seasonId][maxLevel].xpToCompleteLevel;
        while (xpToCompleteLevel != 0) {
            maxLevel++;
            xpToCompleteLevel = seasonInfo[_seasonId][maxLevel].xpToCompleteLevel;
        }
    }

    /// @notice checks a user claim status on a reward for a seasonId and at level
    /// @param _user user address for which to check
    /// @param _seasonId seasonId for which to check
    /// @param _level level at which to check
    /// @param _premium true when checking for premium rewards
    /// @return true when reward is claimed
    function isRewardClaimed(address _user, uint256 _seasonId, uint256 _level, bool _premium) external view returns (bool) {
        return userInfo[_user][_seasonId].claimed[_level][_premium];
    }

    function createLootdrop(LootdropInfo calldata _lootdropInfo) external onlyOwner {
        if (rewardInfo[_lootdropInfo.id].limit == 0) {
            revert InvalidId(_lootdropInfo.id);
        }
        if (_lootdropInfo.qty < 0 || _lootdropInfo.threshold < 0) {
            revert InvalidLootdrop();
        }
        lootdropId++;
        lootdropInfo[lootdropId++] = _lootdropInfo;
    }

    function claimLootdrop() external {
        address user = _msgSender();
        if (lootdropClaims[user] == lootdropId) {
            revert LootdropAlreadyClaimed();
        }
        if (lootdropInfo[lootdropId].lootdropReq == LOOTDROP_REQUIREMENTS.REPUTATION) {
            if (lootdropInfo[lootdropId].threshold < balanceOf[user][CREATOR_TOKEN]) {
                revert LootdropRequirments();
            } else if (lootdropInfo[lootdropId].threshold < userInfo[user][CREATOR_TOKEN].xp) {
                revert LootdropRequirments();
            }
        }
        lootdropClaims[user] = lootdropId;
        mint(user, lootdropInfo[lootdropId].id, lootdropInfo[lootdropId].qty);
    }
}
