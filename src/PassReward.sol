// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "solmate/tokens/ERC1155.sol";
import "solmate/auth/Owned.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

/**
 * @title Pass Rewards
 * @author rayquaza7
 * @notice mint creator specific tokens, premium passes, lootboxes, nfts, redeemable items, etc.
 * @dev
 * ERC1155 is used since it allows for both fungible and non fungible tokens
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
 * if you want to give out multiple qtys of an id then just add it multiple times
 */

struct LootboxOption {
    uint256[2] rarityRange;
    uint256[] ids;
}

uint256 constant CREATOR_TOKEN_ID = 1000;

/// @dev used when delagator tries to delegate more than they have
error InsufficientBalance(address delegator, uint256 owned, uint256 delegatedAmount);
/// @dev used when id is not within any of the approved id ranges
error InvalidId(uint256 id);
/// @dev used when ticket id does not exist
error TicketIdDoesNotExist(bytes32 ticketId);
/// @dev used when ranges for a new lootbox are incorrect
error ProbabilityRangeIncorrect();
/// @dev should never be called
error LOLHowDidYouGetHere(uint256 lootboxId);

abstract contract PassReward is ERC1155, Owned {
    constructor(string memory _uri) Owned(msg.sender) {
        tokenURI = _uri;
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
                            DELEGATION
    //////////////////////////////////////////////////////////////*/

    /// @dev delegator->delegatee->amount; track who delegates to whom and how much
    mapping(address => mapping(address => uint256)) public delegatedBy;
    /// @dev track total delegated to an address
    mapping(address => uint256) public delegatedTotal;

    /// @notice delegate tokens to delegatee
    /// @param delegator the address delegating tokens
    /// @param delegatee the address tokens are being delegated to
    /// @param amount the amount of tokens to delegate
    function delegate(
        address delegator,
        address delegatee,
        uint256 amount
    ) public onlyOwner {
        uint256 owned = balanceOf[delegator][CREATOR_TOKEN_ID];
        if (owned < amount) revert InsufficientBalance(delegator, owned, amount);
        balanceOf[delegator][CREATOR_TOKEN_ID] -= amount;
        delegatedBy[delegator][delegatee] += amount;
        delegatedTotal[delegatee] += amount;
    }

    /// @notice undeledelegate tokens from delegatee
    /// @param delegator the address that delegated tokens
    /// @param delegatee the address tokens were delegated to
    /// @param amount the amount of tokens to undelegate
    function undelegate(
        address delegator,
        address delegatee,
        uint256 amount
    ) public onlyOwner {
        uint256 amountDelegated = delegatedBy[delegator][delegatee];
        if (amountDelegated < amount) revert InsufficientBalance(delegator, amountDelegated, amount);
        balanceOf[delegator][CREATOR_TOKEN_ID] += amount;
        delegatedBy[delegator][delegatee] -= amount;
        delegatedTotal[delegator] -= amount;
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
    /// @dev lootbox id-> all options in a lootbox
    mapping(uint256 => LootboxOption[]) internal lootboxRewards;

    /// @notice create a new lootbox
    /// @dev check if id and probability ranges are valid
    /// @param options all the options avaliable in a lootbox
    /// @return new lootbox id
    function newLootbox(LootboxOption[] memory options) external onlyOwner returns (uint256) {
        lootboxId++;
        uint256 cumulativeProbability;
        for (uint256 x = 0; x < options.length; x++) {
            for (uint256 y; y < options[x].ids.length; y++) {
                checkType(options[x].ids[y]);
            }
            cumulativeProbability = options[x].rarityRange[1] - options[x].rarityRange[0];
            lootboxRewards[lootboxId].push(options[x]);
        }
        if (cumulativeProbability != 10) revert ProbabilityRangeIncorrect();
        return lootboxId;
    }

    /// @notice open a lootbox for a user
    /// @dev only owner can call it and user must own lootbox before
    /// @param id id of lootbox trying to open
    /// @param user trying to open a lootbox
    function openLootbox(uint256 id, address user) public onlyOwner {
        _burn(user, id, 1);
        uint256 idx = calculateRandom(id);
        LootboxOption memory option = lootboxRewards[id][idx];
        for (uint256 x; x < option.ids.length; x++) {
            _mint(user, id, 1, "");
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
