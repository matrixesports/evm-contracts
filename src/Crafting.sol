// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "solmate/auth/Owned.sol";
import "openzeppelin-contracts/contracts/metatx/ERC2771Context.sol";

interface IRewards {
    function burn(address user, uint256 id, uint256 qty) external;

    function mint(address user, uint256 id, uint256 qty) external;
}

/// @dev used when crafting with an inactive recipe
error RecipeNotActive();

/// @dev used when creating a new recipe with incorrect ingredients
error IncorrectRecipeDetails();

/**
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

/**
 * @title Craft recipes, make new yummy items
 * @author rayquaza7
 * @notice
 * Recipe is just a list of input and output tokens
 * User who has all the required input tokens can 'craft' new items.
 * Ingredients get burn and new items are minted
 */
contract Crafting is Owned, ERC2771Context {
    /// @dev emitted when new recipe is created
    event NewRecipe(uint256 indexed recipeId);

    /// @dev number of created recipes
    uint256 public recipeId;

    /// @dev recipe id->input ingredients
    mapping(uint256 => Ingredients) internal inputIngredients;

    /// @dev recipeId->output ingredients
    mapping(uint256 => Ingredients) internal outputIngredients;

    /// @dev recipeId->active?
    mapping(uint256 => bool) public isActive;

    constructor() Owned(msg.sender) ERC2771Context(msg.sender) {}

    /**
     * @notice creates a new recipe
     * @dev assumes that the ids you are adding are valid based on the spec in BattlePass.sol
     * reverts when:
     * ids.length != qtys.length != battlePasses.length for both input and output tokens
     * @param input ingredients
     * @param output ingredients
     * @return recipeId
     */
    function addRecipe(Ingredients calldata input, Ingredients calldata output)
        external
        onlyOwner
        returns (uint256)
    {
        if (
            input.battlePasses.length != input.ids.length
                || input.ids.length != input.qtys.length
                || output.ids.length != output.qtys.length
                || output.battlePasses.length != output.qtys.length
        ) {
            revert IncorrectRecipeDetails();
        }

        unchecked {
            recipeId++;
        }
        inputIngredients[recipeId] = input;
        outputIngredients[recipeId] = output;
        isActive[recipeId] = true;
        emit NewRecipe(recipeId);
        return recipeId;
    }

    /// @notice toggles a recipe on or off
    function toggleRecipe(uint256 _recipeId, bool toggle) external onlyOwner {
        isActive[_recipeId] = toggle;
    }

    /**
     * @notice crafts new items by recipeId
     * @dev reverts when:
     * user does not own the input items
     * recipe is not active
     * @param _recipeId recipeId
     */
    function craft(uint256 _recipeId) external {
        if (!isActive[_recipeId]) {
            revert RecipeNotActive();
        }

        address user = _msgSender();
        Ingredients memory input = inputIngredients[_recipeId];
        Ingredients memory output = outputIngredients[_recipeId];
        for (uint256 x; x < input.battlePasses.length; x++) {
            IRewards(input.battlePasses[x]).burn(
                user, input.ids[x], input.qtys[x]
            );
        }
        for (uint256 x; x < output.battlePasses.length; x++) {
            IRewards(output.battlePasses[x]).mint(
                user, output.ids[x], output.qtys[x]
            );
        }
    }

    /// @notice gets input ingredients for a recipe id
    function getInputIngredients(uint256 _recipeId)
        external
        view
        returns (Ingredients memory)
    {
        return inputIngredients[_recipeId];
    }

    /// @notice gets output ingredients for a recipe id
    function getOutputIngredients(uint256 _recipeId)
        external
        view
        returns (Ingredients memory)
    {
        return outputIngredients[_recipeId];
    }
}
