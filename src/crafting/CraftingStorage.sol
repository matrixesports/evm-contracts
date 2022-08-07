// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @notice DO NOT CHANGE
 * @dev ingredients for a recipe
 * battlePasses: list of battle pass addresses (all ingredients come from Battle Pass contracts)
 * ids: list of ids
 * qtys: list of qtys
 */
struct Ingredients {
    address[] battlePasses;
    uint256[] ids;
    uint256[] qtys;
}

bytes32 constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

/**
 * @notice storage slots for Crafting
 * @dev IMPORTANT: DO NOT CHANGE ORDER
 * CHANGING ORDER FOR AN UPGRADE WILL BREAK STORAGE LAYOUT
 * IF YOU WANT TO INTRODUCE NEW SLOTS MAKE SURE YOU DO IT
 * AFTER THE ALREADY DEFINED ONES.
 */
abstract contract CraftingStorage {
    address public owner;
    /// @dev number of created recipes
    uint256 public recipeId;

    /// @dev recipe id->input ingredients
    mapping(uint256 => Ingredients) internal inputIngredients;

    /// @dev recipeId->output ingredients
    mapping(uint256 => Ingredients) internal outputIngredients;

    /// @dev recipeId->active?
    mapping(uint256 => bool) public isActive;
}
