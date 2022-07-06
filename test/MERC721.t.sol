// // SPDX-License-Identifier: MIT
// pragma solidity >=0.8.0;

// import "./Helper.sol";
// import "../src/rewards/MERC721.sol";

// contract MERC721Test is Helper {
//     MERC721 public token;
//     string public name = "token";
//     string public symbol = "tkn";

//     function setUp() public {
//         token = new MERC721(name, symbol, uri, mockPass, mockRecipe);
//     }

//     function testConstructor() public {
//         assertEq(token.hasRole(token.DEFAULT_ADMIN_ROLE(), address(this)), true);
//         assertEq(token.hasRole(MINTER_ROLE, address(this)), true);
//         assertEq(token.hasRole(MINTER_ROLE, mockRecipe), true);
//         assertEq(token.hasRole(MINTER_ROLE, mockPass), true);
//         assertEq(token.name(), name);
//         assertEq(token.symbol(), symbol);
//         assertEq(token.uri(), uri);
//     }

//     function testMint() public {
//         uint256 oldId = token.currentId();
//         token.mint(mockUser);
//         uint256 newId = token.currentId();
//         assertEq(1, token.balanceOf(mockUser));
//         assertEq(oldId + 1, newId);
//     }

//     function testCannotMintNotMinter() public {
//         vm.expectRevert(revertAccessControl(mockUser, MINTER_ROLE));
//         vm.prank(mockUser);
//         token.mint(mockUser);
//     }

//     function testBurn() public {
//         token.mint(mockUser);
//         token.burn(mockUser, token.currentId());
//         assertEq(0, token.balanceOf(mockUser));
//     }

//     function testCannotBurnNotMinter() public {
//         token.mint(mockUser);
//         uint256 id = token.currentId();
//         vm.expectRevert(revertAccessControl(mockUser, MINTER_ROLE));
//         vm.prank(mockUser);
//         token.burn(mockUser, id);
//     }

//     function testCannotBurnNotOwned() public {
//         vm.expectRevert(abi.encodeWithSelector(NotOwnedByUser.selector, mockUser, 1));
//         token.burn(mockUser, 1);
//     }

//     function testSetUri() public {
//         token.setURI("0xbeef");
//         assertEq(token.uri(), "0xbeef");
//     }

//     function testCannotSetUriWithoutAdmin() public {
//         vm.expectRevert(revertAccessControl(mockUser, token.DEFAULT_ADMIN_ROLE()));
//         vm.prank(mockUser);
//         token.setURI("0xbeef");
//     }
// }
