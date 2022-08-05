// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC1155.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/metatx/ERC2771Context.sol";

/// @dev DO NOT CHANGE ORDERING, web3 service depends on this
enum RewardType {
    PREMIUM_PASS,
    CREATOR_TOKEN,
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

/// @dev used when an id is not within any of the approved id ranges
error InvalidId(uint256 id);

/// @dev used when the details for a new lootbox are incorrect
error IncorrectLootboxOptions();

/// @dev pls dont get here
error LOLHowDidYouGetHere(uint256 lootboxId);

/// @dev used when a non owner/crafting address tries to mint/burn
error NoAccess();

/**
 * @title Rewards given out by a Battle Pass
 * @author rayquaza7
 * @notice Mint creator specific tokens, premium passes, lootboxes, nfts, redeemable items
 * @dev
 * ERC1155 allows for both fungible and non-fungible tokens
 * | Token ID      | Description                                                                             |
 * |---------------|-----------------------------------------------------------------------------------------|
 * | 0             | Empty Reward                                                                            |
 * | 1-999         | Premium Passes (id === season_id); mint id x to give user a premium pass for season x   |
 * | 1000          | Creator's token; CreatorToken handles this token.                                       |
 * | 1,001-9,999   | Lootboxes                                                                               |
 * | 10,000-19,999 | Redeemable Items                                                                        |
 * | 20,000-29,999 | Special NFTs/tokens                                                                     |
 * | >30000        | Invalid, prevents errors                                                                |
 * allows for meta transactions
 */
abstract contract Rewards is ERC1155, Owned, ERC2771Context {
    /// @dev crafting contract address
    address public immutable crafting;

    /// @dev uri
    string public tokenURI;

    uint256 public constant PREMIUM_PASS_STARTING_ID = 1;
    uint256 public constant CREATOR_TOKEN_ID = 1000;
    uint256 public constant LOOTBOX_STARTING_ID = 1001;
    uint256 public constant REDEEMABLE_STARTING_ID = 10000;
    uint256 public constant SPECIAL_STARTING_ID = 20000;
    uint256 public constant INVALID_STARTING_ID = 30000;

    event LootboxOpened(
        uint256 indexed lootboxId,
        uint256 indexed idxOpened,
        address indexed user
    );

    constructor(string memory _uri, address _crafting)
        Owned(msg.sender)
        ERC2771Context(msg.sender)
    {
        tokenURI = _uri;
        crafting = _crafting;
    }

    /// @notice allows the owner/crafting contract to mint tokens
    /// @param to mint to address
    /// @param id mint id
    /// @param amount mint amount
    function mint(address to, uint256 id, uint256 amount) external {
        if (owner == msg.sender || msg.sender == crafting) {
            _mint(to, id, amount, "");
        } else {
            revert NoAccess();
        }
    }

    /// @notice allows the owner/crafting contract to burn tokens
    /// @param to burn from address
    /// @param id burn id
    /// @param amount burn amount
    function burn(address to, uint256 id, uint256 amount) external {
        if (owner == msg.sender || msg.sender == crafting) {
            _burn(to, id, amount);
        } else {
            revert NoAccess();
        }
    }

    /// @notice sets the uri
    /// @dev only owner can set it
    /// @param _uri new string with the format https://<>/creatorId/id.json
    function setURI(string memory _uri) external onlyOwner {
        tokenURI = _uri;
    }

    /*//////////////////////////////////////////////////////////////
                            LOOTBOX
    //////////////////////////////////////////////////////////////*/

    /// @dev lootboxId increments when a new lootbox is created
    uint256 public lootboxId = LOOTBOX_STARTING_ID - 1;

    /// @dev lootboxId->[all LootboxOptions]
    mapping(uint256 => LootboxOption[]) internal lootboxRewards;

    /**
     * @notice creates a new lootbox
     * @dev reverts when:
     * joint rarity of all LootboxOptions does not add up to 100
     * ids.length != qtys.length
     * ids are invalid
     * @param options all the LootboxOptions avaliable in a lootbox
     * @return new lootboxId
     */
    function newLootbox(LootboxOption[] memory options)
        external
        onlyOwner
        returns (uint256)
    {
        lootboxId++;
        uint256 cumulativeProbability;
        for (uint256 x = 0; x < options.length; x++) {
            if (options[x].ids.length != options[x].qtys.length) {
                revert IncorrectLootboxOptions();
            }
            cumulativeProbability +=
                options[x].rarityRange[1] - options[x].rarityRange[0];
            lootboxRewards[lootboxId].push(options[x]);
        }
        if (cumulativeProbability != 100) {
            revert IncorrectLootboxOptions();
        }

        return lootboxId;
    }

    /// @notice opens a lootbox
    /// @dev upto user to not send a bad id here.
    /// @param id lootboxId to open
    function openLootbox(uint256 id) external returns (uint256) {
        address user = _msgSender();
        _burn(user, id, 1);
        uint256 idx = calculateRandom(id);
        LootboxOption memory option = lootboxRewards[id][idx];
        _batchMint(user, option.ids, option.qtys, "");
        emit LootboxOpened(id, idx, user);
        return idx;
    }

    /// @notice calculates a pseudorandom index between 0-99
    function calculateRandom(uint256 id) public view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, blockhash(block.number), block.difficulty)
            )
        ) % 100;
        LootboxOption[] memory options = lootboxRewards[id];
        for (uint256 x; x < options.length; x++) {
            if (
                random >= options[x].rarityRange[0]
                    && random < options[x].rarityRange[1]
            ) {
                return x;
            }
        }
        revert LOLHowDidYouGetHere(id);
    }

    /// @notice gets a lootboxOption by lootboxId and index
    function getLootboxOptionByIdx(uint256 id, uint256 idx)
        external
        view
        returns (LootboxOption memory option)
    {
        return lootboxRewards[id][idx];
    }

    /// @notice gets a lootboxOptions length by lootboxId
    function getLootboxOptionsLength(uint256 id)
        external
        view
        returns (uint256)
    {
        return lootboxRewards[id].length;
    }

    /*//////////////////////////////////////////////////////////////////////
                            CREATOR TOKEN
    //////////////////////////////////////////////////////////////////////*/

    /// @notice tracks who delegates to whom and how much
    /// @dev delegator->delegatee->amount
    mapping(address => mapping(address => uint256)) public delegatedBy;

    /// @dev tracks the total delegated amount to an address
    mapping(address => uint256) public delegatedTotal;

    /// @dev emit when tokens are delegated
    event Delegated(
        address indexed delegator,
        address indexed delegatee,
        uint256 indexed amount
    );

    /// @dev emit when tokens are undelegated
    event Undelegated(
        address indexed delegator,
        address indexed delegatee,
        uint256 indexed amount
    );

    /// @notice delegates msg.sender's tokens to a delegatee
    /// @dev revert if balance is insufficient
    /// @param delegatee the address receiving the delegated tokens
    /// @param amount the amount of tokens to delegate
    function delegate(address delegatee, uint256 amount) external {
        address user = _msgSender();
        balanceOf[user][CREATOR_TOKEN_ID] -= amount;
        delegatedBy[user][delegatee] += amount;
        delegatedTotal[delegatee] += amount;
        emit Delegated(user, delegatee, amount);
    }

    /// @notice undelegates the tokens from a delegatee
    /// @dev revert if msg.sender tries to undelegate more tokens than they delegated
    /// @param delegatee the address who recevied the delegated tokens
    /// @param amount the amount of tokens to undelegate
    function undelegate(address delegatee, uint256 amount) external {
        address user = _msgSender();
        balanceOf[user][CREATOR_TOKEN_ID] += amount;
        delegatedBy[user][delegatee] -= amount;
        delegatedTotal[delegatee] -= amount;
        emit Undelegated(user, delegatee, amount);
    }

    /*//////////////////////////////////////////////////////////////////////
                                    UTILS
    //////////////////////////////////////////////////////////////////////*/

    /// @notice checks a reward type by id; will revert for 0
    function checkType(uint256 id) external pure returns (RewardType) {
        if (id == CREATOR_TOKEN_ID) {
            return RewardType.CREATOR_TOKEN;
        } else if (id >= PREMIUM_PASS_STARTING_ID && id < CREATOR_TOKEN_ID) {
            return RewardType.PREMIUM_PASS;
        } else if (id >= LOOTBOX_STARTING_ID && id < REDEEMABLE_STARTING_ID) {
            return RewardType.LOOTBOX;
        } else if (id >= REDEEMABLE_STARTING_ID && id < SPECIAL_STARTING_ID) {
            return RewardType.REDEEMABLE;
        } else if (id >= SPECIAL_STARTING_ID && id < INVALID_STARTING_ID) {
            return RewardType.SPECIAL;
        } else {
            revert InvalidId(id);
        }
    }

    /// @notice returns uri by id
    /// @return string with the format ipfs://<uri>/id.json
    function uri(uint256 id) public view override returns (string memory) {
        return string.concat(tokenURI, "/", Strings.toString(id), ".json");
    }
}
