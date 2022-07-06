// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./ICreatorToken.sol";
import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC1155.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

enum RewardType {
    PREMIUM_PASS,
    CREATOR_TOKEN,
    LOOTBOX,
    REDEEMABLE,
    SPECIAL
}

enum RedeemStatus {
    REDEEMED,
    PROCESSING,
    REJECTED
}

struct Redemption {
    uint256 itemId;
    RedeemStatus status;
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

uint256 constant CREATOR_TOKEN_ID = 1000;

/// @dev used when id is not within any of the approved id ranges
error InvalidId(uint256 id);
/// @dev used when ticket id does not exist
error TicketIdDoesNotExist(bytes32 ticketId);
/// @dev used when details for a new lootbox are incorrect
error IncorrectLootboxOptions();
/// @dev should never be called
error LOLHowDidYouGetHere(uint256 lootboxId);

/**
 * @title Pass Rewards
 * @author rayquaza7
 * @notice mint creator specific tokens, premium passes, lootboxes, nfts, redeemable items, etc.
 * @dev
 * ERC1155 is used since it allows for both fungible and non fungible tokens
 * crafting contract is allowed to mint burn items for a user based on recipes
 * TOKEN IDS to give out as rewards:
 * 1-999: Premium Passses for different seasons.
 * if a user has token id 2, that means they have a premium pass for season 2.
 * assumes that no creator will realistically create more than 1000 seasons
 * 1000: Creator specific token
 * 1,001-10,000: Lootboxes
 * 10,001-20,000: Redeemable Items
 * 20,001-30,000: Special use items, nfts/tokens with unique logic according to creator requirement
 *
 */
abstract contract Rewards is ERC1155, Owned {
    constructor(string memory _uri, address _crafting) Owned(msg.sender) {
        tokenURI = _uri;
        crafting = _crafting;
    }

    /// @notice check reward type given id
    function checkType(uint256 id) public pure returns (RewardType) {
        if (id == CREATOR_TOKEN_ID) {
            return RewardType.CREATOR_TOKEN;
        } else if (id >= 1 && id <= 999) {
            return RewardType.PREMIUM_PASS;
        } else if (id >= 1001 && id <= 10000) {
            return RewardType.LOOTBOX;
        } else if (id >= 10001 && id <= 20000) {
            return RewardType.REDEEMABLE;
        } else if (id >= 20001 && id <= 30000) {
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
                                CRAFTING
    //////////////////////////////////////////////////////////////*/

    /// @dev crafting address, upgradeable by admin
    address public crafting;

    /// @notice change crafting address
    /// @param newCrafting new crafting address
    function setCrafting(address newCrafting) external onlyOwner {
        crafting = newCrafting;
    }

    /// @notice allow crafting & owner to mint items
    /// @dev revert if id == CREATOR_TOKEN_ID since its handled by different contract
    /// revert if id is invalid
    /// @param to address to mint to
    /// @param id id to mint
    /// @param amount to mint
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public {
        require(owner == msg.sender || msg.sender == crafting, "Only crafting/owner can mint/burn");
        require(id != CREATOR_TOKEN_ID, "CANNOT MINT CREATOR TOKEN");
        checkType(id);
        _mint(to, id, amount, "");
    }

    /// @notice allow crafting & owner to burn items
    /// @dev revert if id == CREATOR_TOKEN_ID since its handled by different contract
    /// revert if id is invalid; will revert if there is an underflow
    /// @param from address to burn from
    /// @param id to burn
    /// @param amount to burn
    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public {
        require(owner == msg.sender || msg.sender == crafting, "Only crafting/owner can mint/burn");
        require(id != CREATOR_TOKEN_ID, "CANNOT BURN CREATOR TOKEN");
        checkType(id);
        _burn(from, id, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        REDEEMABLE ITEMS
    //////////////////////////////////////////////////////////////*/

    /// @dev redeemed entries for a given address
    /// ticketId->Redemption
    mapping(bytes32 => Redemption) public redeemed;

    /// @notice redeeem a redeemable item
    /// @dev id must be within approved range of redeeemable items
    /// @param ticketId ticketId sent by ticketing service
    /// @param user address that wants to redeem the item
    /// @param id id of reward to redeem
    function redeemReward(
        bytes32 ticketId,
        address user,
        uint256 id
    ) external onlyOwner {
        redeemed[ticketId] = Redemption(id, RedeemStatus.PROCESSING);
        _burn(user, id, 1);
    }

    /// @notice update redemption status of ticketId
    /// @dev revert if ticket id does not exist
    /// @param ticketId ticketId sent by ticketing service
    /// @param status new status
    function updateStatus(bytes32 ticketId, RedeemStatus status) external onlyOwner {
        Redemption storage redeemedByUser = redeemed[ticketId];
        if (redeemedByUser.itemId == 0) revert TicketIdDoesNotExist(ticketId);
        redeemedByUser.status = status;
    }

    /*//////////////////////////////////////////////////////////////
                            LOOTBOX
    //////////////////////////////////////////////////////////////*/

    /// @dev lootbox id incremented when a new lootbox is created
    uint256 public lootboxId = 1001;
    /// @dev creator token contract address
    address public creatorTokenCtr;
    /// @dev lootbox id-> all options in a lootbox
    mapping(uint256 => LootboxOption[]) internal lootboxRewards;

    /// @notice set token contract for creator
    function setCreatorTokenCtr(address _creatorTokenCtr) public onlyOwner {
        creatorTokenCtr = _creatorTokenCtr;
    }

    /**
     * @notice create a new lootbox
     * @dev c
     * will recert if prob ranges dont add upto 10
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
    /// call the creator token contract if id == CREATOR_TOKEN_ID
    ///
    /// @param id id of lootbox trying to open
    /// @param user trying to open a lootbox
    function openLootbox(uint256 id, address user) public onlyOwner {
        _burn(user, id, 1);
        uint256 idx = calculateRandom(id);
        LootboxOption memory option = lootboxRewards[id][idx];
        for (uint256 x; x < option.ids.length; x++) {
            if (option.ids[x] == CREATOR_TOKEN_ID && creatorTokenCtr != address(0)) {
                ICreatorToken(creatorTokenCtr).mint(user, option.qtys[x]);
            } else {
                _mint(user, option.ids[x], option.qtys[x], "");
            }
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
