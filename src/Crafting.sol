// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./battle-pass/IRewards.sol";
import "solmate/auth/Owned.sol";

/// @dev use when crafting with an inactive recipe
error RecipeNotActive(uint256 recipeId, address user);
/// @dev use when creating a new recipe with incorrect ingredients
error IncorrectRecipeDetails();

/**
 * @dev ingredients for a recipe
 * tokens: list of reward addresses (all ingredients come from Battle Pass contracts) 
 * ids: list of ids
 * qtys: list of qtys
 */
struct Ingredients {
    address[] tokens;
    uint256[] ids;
    uint256[] qtys;
}

/**
 * @title Recipe Contract
 * @author rayquaza7
 * @notice Recipes used for crafting
 * @dev
 * Recipe is just a list of input and output tokens
 * User who has all the required input tokens can 'craft' new items.
 * Ingredients get burn and new items are minted
 */
contract Crafting is Owned {
    /// @dev emitted when new recipe is created
    event NewRecipe(uint256 indexed recipeId, uint256 indexed creatorId);
    /// @dev emitted when item is crafted
    event Crafted(uint256 indexed recipeId, address indexed user);

    /// @dev number of created recipes 
    uint256 public recipeId;
    /// @dev creatorId->list of recipes
    mapping(uint256 => uint256[]) public creatorRecipes;
    /// @dev recipe id->input ingredients
    mapping(uint256 => Ingredients) internal inputIngredients;
    /// @dev recipeId->output ingredients
    mapping(uint256 => Ingredients) internal outputIngredients;
    /// @dev recipeId->active
    mapping(uint256 => bool) public isActive;

    constructor() Owned(msg.sender) {}

    /**
     * @notice creates a new recipe
     * @dev assumes that the ids you are adding are valid based on the spec in BattlePass.sol
     * reverts when: 
     *      ids are invalid
     *      ids.length != qtys.length for both input and output tokens
     * @param input ingredients
     * @param output ingredients
     * @return recipeId
     */
    function addRecipe(
        Ingredients calldata input,
        Ingredients calldata output,
        uint256 creatorId
    ) external onlyOwner returns (uint256) {
        if (
            input.tokens.length == input.ids.length &&
            input.ids.length == input.qtys.length &&
            output.tokens.length == output.ids.length &&
            output.ids.length == output.qtys.length
        ) {
            revert IncorrectRecipeDetails();
        }

        unchecked {
            recipeId++;
        }
        creatorRecipes[creatorId].push(recipeId);
        inputIngredients[recipeId] = input;
        outputIngredients[recipeId] = output;
        isActive[recipeId] = true;
        emit NewRecipe(recipeId, creatorId);
        return recipeId;
    }

    /**
     * @notice crafts new items by recipeId
     * @dev reverts when:
     *      user does not own the input items
     *      recipe is not active
     * @param _recipeId recipeId
     * @param user address to mint output tokens to
     */
    function craft(uint256 _recipeId, address user) external onlyOwner {
        if (!isActive[_recipeId]) revert RecipeNotActive(_recipeId, user);

        Ingredients memory input = inputIngredients[_recipeId];
        Ingredients memory output = outputIngredients[_recipeId];
        for (uint256 x; x < input.tokens.length; x++) {
            IRewards(input.tokens[x]).burn(user, input.ids[x], input.qtys[x]);
        }
        for (uint256 x; x < output.tokens.length; x++) {
            IRewards(output.tokens[x]).mint(user, output.ids[x], output.qtys[x]);
        }
        emit Crafted(_recipeId, user);
    }

    /// @notice toggles a recipe on or off
    function toggleRecipe(uint256 _recipeId, bool toggle) public onlyOwner {
        isActive[_recipeId] = toggle;
    }

    /// @notice gets input ingredients for a recipe id
    function getInputIngredients(uint256 _recipeId) public view returns (Ingredients memory) {
        return inputIngredients[_recipeId];
    }

    /// @notice gets output ingredients for a recipe id
    function getOutputIngredients(uint256 _recipeId) public view returns (Ingredients memory) {
        return outputIngredients[_recipeId];
    }
}
