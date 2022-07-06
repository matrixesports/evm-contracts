// // SPDX-License-Identifier: MIT
// pragma solidity >=0.8.0;

// import "./Helper.sol";
// import "../src/Recipe.sol";

// contract RecipeTest is Helper {
//     uint256 public constant ingredientCount = 3;
//     Recipe public recipe;
//     uint256 public recipeId;
//     Ingredients internal input;
//     Ingredients internal output;

//     event Crafted(address indexed user, uint256 indexed recipeId);
//     event NewRecipe(address indexed admin, uint256 recipeId);

//     function setUp() public {
//         recipe = new Recipe(uri);
//         for (uint256 x; x < ingredientCount; x++) {
//             input.erc1155s.push(newERC1155Reward(mockPass, address(recipe), x + 1, x + 10));
//             input.erc721s.push(newERC721Reward(mockPass, address(recipe)));
//             output.erc1155s.push(newERC1155Reward(mockPass, address(recipe), x + 1, x + 10));
//             output.erc721s.push(newERC721Reward(mockPass, address(recipe)));
//         }
//         recipeId = recipe.addRecipe(input, output);
//     }

//     function testConstructor() public {
//         assertEq(recipe.hasRole(recipe.DEFAULT_ADMIN_ROLE(), address(this)), true);
//         assertEq(recipe.hasRole(MINTER_ROLE, address(this)), true);
//         assertEq(recipe.hasRole(MINTER_ROLE, address(recipe)), true);
//         assertEq(recipe.tokenURI(), uri);
//     }

//     function testAddRecipe() public {
//         vm.expectEmit(true, false, false, true);
//         emit NewRecipe(address(this), 2);
//         recipeId = recipe.addRecipe(input, output);

//         assertEq(recipeId, recipe.recipeId());
//         Ingredients memory _input = recipe.getInputIngredients(recipeId);
//         for (uint256 x; x < _input.erc721s.length; x++) {
//             assert721Reward(_input.erc721s[x], input.erc721s[x]);
//         }
//         for (uint256 x; x < _input.erc1155s.length; x++) {
//             assert1155Reward(_input.erc1155s[x], input.erc1155s[x]);
//         }

//         Ingredients memory _output = recipe.getOutputIngredients(recipeId);
//         for (uint256 x; x < _output.erc721s.length; x++) {
//             assert721Reward(_output.erc721s[x], output.erc721s[x]);
//         }
//         for (uint256 x; x < _output.erc1155s.length; x++) {
//             assert1155Reward(_output.erc1155s[x], output.erc1155s[x]);
//         }
//         assertTrue(recipe.isActive(recipeId));
//     }

//     function testCannotAddRecipeNoAdmin() public {
//         vm.expectRevert(revertAccessControl(mockUser, recipe.DEFAULT_ADMIN_ROLE()));
//         vm.prank(mockUser);
//         recipe.addRecipe(input, output);
//     }

//     function testCraft() public {
//         vm.expectEmit(true, false, false, true);
//         emit Crafted(mockUser, 2);
//         recipeId = recipe.addRecipe(input, output);
//         for (uint256 x; x < ingredientCount; x++) {
//             MERC1155(input.erc1155s[x].token).mint(
//                 mockUser,
//                 input.erc1155s[x].id,
//                 input.erc1155s[x].qty,
//                 ""
//             );
//             MERC721(input.erc721s[x].token).mint(mockUser);
//         }
//         vm.prank(mockUser);
//         recipe.craft(recipeId);
//         //check balances
//         for (uint256 x; x < ingredientCount; x++) {
//             assertEq(checkERC1155Balance(input.erc1155s[x], mockUser), 0);
//             assertEq(checkERC1155Balance(output.erc1155s[x], mockUser), output.erc1155s[x].qty);
//             assertEq(checkERC721Balance(input.erc721s[x], mockUser), 0);
//             assertEq(checkERC721Balance(output.erc721s[x], mockUser), 1);
//         }
//     }

//     function testCannotCraftNotActive() public {
//         recipe.toggleRecipe(recipeId, false);
//         vm.expectRevert(abi.encodeWithSelector(RecipeNotActive.selector, recipeId, mockUser));
//         vm.prank(mockUser);
//         recipe.craft(recipeId);
//     }

//     function testToggleRecipe() public {
//         recipe.toggleRecipe(recipeId, false);
//         bool active = recipe.isActive(recipeId);
//         assertFalse(active);
//     }

//     function testCannotToggleRecipeWithoutAdmin() public {
//         vm.expectRevert(revertAccessControl(mockUser, recipe.DEFAULT_ADMIN_ROLE()));
//         vm.prank(mockUser);
//         recipe.toggleRecipe(recipeId, false);
//         // }
//     }
// }
