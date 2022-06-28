// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Utils.sol";
import "solmate/utils/ReentrancyGuard.sol";
import {MERC1155 as PremiumPass} from "./rewards/MERC1155.sol";

/** @dev handle all level data together;
xpToCompleteLevel: xp required to go from level x->x+1
freeReward: free reward given at level x
premiumReward: premium reward given at level x
*/
struct LevelInfo {
    uint256 xpToCompleteLevel;
    ERC1155Reward freeReward;
    ERC1155Reward premiumReward;
}

/** @dev
xp: how much xp the user has
claimedPremium: has the user claimed a premium reward,   
claimed: has user claimed reward for given level and prem status
*/
struct User {
    uint256 xp;
    bool claimedPremium;
    mapping(uint256 => mapping(bool => bool)) claimed;
}

error IncorrectSeasonDetails(address admin);
error NotAtLevelNeededToClaimReward(uint256 seasonId, address user, uint256 actualLevel, uint256 requiredLevel);
error NeedPremiumPassToClaimPremiumReward(uint256 seasonId, address user);
error RewardAlreadyClaimed(uint256 seasonId, address user);

/**
@notice Pass contract representing a battle pass as used in games
@dev 
1. starts at level 0 for a user, 
2. can have multiple seasons, 
3. deploy 1 per creator
4. mint id=season id to giver premium pass for a particular season to a user
5. pass rewards are usually lootboxes
@author rayquaza
*/
contract Pass is PremiumPass, ReentrancyGuard, Utils {
    event NewSeason(address indexed admin, uint256 seasonId);

    /// @dev upgradeable by the admin
    address public oracleAddress;
    /// @dev current season id
    uint256 public seasonId;

    /// @dev seasonId->level->LevelInfo
    mapping(uint256 => mapping(uint256 => LevelInfo)) public seasonInfo;
    /// @dev seasonId->max lv in season
    mapping(uint256 => uint256) public maxLevelInSeason;
    /// @dev user->seasonId->User, store user info for each season
    mapping(address => mapping(uint256 => User)) public userInfo;

    /** 
    @dev recipe is given the minter role because it can mint/burn a prem pass based on recipes,
    msg.sender is admin, 
    msg.sender, pass contract, recipe have the minter role
    */
    constructor(string memory uri, address recipe) PremiumPass(uri, address(this), recipe) {
        oracleAddress = 0x744C907a37f4f595605E6FdE8cb5C3A022594D0a;
        _grantRole(ORACLE_ROLE, oracleAddress);
    }

    /*//////////////////////////////////////////////////////////////////////
                        NEW SEASONS AND ORACLE (ADMIN)
    //////////////////////////////////////////////////////////////////////*/

    /**
     @notice create a new season
     @dev 
     @param maxLevel max levels in season, maxLevel = 5 means last reward is given out at level 5
     u could technically remove this param and have a function to calculate this: a loop that breaks when it sees a 0 xptocompletelevel;
     refer lootbox, left as a todo for later
     @param levelInfo info about each level, levelInfo[0] corresponds to info on level 0
     @return current season id
     */
    function newSeason(uint256 maxLevel, LevelInfo[] calldata levelInfo)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256)
    {
        seasonId++;
        maxLevelInSeason[seasonId] = maxLevel;

        /**
        checks to prevent FE/scripting mistakes
        1. error if levelInfo does not have info on each level, therefore needs size to be equal to maxLevel+1 since 0 indexed
        2. cannot have xpToCompleteLevel to be non zero at max level since that would mean that there is another level
        3. max level cannot be 0
         */
        if (maxLevel + 1 != levelInfo.length || levelInfo[maxLevel].xpToCompleteLevel != 0 || maxLevel == 0)
            revert IncorrectSeasonDetails(_msgSender());

        for (uint256 x; x <= maxLevel; x++) {
            seasonInfo[seasonId][x].xpToCompleteLevel = levelInfo[x].xpToCompleteLevel;
            addReward(seasonId, x, false, levelInfo[x].freeReward);
            addReward(seasonId, x, true, levelInfo[x].premiumReward);
        }
        emit NewSeason(_msgSender(), seasonId);
        return seasonId;
    }

    ///@dev can add reward after season has been created
    /// if you're passing the 0 address then it means that u dont want to give anything at that level
    function addReward(
        uint256 _seasonId,
        uint256 _level,
        bool premium,
        ERC1155Reward calldata bundle
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (address(0) == bundle.token) return;
        deposit(bundle.token);
        if (premium) {
            seasonInfo[_seasonId][_level].premiumReward = bundle;
        } else {
            seasonInfo[_seasonId][_level].freeReward = bundle;
        }
    }

    ///@dev can set xp after season has been created
    function setXp(
        uint256 _seasonId,
        uint256 _level,
        uint256 xp
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        seasonInfo[_seasonId][_level].xpToCompleteLevel = xp;
    }

    ///@dev give xp to user, only callable from oracle
    function giveXp(
        uint256 _seasonId,
        uint256 xp,
        address user
    ) external onlyRole(ORACLE_ROLE) {
        userInfo[user][_seasonId].xp += xp;
    }

    function changeOracle(address newOracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(ORACLE_ROLE, oracleAddress);
        oracleAddress = newOracle;
        _grantRole(ORACLE_ROLE, oracleAddress);
    }

    /*//////////////////////////////////////////////////////////////////////
                                USER
    //////////////////////////////////////////////////////////////////////*/

    ///@dev break when xpToCompleteLevel is 0 since that means that the user is at last level
    function level(address user, uint256 _seasonId) public view returns (uint256 userLevel) {
        uint256 currentXp = userInfo[user][_seasonId].xp;
        uint256 xpToNext;
        for (uint256 x; x <= maxLevelInSeason[_seasonId]; x++) {
            xpToNext += seasonInfo[_seasonId][x].xpToCompleteLevel;
            if (xpToNext > currentXp || seasonInfo[_seasonId][x].xpToCompleteLevel == 0) break;
            userLevel++;
        }
        return userLevel;
    }

    /// @dev refer to claim reward to understand why this is the way it is
    function isUserPremium(address user, uint256 _seasonId) public view returns (bool) {
        if (userInfo[user][_seasonId].claimedPremium || balanceOf[user][_seasonId] >= 1) {
            return true;
        } else {
            return false;
        }
    }

    ///@dev is reward claimed by user for given season id, level and prem status
    function isRewardClaimed(
        address user,
        uint256 _seasonId,
        uint256 _level,
        bool premium
    ) public view returns (bool) {
        return userInfo[user][_seasonId].claimed[_level][premium];
    }

    /**
    @dev
    1. revert if trying to claim reward for level at which the user is not
    2. revert if reward is already claimed
    3. revert if trying to redeem premium reward and user is not eligible for it
    3. prem reward:
     - in order to mint a premium pass for a given season, the mint id MUST be equal to the seasonId
    - a user has a premium status if for a given seasonId, user.claimedPremium == true || balanceOf(user) >= 1,
    - this is because when the user is minted a premium pass for a season, they are free to buy/sell or claim it for a premium reward,
    - RESTRICTIONS: it is not allowed for a user to claim a premium reward for a season and then sell the pass.
        - user.claimedPremium == false and balanceOf(user) == 0, not eligible to claim premium reward
        - user.claimedPremium == false and balanceOf(user) >= 1, eligible to claim prem reward. burn pass when prem reward is claimed and set premiumClaimed = true
        - user.claimedPremium == true and balanceOf(user) >= 0; redeem prem reward normally
     */
    function claimReward(
        uint256 _seasonId,
        address user,
        uint256 _level,
        bool premium
    ) external nonReentrant {
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
                if (!tempUserInfo.claimedPremium) {
                    tempUserInfo.claimedPremium = true;
                    _burn(user, _seasonId, 1);
                }
                withdrawERC1155(seasonInfo[_seasonId][_level].premiumReward, user);
            } else {
                revert NeedPremiumPassToClaimPremiumReward(_seasonId, user);
            }
        } else {
            withdrawERC1155(seasonInfo[_seasonId][_level].freeReward, user);
        }
    }
}
