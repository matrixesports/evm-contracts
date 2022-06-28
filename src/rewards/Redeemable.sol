// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./MERC1155.sol";

error TicketIdDoesNotExist(address user, string ticketId);

enum Status {
    REDEEMED,
    PROCESSING,
    REJECTED
}

struct Redemption {
    string ticketId;
    uint256 itemId;
    Status status;
}

//length and reading probs

// hypothesis: will increase creator accountability
contract Redeemable is MERC1155 {
    ///@dev u can see for a given addresses all the redeemed items
    mapping(address => Redemption[]) public redeemed;
    mapping(address => uint256) public qtyRedeemed;

    constructor(
        string memory uri,
        address passOrLootbox,
        address recipe
    ) MERC1155(uri, passOrLootbox, recipe) {}

    ///@dev will revert if user does not own id; called by web3-service when item is redeemed
    function redeemReward(
        string calldata ticketId,
        address user,
        uint256 id
    ) external {
        qtyRedeemed[user]++;
        burn(user, id, 1);
        redeemed[user].push(Redemption(ticketId, id, Status.PROCESSING));
    }

    ///@dev called when redemption process is either fullfilled or rejected
    function updateStatus(
        address user,
        string calldata ticketId,
        Status status
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Redemption[] storage redeemedByUser = redeemed[user];
        bool found = false;
        for (uint256 x; x < redeemedByUser.length; x++) {
            if (
                keccak256(abi.encodePacked(redeemedByUser[x].ticketId)) ==
                keccak256(abi.encodePacked(ticketId))
            ) {
                redeemedByUser[x].status = status;
                found = true;
            }
        }
        if (!found) revert TicketIdDoesNotExist(user, ticketId);
    }
}
