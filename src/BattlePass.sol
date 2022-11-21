// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC1155.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/metatx/ERC2771Context.sol";

/// @dev DO NOT CHANGE ORDERING, web3 service depends on this
enum REWARD_TYPE {
    PREMIUM_PASS,
    REPUTATION,
    LOOTBOX,
    REDEEMABLE,
    SPECIAL
}

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
struct Level {
    uint256 xp;
    uint256 freeId;
    uint256 freeQty;
    REWARD_TYPE freeType;
    uint256 premId;
    uint256 premQty;
    REWARD_TYPE premType;
    int256 freeLimit;
    int256 premLimit;
}

struct Lootdrop {
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

/**
 * @dev a lootbox is a collection of LootboxOptions
 * rarity is rarityRange[1] - rarityRange[0]
 * the rarity of all LootboxOptions must add up to 100
 * rarityRange[0] is inclusive and rarityRange[1] is exclusive
 * give qtys[x] of ids[x]  (ids.length == qtys.length)
 */
struct LootboxOption {
    uint256[2] rarityRange;
    uint256[] ids;
    uint256[] qtys;
}

/// @dev use when an error occurrs while creating a new season
error IncorrectSeasonDetails();

/// @dev use when user claims a reward for a level at which they are NOT
error NotAtLevelNeededToClaimReward();

/// @dev use when user claims a premium reward without owning a premium pass or claimedPremiumPass is false
error NeedPremiumPass();

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

/// @dev pls dont get here
error LOLHowDidYouGetHere(uint256 _Id);

/// @dev used when the details for a new lootbox are incorrect
error IncorrectLootboxOptions();

/// @dev used when the info for a new reward is incorrect
error IncorrectRewardInfo();

/// @dev used when a non owner/crafting address tries to mint/burn
error NoAccess();

error InvalidId();

/**
 * @title MTX Battle Pass
 * @author BoManev
 * @notice
 * Battle Pass is a system that rewards users for completing creator specific quests
 * during established time periods known as seasons.
 * 
 *  
 * Each creator gets 1 unique Battle Pass and the contract allows multiple seasons
 * Tracks user progress at each level and across seasons
 * Allows for giving out rewards at specified levels
 * Rewards can be { NFTs, Tokens, Lootboxes, Redeemables }
 */
contract BattlePass is ERC1155, Owned, ERC2771Context {
    uint256 public immutable creatorId;
    uint256 public seasonId;
    uint256 public lootdropId;
    string public tokenURI;
    address public craftingContract;

    /**
     * reputation_token - 1
     * premium pass for season x - x00
     * reward 0y for season x - x0y (102, 123)
     */
    /// @dev id 100 is reserved for reputation_token; 1-99 seasonal premium passes
    uint256 public constant REPUTATION_TOKEN = 100;

    /// @dev id 1 is reserved for reputation_token and 99 for premium passes
    uint256 public id = REPUTATION_TOKEN;

    /// @dev seasonId -> level -> LevelInfo
    mapping(uint256 => mapping(uint256 => Level)) public seasonInfo;

    /// @dev user -> seasonId -> User
    mapping(address => mapping(uint256 => User)) public userInfo;

    /// @dev id -> [all LootboxOptions]
    mapping(uint256 => LootboxOption[]) internal lootboxRewards;

    /// @dev lootdropId -> Lootdrop
    mapping(uint256 => Lootdrop) public lootdropInfo;

    /// @dev lootdropEntry -> user
    mapping(uint256 => address) public lootdropEntry;

    /// @dev user -> lootdropId
    mapping(address => uint256) public lootdropClaim;

    event LootdropWinner(uint256 indexed _Id, address indexed _user);

    event LootboxOpened(uint256 indexed _lootboxId, uint256 indexed _idxOpened, address indexed _user);

    /// @notice creates reputation reward
    /// @dev crafting is allowed to mint burn tokens in battle pass
    constructor(uint256 _creatorId, address _craftingContract, address _owner) Owned(_owner) ERC2771Context(_owner) {
        tokenURI = "https://matrix-metadata-server.zeet-matrix.zeet.app";
        creatorId = _creatorId;
        craftingContract = _craftingContract;
    }

    /*//////////////////////////////////////////////////////////////
                                PASS
    //////////////////////////////////////////////////////////////*/

    function checkClaim(address _user, uint256 _level, bool _premium) internal {
        if (level(_user, seasonId) < _level) {
            revert NotAtLevelNeededToClaimReward();
        }
        if (userInfo[_user][seasonId].claimed[_level][_premium]) {
            revert RewardAlreadyClaimed();
        }
        if (_premium) {
            if (seasonInfo[seasonId][_level].premLimit == 0) {
                revert RewardLimit();
            } else if (seasonInfo[seasonId][_level].premLimit != -1) {
                seasonInfo[seasonId][_level].premLimit--;
            }
            if (isUserPremium(_user, seasonId)) {
                if (!userInfo[_user][seasonId].claimedPremiumPass) {
                    userInfo[_user][seasonId].claimedPremiumPass = true;
                    burn(_user, seasonId, 1);
                }
            } else {
                revert NeedPremiumPass();
            }
        } else {
            if (seasonInfo[seasonId][_level].freeLimit == 0) {
                revert RewardLimit();
            } else if (seasonInfo[seasonId][_level].freeLimit != -1) {
                seasonInfo[seasonId][_level].freeLimit--;
            }
        }
        userInfo[_user][seasonId].claimed[_level][_premium] = true;
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
        checkClaim(user, _level, _premium);
        if (_premium && seasonInfo[seasonId][_level].premId > 0) {
            _mint(user, seasonInfo[seasonId][_level].premId, seasonInfo[seasonId][_level].premQty, "");
        } else if (!_premium && seasonInfo[seasonId][_level].freeId > 0) {
            _mint(user, seasonInfo[seasonId][_level].freeId, seasonInfo[seasonId][_level].freeQty, "");
        } else {}
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
     * @param _level level at which to claim the reward
     * @param _premium true when claiming a premium reward
     */
    function claimRewardAtomic(uint256 _level, bool _premium) external {
        address user = _msgSender();
        checkClaim(user, _level, _premium);
        uint256 rewardId;
        uint256 rewardQty;
        REWARD_TYPE rewardType;
        if (_premium) {
            rewardId = seasonInfo[seasonId][_level].premId;
            rewardQty = seasonInfo[seasonId][_level].premQty;
            rewardType = seasonInfo[seasonId][_level].premType;
        } else {
            rewardId = seasonInfo[seasonId][_level].freeId;
            rewardQty = seasonInfo[seasonId][_level].freeQty;
            rewardType = seasonInfo[seasonId][_level].freeType;
        }
        if (rewardId > 0) {
            if (rewardType == REWARD_TYPE.PREMIUM_PASS) {
                userInfo[user][seasonId].claimedPremiumPass = true;
            } else {
                _mint(user, rewardId, rewardQty, "");
                if (rewardType == REWARD_TYPE.LOOTBOX) {
                    openLootboxAtomic(rewardId, user);
                }
            }
        }
    }

    /// @notice gives xp to a user for the current season; use upon completion of quests
    function giveXp(uint256 _xp, address _user) external onlyOwner {
        userInfo[_user][seasonId].xp += _xp;
    }

    /*//////////////////////////////////////////////////////////////
                                SEASON
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice creates a new season and premium_pass reward for new seasonId
     * @param _levelInfo info about each level, levelInfo[0] corresponds to info on a level 0
     * last level must be (levelInfo.length - 1) and must have xpToCompleteLevel == 0
     */
    function newSeason(Level[] calldata _levelInfo) external onlyOwner {
        if (_levelInfo[_levelInfo.length - 1].xp != 0) {
            revert IncorrectSeasonDetails();
        }
        for (uint256 i; i < _levelInfo.length; i++) {
            seasonInfo[seasonId][i].xp = _levelInfo[i].xp;
            if (_levelInfo[i].freeId != 0) {
                addReward(i, false, _levelInfo[i].freeId, _levelInfo[i].freeQty);
            }
            if (_levelInfo[i].premId != 0) {
                addReward(i, true, _levelInfo[i].premId, _levelInfo[i].premQty);
            }
        }
    }

    /// @notice sets a reward for the current seasonId
    function addReward(uint256 _level, bool _premium, uint256 _id, uint256 _qty) public onlyOwner {
        if (_premium) {
            seasonInfo[seasonId][_level].premId = _id;
            seasonInfo[seasonId][_level].premQty = _qty;
        } else {
            seasonInfo[seasonId][_level].freeId = _id;
            seasonInfo[seasonId][_level].freeQty = _qty;
        }
    }

    /// @notice sets the required xp to levelup for the current season
    function setXp(uint256 _level, uint256 _xp) external onlyOwner {
        seasonInfo[seasonId][_level].xp = _xp;
    }

    /*//////////////////////////////////////////////////////////////
                                LOOTBOX
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice creates a new lootbox
     * @dev reverts when:
     *      joint rarity of all LootboxOptions does not add up to 100
     *      ids.length != qtys.length
     *      ids are invalid
     * @param _options all the LootboxOptions avaliable in a lootbox
     */
    function newLootbox(LootboxOption[] memory _options) external onlyOwner {
        uint256 cumulativeProbability;
        for (uint256 i = 0; i < _options.length; i++) {
            if (_options[i].ids.length != _options[i].qtys.length) {
                revert IncorrectLootboxOptions();
            }
            cumulativeProbability += _options[i].rarityRange[1] - _options[i].rarityRange[0];
            lootboxRewards[id].push(_options[i]);
        }
        if (cumulativeProbability != 100) {
            revert IncorrectLootboxOptions();
        }
    }

    /**
     * @notice opens a lootbox
     * @param _id lootboxId to open
     */
    function openLootbox(uint256 _id) public returns (uint256) {
        address user = _msgSender();
        if (lootboxRewards[_id].length == 0) {
            revert InvalidId();
        }
        _burn(user, _id, 1);
        uint256 idx = calculateRandom(_id);
        LootboxOption memory option = lootboxRewards[_id][idx];
        _batchMint(user, option.ids, option.qtys, "");
        emit LootboxOpened(_id, idx, user);
        return idx;
    }

    function openLootboxAtomic(uint256 _id, address _user) internal returns (uint256) {
        uint256 idx = calculateRandom(_id);
        LootboxOption memory option = lootboxRewards[_id][idx];
        _batchMint(_user, option.ids, option.qtys, "");
        emit LootboxOpened(_id, idx, _user);
        return idx;
    }

    /// @notice gets a lootboxOption by lootboxId and index
    function getLootboxOptionByIdx(uint256 _id, uint256 _idx) external view returns (LootboxOption memory) {
        return lootboxRewards[_id][_idx];
    }

    /// @notice gets a lootboxOptions length by lootboxId
    function getLootboxOptionsLength(uint256 _id) external view returns (uint256) {
        return lootboxRewards[_id].length;
    }

    /// @notice calculates a pseudorandom index between 0-99
    function calculateRandom(uint256 _id) public view returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number), block.difficulty))) % 100;
        LootboxOption[] memory options = lootboxRewards[_id];
        for (uint256 x; x < options.length; x++) {
            if (random >= options[x].rarityRange[0] && random < options[x].rarityRange[1]) {
                return x;
            }
        }
        revert LOLHowDidYouGetHere(_id);
    }

    /*//////////////////////////////////////////////////////////////
                                LOOTDROP
    //////////////////////////////////////////////////////////////*/

    function createLootdrop(Lootdrop calldata _lootdropInfo) external onlyOwner {
        if (
            _lootdropInfo.limit == 0 || _lootdropInfo.qty <= 0 || _lootdropInfo.threshold < 0
                || _lootdropInfo.start >= _lootdropInfo.end
        ) {
            revert InvalidId();
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
            lootdropEntry[++lootdropInfo[lootdropId].count] = user;
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

    /*//////////////////////////////////////////////////////////////
                                ADMIN
    //////////////////////////////////////////////////////////////*/

    /// @notice sets the uri
    function setURI(string memory _uri) external onlyOwner {
        tokenURI = _uri;
    }

    /// @notice sets the crafting proxy address
    function setCrafting(address _craftingContract) external onlyOwner {
        craftingContract = _craftingContract;
    }

    /*//////////////////////////////////////////////////////////////
                                UTILS
    //////////////////////////////////////////////////////////////*/

    /// @notice returns uri by id
    function uri(uint256 _id) public view override returns (string memory) {
        return string.concat(tokenURI, "/", Strings.toString(creatorId), "/", Strings.toString(_id), ".json");
    }

    /// @notice allows the owner/crafting contract to mint tokens
    function mint(address _to, uint256 _id, uint256 _amount) public {
        if (owner == msg.sender || msg.sender == craftingContract) {
            _mint(_to, _id, _amount, "");
        } else {
            revert NoAccess();
        }
    }

    /// @notice allows the owner/crafting contract to burn tokens
    function burn(address _to, uint256 _id, uint256 _amount) public {
        if (owner == msg.sender || msg.sender == craftingContract) {
            _burn(_to, _id, _amount);
        } else {
            revert NoAccess();
        }
    }

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
            cumulativeXP += seasonInfo[_seasonId][x].xp;
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
        while (seasonInfo[_seasonId][maxLevel].xp != 0) {
            maxLevel++;
        }
    }

    /// @notice checks a user claim status for a reward
    function isRewardClaimed(address _user, uint256 _seasonId, uint256 _level, bool _premium) external view returns (bool) {
        return userInfo[_user][_seasonId].claimed[_level][_premium];
    }
}
