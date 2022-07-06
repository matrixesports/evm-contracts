// // SPDX-License-Identifier: MIT
// pragma solidity >=0.8.0;

// import "./Helper.sol";
// import "../src/rewards/MERC1155.sol";

// contract MERC1155Test is Helper {
//     MERC1155 public token;

//     function setUp() public {
//         token = new MERC1155(uri, mockPass, mockRecipe);
//     }

//     function testConstructor() public {
//         assertEq(token.hasRole(token.DEFAULT_ADMIN_ROLE(), address(this)), true);
//         assertEq(token.hasRole(MINTER_ROLE, address(this)), true);
//         assertEq(token.hasRole(MINTER_ROLE, mockRecipe), true);
//         assertEq(token.hasRole(MINTER_ROLE, mockPass), true);
//         assertEq(token.tokenURI(), uri);
//     }

//     function testMint() public {
//         token.mint(mockUser, 1, 1, "");
//         assertEq(1, token.balanceOf(mockUser, 1));
//     }

//     function testCannotMintNotMinter() public {
//         vm.expectRevert(revertAccessControl(mockUser, MINTER_ROLE));
//         vm.prank(mockUser);
//         token.mint(mockUser, 1, 1, "");
//     }

//     function testBurn() public {
//         token.mint(mockUser, 1, 1, "");
//         token.burn(mockUser, 1, 1);
//         assertEq(0, token.balanceOf(mockUser, 1));
//     }

//     function testCannotBurnNotMinter() public {
//         token.mint(mockUser, 1, 1, "");
//         vm.expectRevert(revertAccessControl(mockUser, MINTER_ROLE));
//         vm.prank(mockUser);
//         token.burn(mockUser, 1, 1);
//     }

//     function testURI() public {
//         assertEq(token.uri(1), string.concat(token.tokenURI(), "/1.json"));
//     }

//     function testSetUri() public {
//         token.setURI("0xbeef");
//         assertEq(token.tokenURI(), "0xbeef");
//     }

//     function testCannotSetUriWithoutAdmin() public {
//         vm.expectRevert(revertAccessControl(mockUser, token.DEFAULT_ADMIN_ROLE()));
//         vm.prank(mockUser);
//         token.setURI("0xbeef");
//     }
// }
