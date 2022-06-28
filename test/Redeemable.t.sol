// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Helper.sol";
import "../src/rewards/Redeemable.sol";

contract RedeemableTest is Helper {
    Redeemable public redeemable;
    string public tempTicketId = "xx";
    uint256 public idToMint = 1;

    function setUp() public {
        redeemable = new Redeemable(uri, mockPass, mockRecipe);
        redeemable.mint(mockUser, idToMint, 1, "");
    }

    function testConstructor() public {
        assertEq(redeemable.hasRole(redeemable.DEFAULT_ADMIN_ROLE(), address(this)), true);
        assertEq(redeemable.hasRole(MINTER_ROLE, mockPass), true);
        assertEq(redeemable.hasRole(MINTER_ROLE, address(this)), true);
        assertEq(redeemable.hasRole(MINTER_ROLE, mockRecipe), true);
        assertEq(redeemable.tokenURI(), uri);
    }

    function testRedeemReward() public {
        redeemable.redeemReward(tempTicketId, mockUser, idToMint);
        assertEq(redeemable.qtyRedeemed(mockUser), 1);
        assertEq(redeemable.balanceOf(mockUser, idToMint), 0);

        (string memory ticketId, uint256 itemId, Status status) = redeemable.redeemed(mockUser, 0);
        assertEq(ticketId, tempTicketId);
        assertEq(itemId, idToMint);
        assertEq(uint256(status), uint256(Status.PROCESSING));

        redeemable.mint(mockUser, idToMint, 1, "");
        redeemable.redeemReward(tempTicketId, mockUser, idToMint);
        assertEq(redeemable.qtyRedeemed(mockUser), 2);
        (ticketId, itemId, status) = redeemable.redeemed(mockUser, 1);
        assertEq(ticketId, tempTicketId);
        assertEq(itemId, idToMint);
        assertEq(uint256(status), uint256(Status.PROCESSING));
    }

    function testCannotRedeemRewardNotOwned() public {
        vm.expectRevert(stdError.arithmeticError);
        redeemable.redeemReward("", mockUser, 2);
    }

    function testUpdateStatus() public {
        redeemable.redeemReward(tempTicketId, mockUser, idToMint);
        redeemable.updateStatus(mockUser, tempTicketId, Status.REDEEMED);
        (, , Status status) = redeemable.redeemed(mockUser, 0);
        assertEq(uint256(status), uint256(Status.REDEEMED));
    }

    function testCannotUpdateStatusWithoutAdmin() public {
        vm.expectRevert(revertAccessControl(mockUser, redeemable.DEFAULT_ADMIN_ROLE()));
        vm.prank(mockUser);
        redeemable.updateStatus(mockUser, tempTicketId, Status.REDEEMED);
    }

    function testCannotUpdateStatusInvalidTicket() public {
        redeemable.redeemReward(tempTicketId, mockUser, idToMint);
        vm.expectRevert(abi.encodeWithSelector(TicketIdDoesNotExist.selector, mockUser, ""));
        redeemable.updateStatus(mockUser, "", Status.REDEEMED);
    }
}
