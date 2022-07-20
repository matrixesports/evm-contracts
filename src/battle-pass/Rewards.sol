// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./ICreatorToken.sol";
import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC1155.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

/// @dev DO NOT CHANGE ORDERING, web3 service depends on this
enum RewardType {
    PREMIUM_PASS,
    CREATOR_TOKEN,
    LOOTBOX,
    REDEEMABLE,
    SPECIAL
}

/**
 *  @dev a lootbox is a collection of LootboxOptions
 * rarity is rarityRange[1] - rarityRange[0]
 * the rarity of all LootboxOptions must add up to 10
 * rarityRange[0] is inclusive and rarityRange[1] is exclusive
 * give qtys[x] of ids[x]  (ids.length == qtys.length)
 * if any of the ids is CREATOR_TOKEN_ID then call the creator token contract
 */
struct LootboxOption {
    uint256[2] rarityRange;
    uint256[] ids;
    uint256[] qtys;
}

/// @dev use when an id is not within any of the approved id ranges
error InvalidId(uint256 id);
/// @dev use when a ticket id does not exist
error TicketIdDoesNotExist(bytes32 ticketId);
/// @dev use when the details for a new lootbox are incorrect
error IncorrectLootboxOptions();
/// @dev fail-safe guard
error LOLHowDidYouGetHere(uint256 lootboxId);
/// @dev use when a non-whitelisted address attempts to mint or burn
error NotWhitelisted(address sender);

/**
 * @title Pass Rewards
 * @author rayquaza7
 * @notice
 * Mint creator specific tokens, premium passes, lootboxes, nfts, redeemable items, etc.
 * @dev
 * ERC1155 allows for both fungible and non-fungible tokens
 * Crafting/Game contracts and owner can mint and burn items for a user
 * | Token ID      | Description                                                                             |
 * |---------------|-----------------------------------------------------------------------------------------|
 * | 0             | Empty Reward                                                                            |
 * | 1-999         | Premium Passes (id === season_id); mint id x to give user a premium pass for season x   |
 * | 1000          | Creator's token; CreatorToken handles this token.                                       |
 * |               | Battle Pass is whitelisted to distribute and calls CreatorToken when id === 1000        |
 * | 1,001-9,999   | Lootboxes                                                                               |
 * | 10,000-19,999 | Redeemable Items                                                                        |
 * | 20,000-29,999 | Special NFTs/tokens                                                                     |
 * | 20,100-20,199 |        MTX-Game: defender items                                                         |
 * | 20,200-20,299 |        MTX-Game: attacker items                                                         |
 * | >30000        | Invalid, prevents errors                                                                |
 */
abstract contract Rewards is ERC1155, Owned {
    /// @dev adddresses that are allowed to mint/burn tokens
    mapping(address => bool) public whitelisted;
    /// @dev creator token contract address
    address public creatorTokenCtr;

    uint256 public constant PREMIUM_PASS_STARTING_ID = 1;
    uint256 public constant CREATOR_TOKEN_ID = 1_000;
    uint256 public constant LOOTBOX_STARTING_ID = 1_001;
    uint256 public constant REDEEMABLE_STARTING_ID = 10_000;
    uint256 public constant SPECIAL_STARTING_ID = 20_000;
    uint256 public constant INVALID_STARTING_ID = 30_000;

    event LootboxOpened(uint256 indexed lootboxId, uint256 indexed idOpened, address indexed user);

    /// @notice whitelists game, crafting and msg.sender
    constructor(
        string memory _uri,
        address crafting,
        address game,
        address _creatorTokenCtr
    ) Owned(msg.sender) {
        tokenURI = _uri;
        whitelisted[msg.sender] = true;
        whitelisted[crafting] = true;
        whitelisted[game] = true;
        creatorTokenCtr = _creatorTokenCtr;
    }

    /// @notice sets the creator token contract
    /// @dev only owner can call it
    /// @param _creatorTokenCtr new creator token contract address
    function setCreatorTokenCtr(address _creatorTokenCtr) public onlyOwner {
        creatorTokenCtr = _creatorTokenCtr;
    }

    /// @notice add/remove address from the whitelist
    /// @param grantPower address to update permission
    /// @param toggle to give mint and burn permission
    function togglewhitelisted(address grantPower, bool toggle) external onlyOwner {
        whitelisted[grantPower] = toggle;
    }

    /*//////////////////////////////////////////////////////////////////////
                            WHITELISTED ACTIONS
    //////////////////////////////////////////////////////////////////////*/

    /// @notice allows the whitelisted address to mint tokens
    /// @dev reverts when id is invalid
    /// @param to mint to address
    /// @param id mint id
    /// @param amount mint amount
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public {
        if (!whitelisted[msg.sender]) revert NotWhitelisted(msg.sender);
        RewardType reward = checkType(id);
        if (reward == RewardType.CREATOR_TOKEN) {
            mintCreatorToken(to, amount);
        } else {
            _mint(to, id, amount, "");
        }
    }

    /// @notice allows the whitelisted address to burn tokens
    /// @dev reverts when id is invalid
    /// @param from burn from address
    /// @param id burn id
    /// @param amount burn amount
    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public {
        if (!whitelisted[msg.sender]) revert NotWhitelisted(msg.sender);
        RewardType reward = checkType(id);
        if (reward == RewardType.CREATOR_TOKEN) {
            burnCreatorToken(from, amount);
        } else {
            _burn(from, id, amount);
        }
    }

    /// @notice mints creator tokens
    /// @dev must be whitelisted by the CreatorToken
    /// @param to mint to address
    /// @param amount mint amount
    function mintCreatorToken(address to, uint256 amount) private {
        ICreatorToken(creatorTokenCtr).mint(to, amount);
    }

    /// @notice burns creator tokens
    /// @dev must be whitelisted by the CreatorToken
    /// reverts when a user does NOT own sufficient amount of tokens
    /// @param from user address to burn from
    /// @param amount amount to burn
    function burnCreatorToken(address from, uint256 amount) private {
        ICreatorToken(creatorTokenCtr).burn(from, amount);
    }

    /*//////////////////////////////////////////////////////////////////////
                                    UTILS
    //////////////////////////////////////////////////////////////////////*/

    /// @notice checks a reward type by id
    function checkType(uint256 id) public pure returns (RewardType) {
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

    /*//////////////////////////////////////////////////////////////
                                URI
    //////////////////////////////////////////////////////////////*/

    /// @dev uri with the format ipfs://
    string public tokenURI;

    /// @notice returns uri by id
    /// @return string with the format ipfs://<uri>/id.json
    function uri(uint256 id) public view override returns (string memory) {
        return string.concat(tokenURI, "/", Strings.toString(id), ".json");
    }

    /// @notice sets the uri
    /// @dev only owner can call it
    /// @param _uri new string with the format ipfs://<uri>/
    function setURI(string memory _uri) external onlyOwner {
        tokenURI = _uri;
    }

    /*//////////////////////////////////////////////////////////////
                            LOOTBOX
    //////////////////////////////////////////////////////////////*/

    /// @dev lootboxId increments when a new lootbox is created
    uint256 public lootboxId = LOOTBOX_STARTING_ID;

    /// @dev lootboxId->[all LootboxOptions]
    mapping(uint256 => LootboxOption[]) internal lootboxRewards;

    /**
     * @notice creates a new lootbox
     * @dev reverts when:
     *      joint rarity of all LootboxOptions does not add up to 10
     *      ids.length != qtys.length
     *      ids are invalid
     * @param options all the LootboxOptions avaliable in a lootbox
     * @return new lootboxId
     */
    function newLootbox(LootboxOption[] memory options) external onlyOwner returns (uint256) {
        lootboxId++;
        uint256 cumulativeProbability;
        for (uint256 x = 0; x < options.length; x++) {
            if (options[x].ids.length != options[x].qtys.length) revert IncorrectLootboxOptions();
            for (uint256 y; y < options[x].ids.length; y++) {
                checkType(options[x].ids[y]);
            }
            cumulativeProbability += options[x].rarityRange[1] - options[x].rarityRange[0];
            lootboxRewards[lootboxId].push(options[x]);
        }
        if (cumulativeProbability != 10) revert IncorrectLootboxOptions();
        return lootboxId;
    }

    /// @notice opens a lootbox for a user
    /// @dev only owner can call it and user must own lootbox before
    /// reverts when id is not a lootbox
    /// @param id lootboxId to open
    /// @param user mint lootboxOption rewards to user address
    function openLootbox(uint256 id, address user) public onlyOwner {
        RewardType reward = checkType(id);
        if (reward != RewardType.LOOTBOX) revert InvalidId(id);
        _burn(user, id, 1);
        uint256 idx = calculateRandom(id);
        LootboxOption memory option = lootboxRewards[id][idx];
        for (uint256 x; x < option.ids.length; x++) {
            mint(user, option.ids[x], option.qtys[x]);
        }
        emit LootboxOpened(id, idx, user);
    }

    /// @notice calculates a pseudorandom index between 0-9
    /// @dev vulnerable to timing attacks
    function calculateRandom(uint256 id) public view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(msg.sender, block.timestamp, block.number, blockhash(block.number), block.difficulty)
            )
        ) % 10;
        LootboxOption[] memory options = lootboxRewards[id];
        for (uint256 x; x < options.length; x++) {
            // rarityRange[0] is inclusive and rarityRange[1] is exclusive
            if (random >= options[x].rarityRange[0] && random < options[x].rarityRange[1]) {
                return x;
            }
        }
        revert LOLHowDidYouGetHere(id);
    }

    /// @notice gets a lootboxOption by lootboxId and index
    function getLootboxOptionByIdx(uint256 id, uint256 idx) public view returns (LootboxOption memory option) {
        return lootboxRewards[id][idx];
    }

    /// @notice gets a lootboxOptions length by lootboxId
    function getLootboxOptionsLength(uint256 id) public view returns (uint256) {
        return lootboxRewards[id].length;
    }
}
