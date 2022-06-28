// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Helper.sol";
import "../src/rewards/MERC20.sol";

contract MERC20Test is Helper {
    MERC20 public token;
    string public name = "token";
    string public symbol = "tkn";
    uint8 public decimals = 18;

    function setUp() public {
        token = new MERC20(name, symbol, decimals, mockPass, mockRecipe);
    }

    function testConstructor() public {
        assertEq(token.hasRole(token.DEFAULT_ADMIN_ROLE(), address(this)), true);
        assertEq(token.hasRole(MINTER_ROLE, address(this)), true);
        assertEq(token.hasRole(MINTER_ROLE, mockRecipe), true);
        assertEq(token.hasRole(MINTER_ROLE, mockPass), true);
        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.decimals(), decimals);
    }

    function testMint() public {
        token.mint(mockUser, 1);
        assertEq(1, token.balanceOf(mockUser));
    }

    function testCannotMintNotMinter() public {
        vm.expectRevert(revertAccessControl(mockUser, MINTER_ROLE));
        vm.prank(mockUser);
        token.mint(mockUser, 1);
    }

    function testBurn() public {
        token.mint(mockUser, 1);
        token.burn(mockUser, 1);
        assertEq(0, token.balanceOf(mockUser));
    }

    function testCannotBurnNotMinter() public {
        token.mint(mockUser, 1);
        vm.expectRevert(revertAccessControl(mockUser, MINTER_ROLE));
        vm.prank(mockUser);
        token.burn(mockUser, 1);
    }
}
