// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "../src/misc/SoupcansNFT.sol";

contract SoupcansNFTTest is Test {
    SoupcansNFT token;

    function setUp() public {
        token = new SoupcansNFT("");
    }

    function testConstructor() public {
        assertEq(token.baseTokenURI(), "");
    }

    function testTokenURI() public {
        assertEq(token.tokenURI(1), "ipfs:///1.json");
    }

    function testSetBaseTokenURI() public {
        token.setBaseTokenURI("1");
        assertEq(token.tokenURI(1), "ipfs://1/1.json");
    }

    function testCannotSetURIWithoutOwner() public {
        vm.prank(address(1));
        vm.expectRevert(bytes(abi.encodePacked("UNAUTHORIZED")));
        token.setBaseTokenURI("1");
    }

    function testToggleMint() public {
        assertEq(token.mintStart(), false);
        token.toggleMint(true);
        assertEq(token.mintStart(), true);
    }

    function testCannotToggleMintWithoutOwner() public {
        vm.prank(address(1));
        vm.expectRevert(bytes(abi.encodePacked("UNAUTHORIZED")));
        token.toggleMint(true);
    }

    function testSetPrice() public {
        assertEq(token.price(), 0);
        token.setPrice(10);
        assertEq(token.price(), 10);
    }

    function testCannotSetPriceWithoutOwner() public {
        vm.prank(address(1));
        vm.expectRevert(bytes(abi.encodePacked("UNAUTHORIZED")));
        token.setPrice(10);
    }

    function testMintForAuction() public {
        token.mintForAuction();
        assertEq(token.ownerOf(token.mintId()), address(this));
        assertEq(token.balanceOf(address(this)), 1);
    }

    function testCannotMintForAuctionWithoutOwner() public {
        vm.prank(address(1));
        vm.expectRevert(bytes(abi.encodePacked("UNAUTHORIZED")));
        token.mintForAuction();
    }

    function testCannotMintForAuctionBeyondReserved() public {
        token.mintForAuction();
        assertEq(token.ownerOf(token.mintId()), address(this));
        token.mintForAuction();
        assertEq(token.ownerOf(token.mintId()), address(this));
        token.mintForAuction();
        assertEq(token.ownerOf(token.mintId()), address(this));
        token.mintForAuction();
        assertEq(token.ownerOf(token.mintId()), address(this));
        token.mintForAuction();
        assertEq(token.ownerOf(token.mintId()), address(this));
        assertEq(token.balanceOf(address(this)), token.RESERVED_PRIVATE());

        vm.prank(address(1));
        vm.expectRevert(bytes(abi.encodePacked("UNAUTHORIZED")));
        token.mintForAuction();
    }

    function testWithdraw() public {
        vm.deal(address(this), 100);
        token.toggleMint(true);
        token.mint{value: 50}();
        token.mint{value: 50}();
        assertEq(address(token).balance, 100);
        address x = address(1);
        token.withdraw(payable(x));
        assertEq(address(1).balance, 100);
        assertEq(address(token).balance, 0);
    }

    function testCannotWithdrawWithoutOwner() public {
        vm.prank(address(1));
        vm.expectRevert(bytes(abi.encodePacked("UNAUTHORIZED")));
        address x = address(1);
        token.withdraw(payable(x));
    }

    function testPublicMint() public {
        token.toggleMint(true);
        token.setPrice(100);

        vm.deal(address(this), 100);
        vm.deal(address(1), 100);

        token.mint{value: 100}();
        assertEq(token.ownerOf(token.mintId()), address(this));

        vm.prank(address(1));
        token.mint{value: 100}();
        assertEq(token.ownerOf(token.mintId()), address(1));
    }

    function testCannotPublicMintNotStarted() public {
        vm.expectRevert(bytes(abi.encodePacked("MINT HAS NOT STARTED")));
        token.mint{value: 100}();
    }

    function testCannotPublicMintInsufficientPrice() public {
        token.toggleMint(true);
        token.setPrice(100);
        vm.expectRevert(bytes(abi.encodePacked("MINT PRICE MORE THAN ETH SENT")));
        token.mint{value: 10}();
    }

    function testCannotPublicMintSoldOut() public {
        token.toggleMint(true);
        for (uint256 x; x < token.TOTAL_SUPPLY(); x++) {
            token.mint();
        }
        vm.expectRevert(bytes(abi.encodePacked("SOLD OUT")));
        token.mint();
    }
}
