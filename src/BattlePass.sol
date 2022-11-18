// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./Rewards.sol";

enum LOOTDROP_TYPE {
    STANDARD,
    GIVEAWAY
}

enum LOOTDROP_REQUIREMENTS {
    REPUTATION,
    XP
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
    int256 freeLimit;
    int256 premLimit; // -1 for inifity
}

struct LootdropInfo {
    uint256 id;
    uint256 qty;
    LOOTDROP_TYPE lootdropType;
    LOOTDROP_REQUIREMENTS lootdropReq;
    uint256 threshold;
    uint256 start;
    uint256 end;
    uint256 count;
    int256 limit;
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

error LootdropInactive();

/// @dev use when user draws a winner from an active *giveaway* lootdrop
error LootdropStillActive();

error LootdropLimit();

/// @dev used when claiming a reward outside of qty limit
error RewardLimit();

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
    /// @dev current active seasonId; [2..99]
    uint256 public seasonId = 1;

    uint256 public lootdropId;

    /// @dev seasonId -> level -> LevelInfo
    mapping(uint256 => mapping(uint256 => LevelInfo)) public seasonInfo;

    /// @dev user -> seasonId -> User
    mapping(address => mapping(uint256 => User)) public userInfo;

    /// @dev lootdropId -> LootdropInfo
    mapping(uint256 => LootdropInfo) public lootdropInfo;

    /// @dev user -> lootdropId
    mapping(address => uint256) public lootdropClaim;

    /// @dev lootdropEntry -> user
    mapping(uint256 => address) public lootdropEntry;

    event LootdropWinner(uint256 indexed _Id, address indexed _user);

    /// @dev crafting is allowed to mint burn tokens in battle pass
    constructor(uint256 _creatorId, address _crafting, address _owner) Rewards(_creatorId, _crafting, _owner) {}

    /*//////////////////////////////////////////////////////////////
                                METATX
    //////////////////////////////////////////////////////////////*/

    function checkClaim(address _user, uint256 _seasonId, uint256 _level, bool _premium) internal {
        if (level(_user, _seasonId) < _level) {
            revert NotAtLevelNeededToClaimReward();
        }
        if (userInfo[_user][_seasonId].claimed[_level][_premium]) {
            revert RewardAlreadyClaimed();
        }
        if (_premium) {
            if (seasonInfo[_seasonId][_level].premLimit == 0) {
                revert RewardLimit();
            } else if (seasonInfo[_seasonId][_level].premLimit != -1) {
                seasonInfo[_seasonId][_level].premLimit--;
            }
            if (isUserPremium(_user, _seasonId)) {
                if (!userInfo[_user][_seasonId].claimedPremiumPass) {
                    userInfo[_user][_seasonId].claimedPremiumPass = true;
                    burn(_user, _seasonId, 1);
                }
            } else {
                revert NeedPremiumPassToClaimPremiumReward();
            }
        } else {
            if (seasonInfo[_seasonId][_level].freeLimit == 0) {
                revert RewardLimit();
            } else if (seasonInfo[_seasonId][_level].freeLimit != -1) {
                seasonInfo[_seasonId][_level].freeLimit--;
            }
        }
        userInfo[_user][_seasonId].claimed[_level][_premium] = true;
    }

    /**
     * @notice claims a reward for the current season
     * @dev reverts when:
     * user claims a reward for a level at which they are NOT
     * user claims an already claimed reward
     * user claims a premium reward, but is NOT eligible for it
     * when a user has a premium pass and it is their first time claiming a premium reward then
     * burn 1 pass from their balance and set claimedPremiumPass to be true
     * a user can own multiple premium passes just like any other reward
     * it will NOT be burned if the user has already claimed a premium reward
     * @param _level level at which to claim the reward
     * @param _premium true when claiming a premium reward
     */
    function claimReward(uint256 _level, bool _premium) external {
        address user = _msgSender();
        checkClaim(user, seasonId, _level, _premium);
        if (_premium && seasonInfo[seasonId][_level].premiumRewardId > 0) {
            _mint(user, seasonInfo[seasonId][_level].premiumRewardId, seasonInfo[seasonId][_level].premiumRewardQty, "");
        } else if (!_premium && seasonInfo[seasonId][_level].freeRewardId > 0) {
            _mint(user, seasonInfo[seasonId][_level].freeRewardId, seasonInfo[seasonId][_level].freeRewardQty, "");
        }
    }

    /**
     * @notice claims a reward for the current season with atomic open and redeem
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
    function claimRewardAtomic(uint256 _seasonId, uint256 _level, bool _premium) external {
        address user = _msgSender();
        checkClaim(user, _seasonId, _level, _premium);
        uint256 rewardId;
        uint256 rewardQty;
        if (_premium) {
            rewardId = seasonInfo[_seasonId][_level].premiumRewardId;
            rewardQty = seasonInfo[_seasonId][_level].premiumRewardQty;
        } else {
            rewardId = seasonInfo[_seasonId][_level].freeRewardId;
            rewardQty = seasonInfo[_seasonId][_level].freeRewardQty;
        }
        if (rewardId > 0) {
            _mint(user, rewardId, rewardQty, "");
            if (rewardInfo[rewardId].rewardType == REWARD_TYPE.LOOTBOX) {
                openLootbox(rewardId);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                                PASS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice creates a new season
     * @param levelInfo info about each level, levelInfo[0] corresponds to info on a level 0
     * last level must be (levelInfo.length - 1) and must have xpToCompleteLevel == 0
     */
    function newSeason(LevelInfo[] calldata levelInfo) external onlyOwner {
        seasonId++;
        if (levelInfo[levelInfo.length - 1].xpToCompleteLevel != 0) {
            revert IncorrectSeasonDetails();
        }
        for (uint256 i; i < levelInfo.length; i++) {
            seasonInfo[seasonId][i].xpToCompleteLevel = levelInfo[i].xpToCompleteLevel;
            if (levelInfo[i].freeRewardId != 0 && levelInfo[i].freeRewardId != 0) {
                seasonInfo[seasonId][i] = levelInfo[i];
            }
        }
    }

    /// @notice sets the required xp to levelup for the current season
    function setXp(uint256 _level, uint256 xp) external onlyOwner {
        seasonInfo[seasonId][_level].xpToCompleteLevel = xp;
    }

    /// @notice sets a reward for the current seasonId
    function addReward(uint256 _level, bool _premium, uint256 _id, uint256 _qty) public onlyOwner {
        if (_premium) {
            seasonInfo[seasonId][_level].premiumRewardId = _id;
            seasonInfo[seasonId][_level].premiumRewardQty = _qty;
        } else {
            seasonInfo[seasonId][_level].freeRewardId = _id;
            seasonInfo[seasonId][_level].freeRewardQty = _qty;
        }
    }

    /// @notice gives xp to a user for the current season; use upon completion of quests
    function giveXp(uint256 _xp, address _user) external onlyOwner {
        userInfo[_user][seasonId].xp += _xp;
    }

    /*//////////////////////////////////////////////////////////////
                                UTILS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice checks if a user has premium pass
     * @dev user is considered premium when:
     *       they own one premium pass or
     *       they have already claimed a premium reward
     */
    function isUserPremium(address _user, uint256 _seasonId) public view returns (bool) {
        if (userInfo[_user][_seasonId].claimedPremiumPass || balanceOf[_user][_seasonId] >= 1) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice gets user level
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

    /**
     * @notice gets the max level for a seasonId
     * @dev max level is reached when xpToCompleteLevel == 0
     */
    function getMaxLevel(uint256 _seasonId) public view returns (uint256 maxLevel) {
        uint256 xpToCompleteLevel = seasonInfo[_seasonId][maxLevel].xpToCompleteLevel;
        while (xpToCompleteLevel != 0) {
            maxLevel++;
            xpToCompleteLevel = seasonInfo[_seasonId][maxLevel].xpToCompleteLevel;
        }
    }

    /// @notice checks a user claim status for a reward
    function isRewardClaimed(address _user, uint256 _seasonId, uint256 _level, bool _premium) external view returns (bool) {
        return userInfo[_user][_seasonId].claimed[_level][_premium];
    }

    function createLootdrop(LootdropInfo calldata _lootdropInfo) external onlyOwner {
        if (
            _lootdropInfo.limit == 0 || _lootdropInfo.qty <= 0 || _lootdropInfo.threshold < 0
                || _lootdropInfo.start >= _lootdropInfo.end
        ) {
            revert InvalidId(_lootdropInfo.id);
        }
        lootdropId++;
        lootdropInfo[lootdropId] = _lootdropInfo;
        lootdropInfo[lootdropId].count = 0;
    }

    function claimLootdrop() external {
        address user = _msgSender();
        if (lootdropInfo[lootdropId].start < block.number || lootdropInfo[lootdropId].end > block.number) {
            revert LootdropInactive();
        }
        if (lootdropClaim[user] == lootdropId) {
            revert LootdropAlreadyClaimed();
        }
        if (lootdropInfo[lootdropId].limit == 0) {
            revert LootdropLimit();
        } else if (lootdropInfo[lootdropId].limit > 0) {
            lootdropInfo[lootdropId].limit--;
        }
        if (
            lootdropInfo[lootdropId].lootdropReq == LOOTDROP_REQUIREMENTS.REPUTATION
                && lootdropInfo[lootdropId].threshold > balanceOf[user][REPUTATION_TOKEN]
                || (
                    lootdropInfo[lootdropId].lootdropReq == LOOTDROP_REQUIREMENTS.XP
                        && lootdropInfo[lootdropId].threshold > userInfo[user][seasonId].xp
                )
        ) {
            revert LootdropRequirments();
        }
        lootdropClaim[user] = lootdropId;
        if (lootdropInfo[lootdropId].lootdropType == LOOTDROP_TYPE.GIVEAWAY) {
            lootdropEntry[++lootdropInfo[lootdropId].count];
        } else {
            mint(user, lootdropInfo[lootdropId].id, lootdropInfo[lootdropId].qty);
        }
    }

    function selectWinner() external onlyOwner {
        if (lootdropInfo[lootdropId].lootdropType != LOOTDROP_TYPE.GIVEAWAY) {
            revert InvalidLootdrop();
        }
        if (lootdropInfo[lootdropId].end < block.number) {
            revert LootdropStillActive();
        }
        if (lootdropInfo[lootdropId].count == 0) {
            revert InvalidLootdrop();
        }
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number), block.difficulty)))
            % lootdropInfo[lootdropId].count;
        mint(lootdropEntry[random + 1], lootdropInfo[lootdropId].id, lootdropInfo[lootdropId].qty);
        emit LootdropWinner(lootdropInfo[lootdropId].id, lootdropEntry[random + 1]);
    }
}
