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

struct RewardInfo {
    REWARD_TYPE rewardType;
}

/// @dev used when a reward is invalid or non-existent
error InvalidId(uint256 _id);

/// @dev pls dont get here
error LOLHowDidYouGetHere(uint256 _Id);

/// @dev used when the details for a new lootbox are incorrect
error IncorrectLootboxOptions();

/// @dev used when the info for a new reward is incorrect
error IncorrectRewardInfo();

/// @dev used when a non owner/crafting address tries to mint/burn
error NoAccess();

/**
 * @title MTX Rewards
 * @author rayquaza7 && BoManev
 * @notice manages creator specific tokens, premium passes, lootboxes, nfts, redeemable items
 * @dev
 * allows for both fungible and non-fungible tokens; allows for meta tx
 * premium passes (id === keccak256(season_id); mint to give user a premium pass for season_id
 */
abstract contract Rewards is ERC1155, Owned, ERC2771Context {
    /// @dev crafting contract address
    address public crafting;
    uint256 public immutable creatorId;
    string public tokenURI;

    /// @dev used for reputation
    uint256 public constant REPUTATION_TOKEN = 1;

    /// @dev id 1 is reserved for reputation_token and 99 for premium passes
    uint256 public id = 100;

    /// @dev id -> rewardInfo
    mapping(uint256 => RewardInfo) internal rewardInfo;

    /// @dev id -> [all LootboxOptions]
    mapping(uint256 => LootboxOption[]) internal lootboxRewards;

    event LootboxOpened(uint256 indexed _lootboxId, uint256 indexed _idxOpened, address indexed _user);

    constructor(uint256 _creatorId, address _crafting, address _owner) Owned(_owner) ERC2771Context(_owner) {
        tokenURI = "https://matrix-metadata-server.zeet-matrix.zeet.app";
        creatorId = _creatorId;
        crafting = _crafting;
    }

    /// @notice allows the owner/crafting contract to mint tokens
    function mint(address _to, uint256 _id, uint256 _amount) public {
        if (owner == msg.sender || msg.sender == crafting) {
            _mint(_to, _id, _amount, "");
        } else {
            revert NoAccess();
        }
    }

    /// @notice allows the owner/crafting contract to burn tokens
    function burn(address _to, uint256 _id, uint256 _amount) public {
        if (owner == msg.sender || msg.sender == crafting) {
            _burn(_to, _id, _amount);
        } else {
            revert NoAccess();
        }
    }

    /**
     * @notice opens a lootbox
     * @param _id lootboxId to open
     */
    function openLootbox(uint256 _id) public returns (uint256) {
        address user = _msgSender();
        if (rewardInfo[_id].rewardType != REWARD_TYPE.LOOTBOX) {
            revert InvalidId(_id);
        }
        _burn(user, id, 1);
        uint256 idx = calculateRandom(id);
        LootboxOption memory option = lootboxRewards[id][idx];
        _batchMint(user, option.ids, option.qtys, "");
        emit LootboxOpened(id, idx, user);
        return idx;
    }

    /// @notice sets the uri
    function setURI(string memory _uri) external onlyOwner {
        tokenURI = _uri;
    }

    /// @notice sets the crafting proxy address
    function setCrafting(address _crafting) external onlyOwner {
        crafting = _crafting;
    }

    /**
     * @notice creates a new lootbox
     * @dev reverts when:
     *      joint rarity of all LootboxOptions does not add up to 100
     *      ids.length != qtys.length
     *      ids are invalid
     * @param _options all the LootboxOptions avaliable in a lootbox
     */
    function newLootbox(LootboxOption[] memory _options) external onlyOwner {
        id++;
        uint256 cumulativeProbability;
        for (uint256 x = 0; x < _options.length; x++) {
            if (_options[x].ids.length != _options[x].qtys.length) {
                revert IncorrectLootboxOptions();
            }
            cumulativeProbability += _options[x].rarityRange[1] - _options[x].rarityRange[0];
            lootboxRewards[id].push(_options[x]);
        }
        if (cumulativeProbability != 100) {
            revert IncorrectLootboxOptions();
        }
        rewardInfo[id].rewardType = REWARD_TYPE.LOOTBOX;
    }

    function createReward(RewardInfo[] calldata _rewardInfos) external onlyOwner {
        for (uint256 i; i < _rewardInfos.length; i++) {
            id++;
            rewardInfo[id] = _rewardInfos[i];
        }
    }

    /*//////////////////////////////////////////////////////////////////////
                                    UTILS
    //////////////////////////////////////////////////////////////////////*/

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

    /// @notice returns uri by id
    function uri(uint256 _id) public view override returns (string memory) {
        return string.concat(tokenURI, "/", Strings.toString(creatorId), "/", Strings.toString(_id), ".json");
    }
}
