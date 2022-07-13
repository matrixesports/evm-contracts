// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./ICreatorToken.sol";
import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC1155.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

/// @dev type of reward that can be given out
/// DO NOT CHANGE ORDERING, web3 service depends on this
enum RewardType {
    PREMIUM_PASS,
    CREATOR_TOKEN,
    LOOTBOX,
    REDEEMABLE,
    SPECIAL
}

/**
 *  @dev a lootbox takes in multiple LootboxOptions and rewards one to the user
 * rarityRange of 0-1 means that the user has a 10% chance of getting this
 * the rarity range of all lootboxes must add up to be 1
 * the lower bound is inclusive and the upper bound is exclusive
 * ids correspond to the array of ids to give out for this option
 * give qtys[x] of ids[x]
 * ids.length == qtys.length
 * if any of the ids is CREATOR_TOKEN_ID then call the creator token contract
 */
struct LootboxOption {
    uint256[2] rarityRange;
    uint256[] ids;
    uint256[] qtys;
}

/// @dev used when id is not within any of the approved id ranges or is not appropriate for the item
error InvalidId(uint256 id);
/// @dev used when ticket id does not exist
error TicketIdDoesNotExist(bytes32 ticketId);
/// @dev used when details for a new lootbox are incorrect
error IncorrectLootboxOptions();
/// @dev should never be called
error LOLHowDidYouGetHere(uint256 lootboxId);
/// @dev used when a non whitelisted address tries to mint or burn
error NotWhitelisted(address sender);

/**
 * @title Pass Rewards
 * @author rayquaza7
 * @notice mint creator specific tokens, premium passes, lootboxes, nfts, redeemable items, etc.
 * @dev
 * ERC1155 is used since it allows for both fungible and non fungible tokens
 * crafting contract, owner and the game contract are allowed to mint burn items for a user
 * Premium passes: ids 1-999 reserved for issuing premium passes for new seasons.
 * seasons x needs to mint id x in order to give user a premium pass
 * Creator Token: NOT minted by the Battle Pass, it is minted by the creator token contract
 * however, a Battle Pass is allowed to give creator tokens as a reward.
 * So, the creator token whitelists the pass contract and when you want to give out the tokens
 * you specify id CREATOR_TOKEN_ID so that the contract knows that it has to call the token contract
 * Lootbox: ids 1001-9999 reserved for creating new lootboxes, a battle pass can give out new lootboxes as
 * a reward.
 * Redeemable: ids 10,000-19999 reserved for redeemable items. These are items that require manual intervention
 * by a creator
 * Special: ids 20000-29999 reserved for default items like nfts, game items, one off tokens, etc.
 * Currently defined special items:
 * - ids 20,100-20199 reserved for MTX game defender items
 * - ids 20,200-20299 reserved for MTX game attacker items
 * anything bove 30,000 is considered invalid to prevent mistakes
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

    /// @notice whitelist game, crafting and msg.sender
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

    /// @notice set token contract for creator
    function setCreatorTokenCtr(address _creatorTokenCtr) public onlyOwner {
        creatorTokenCtr = _creatorTokenCtr;
    }

    /// @notice add/remove address from the whitelist
    /// @param grantPower address to update in whitelist
    /// @param toggle true if want the address to have mint/burn priv
    function togglewhitelisted(address grantPower, bool toggle) external onlyOwner {
        whitelisted[grantPower] = toggle;
    }

    /*//////////////////////////////////////////////////////////////////////
                            WHITELISTED ACTIONS
    //////////////////////////////////////////////////////////////////////*/

    /// @notice allow whitelisted address to mint tokens
    /// @dev revert if id is invalid
    /// @param to address to mint to
    /// @param id id to mint
    /// @param amount to mint
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

    /// @notice allow whitelisted address to burn tokens
    /// @dev revert if id is invalid
    /// @param from address to burn from
    /// @param id id to burn
    /// @param amount to burn
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

    /// @dev handle mintiting of tokens here since then the token contract
    /// only needs to whitelist its respective pass contract
    /// @param to user address to mint to
    /// @param amount amount to mint
    function mintCreatorToken(address to, uint256 amount) private {
        ICreatorToken(creatorTokenCtr).mint(to, amount);
    }

    /// @dev handle burning of tokens here since then the token contract
    /// only needs to whitelist its respective pass contract
    /// will revert if user does not own sufficient amount of tokens
    /// @param from user address to burn from
    /// @param amount amount to burn
    function burnCreatorToken(address from, uint256 amount) private {
        ICreatorToken(creatorTokenCtr).burn(from, amount);
    }

    /*//////////////////////////////////////////////////////////////////////
                                    UTILS
    //////////////////////////////////////////////////////////////////////*/

    /// @notice check reward type given id
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

    /// @dev uri for this contract
    string public tokenURI;

    /// @notice return uri for an id
    /// @return string in format ipfs://<uri>/id.json
    function uri(uint256 id) public view override returns (string memory) {
        return string.concat(tokenURI, "/", Strings.toString(id), ".json");
    }

    /// @notice set uri for this contract
    /// @dev only owner can call it
    /// @param _uri new ipfs hash
    function setURI(string memory _uri) external onlyOwner {
        tokenURI = _uri;
    }

    /*//////////////////////////////////////////////////////////////
                            LOOTBOX
    //////////////////////////////////////////////////////////////*/

    /// @dev lootbox id incremented when a new lootbox is created
    uint256 public lootboxId = LOOTBOX_STARTING_ID;

    /// @dev lootbox id-> all options in a lootbox
    mapping(uint256 => LootboxOption[]) internal lootboxRewards;

    /**
     * @notice create a new lootbox
     * @dev
     * will revert if prob ranges dont add upto 10
     * will revert if  if length of ids != length of qtys
     * will rever if invalid ids are passed to be added
     * @param options all the options avaliable in a lootbox
     * @return new lootbox id
     */
    function newLootbox(LootboxOption[] memory options) external onlyOwner returns (uint256) {
        lootboxId++;
        uint256 cumulativeProbability;
        for (uint256 x = 0; x < options.length; x++) {
            for (uint256 y; y < options[x].ids.length; y++) {
                checkType(options[x].ids[y]);
                if (options[x].ids.length != options[x].qtys.length) revert IncorrectLootboxOptions();
            }
            cumulativeProbability = options[x].rarityRange[1] - options[x].rarityRange[0];
            lootboxRewards[lootboxId].push(options[x]);
        }
        if (cumulativeProbability != 10) revert IncorrectLootboxOptions();
        return lootboxId;
    }

    /// @notice open a lootbox for a user
    /// @dev only owner can call it and user must own lootbox before
    /// revert if id trying to open is not a lootbox
    /// @param id id of lootbox trying to open
    /// @param user trying to open a lootbox
    function openLootbox(uint256 id, address user) public onlyOwner {
        RewardType reward = checkType(id);
        if (reward != RewardType.LOOTBOX) revert InvalidId(id);
        _burn(user, id, 1);
        uint256 idx = calculateRandom(id);
        LootboxOption memory option = lootboxRewards[id][idx];
        for (uint256 x; x < option.ids.length; x++) {
            mint(user, option.ids[x], option.qtys[x]);
        }
    }

    /// @notice calculate index of a lootbox that a random number falls between
    /// @dev highly unlikely that a miner will want a creator token
    function calculateRandom(uint256 id) public view returns (uint256) {
        // returns a number between 0-9
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(msg.sender, block.timestamp, block.number, blockhash(block.number), block.difficulty)
            )
        ) % 10;
        LootboxOption[] memory options = lootboxRewards[id];
        for (uint256 x; x < options.length; x++) {
            // lower bound is inclusive but upper isnt
            if (random >= options[x].rarityRange[0] && random < options[x].rarityRange[1]) {
                return x;
            }
        }
        revert LOLHowDidYouGetHere(id);
    }

    /// @notice get lootbox option for a given lootbox and index
    function getLootboxOptionByIdx(uint256 id, uint256 idx) public view returns (LootboxOption memory option) {
        return lootboxRewards[id][idx];
    }

    /// @notice get number of options in a given lootbox id
    function getLootboxOptionsLength(uint256 id) public view returns (uint256) {
        return lootboxRewards[id].length;
    }
}
