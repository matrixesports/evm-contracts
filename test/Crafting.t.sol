// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../src/Crafting.sol";
import "../src/BattlePass.sol";
import "../src/uups/ERC1967Proxy.sol";
import "solmate/utils/Bytes32AddressLib.sol";

contract CraftingProxyTest is Test {
    using Bytes32AddressLib for address;
    using Bytes32AddressLib for bytes32;

    Crafting crafting;
    ERC1967Proxy proxy;

    event Upgraded(address indexed implementation);

    function setUp() public {
        crafting = new Crafting();
        bytes memory data = abi.encodeWithSelector(crafting.initialize.selector, address(this));
        proxy = new ERC1967Proxy(address(crafting),data);
    }

    function testInitializer() public {
        bytes32 impl = vm.load(address(proxy), _IMPLEMENTATION_SLOT);
        assertEq(impl.fromLast20Bytes(), address(crafting));
        bytes32 owner = vm.load(address(proxy), 0);
        assertEq(address(this), owner.fromLast20Bytes());
    }
}
// address mockUser = address(1);
//     uint256 inputLength = 3;
//     Ingredients input;
//     Ingredients output;
// function setUp() public {
//         crafting = new Crafting();
//         proxy = new ERC1967Proxy(address(crafting));
//         for (uint256 x = 0; x < inputLength; x++) {
//             BattlePass bp = new BattlePass("", address(proxy));
//             input.battlePasses.push(address(bp));
//             input.ids.push(x + 1);
//             input.qtys.push(x + 1);
//         }
//         BattlePass bp = new BattlePass("", address(proxy));
//         output.battlePasses.push(address(bp));
//         output.ids.push(10);
//         output.qtys.push(1);
//         output.battlePasses.push(address(bp));
//         output.ids.push(11);
//         output.qtys.push(1);
//     }
// function testRevertAddRecipeNonOwner() public {
//     vm.startPrank(mockUser);
//     vm.expectRevert(abi.encodePacked("UNAUTHORIZED"));
//     crafting.addRecipe(input, output);
// }

// function testRevertAddRecipeIncorrectDetails() public {
//     vm.expectRevert(IncorrectRecipeDetails.selector);
//     input.qtys.push(1);
//     crafting.addRecipe(input, output);

//     vm.expectRevert(IncorrectRecipeDetails.selector);
//     input.ids.push(1);
//     crafting.addRecipe(input, output);

//     input.battlePasses.push(address(2));
//     crafting.addRecipe(input, output);

//     vm.expectRevert(IncorrectRecipeDetails.selector);
//     output.ids.push(1);
//     crafting.addRecipe(input, output);

//     vm.expectRevert(IncorrectRecipeDetails.selector);
//     output.qtys.push(1);
//     crafting.addRecipe(input, output);

//     output.battlePasses.push(address(2));
//     crafting.addRecipe(input, output);
// }

// function testAddRecipe() public {
//     uint256 oldRecipeId = crafting.recipeId();
//     uint256 recipeId = crafting.addRecipe(input, output);
//     assertEq(oldRecipeId + 1, recipeId);
//     assertEq(crafting.recipeId(), recipeId);
//     Ingredients memory _input = crafting.getInputIngredients(recipeId);

//     for (uint256 x; x < _input.battlePasses.length; x++) {
//         assertEq(input.battlePasses[x], _input.battlePasses[x]);
//         assertEq(input.ids[x], _input.ids[x]);
//         assertEq(input.qtys[x], _input.qtys[x]);
//     }

//     Ingredients memory _output = crafting.getOutputIngredients(recipeId);
//     for (uint256 x; x < _output.battlePasses.length; x++) {
//         assertEq(output.battlePasses[x], _output.battlePasses[x]);
//         assertEq(output.ids[x], _output.ids[x]);
//         assertEq(output.qtys[x], _output.qtys[x]);
//     }

//     assertTrue(crafting.isActive(recipeId));
// }

// function testRevertToggleRecipeNonOwner() public {
//     vm.startPrank(mockUser);
//     vm.expectRevert(abi.encodePacked("UNAUTHORIZED"));
//     crafting.toggleRecipe(1, true);
// }

// function testToggleRecipe() public {
//     assertFalse(crafting.isActive(1));
//     crafting.toggleRecipe(1, true);
//     assertTrue(crafting.isActive(1));
//     crafting.toggleRecipe(1, false);
//     assertFalse(crafting.isActive(1));
// }

// function testRevertCraftNotActive() public {
//     crafting.addRecipe(input, output);
//     crafting.toggleRecipe(1, false);
//     vm.expectRevert(RecipeNotActive.selector);
//     crafting.craft(1);
// }

// function testCraft() public {
//     uint256 recipeId = crafting.addRecipe(input, output);
//     for (uint256 x; x < input.battlePasses.length; x++) {
//         BattlePass(input.battlePasses[x]).mint(mockUser, input.ids[x], input.qtys[x]);
//     }

//     vm.prank(mockUser);
//     crafting.craft(recipeId);

//     for (uint256 x; x < input.battlePasses.length; x++) {
//         assertEq(BattlePass(input.battlePasses[x]).balanceOf(mockUser, input.ids[x]), 0);
//     }

//     for (uint256 x; x < output.battlePasses.length; x++) {
//         assertEq(BattlePass(output.battlePasses[x]).balanceOf(mockUser, output.ids[x]), output.qtys[x]);
//     }
// }

// // will send user address in calldata from admin
// function testCraftWithMetaTx() public {
//     uint256 recipeId = crafting.addRecipe(input, output);
//     for (uint256 x; x < input.battlePasses.length; x++) {
//         BattlePass(input.battlePasses[x]).mint(mockUser, input.ids[x], input.qtys[x]);
//     }
//     (bool success,) =
//         address(crafting).call(abi.encodePacked(abi.encodeWithSelector(crafting.craft.selector, recipeId), mockUser));
//     assertTrue(success);
//     for (uint256 x; x < input.battlePasses.length; x++) {
//         assertEq(BattlePass(input.battlePasses[x]).balanceOf(mockUser, input.ids[x]), 0);
//     }
//     for (uint256 x; x < output.battlePasses.length; x++) {
//         assertEq(BattlePass(output.battlePasses[x]).balanceOf(mockUser, output.ids[x]), output.qtys[x]);
//     }
// }
