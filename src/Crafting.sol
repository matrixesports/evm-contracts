// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./battle_pass/IRewards.sol";
import "solmate/auth/Owned.sol";

/// @dev used when trying to craft a recipe thats not active
error RecipeNotActive(uint256 recipeId, address user);
/// @dev used when trying to create recipe with incorrect details
error IncorrectRecipeDetails();

/**
 * @dev ingredients for a recipe
 * tokens: list of addresses to call
 * ids: list of ids
 * qtys: list of qtys
 * For now, we only create recipes based on items we have deployed
 * all items are a part of a creator's Battle Pass contract
 * therefore token addresses will only comprise of Battle Pass addresses for diff contracts
 */
struct Ingredients {
    address[] tokens;
    uint256[] ids;
    uint256[] qtys;
}

/** 
@notice a recipe is just a list of input and output tokens
a user that has all the input tokens required by a recipe can 'craft' new items
for ex: there exists a recipe that takes input token X and gives output token Y
- user wants item Y and has item X
- they 'craft' the recipe, i.e., their X token is burned and Y token is minted to them
*/

contract Recipe is Owned {
    /// @dev emitted when new recipe is created
    event NewRecipe(uint256 indexed recipeId);

    /// @dev current number of recipes created
    uint256 public recipeId;
    /// @dev recipe id->input ingredients
    mapping(uint256 => Ingredients) internal inputIngredients;
    /// @dev recipe id->output ingredients
    mapping(uint256 => Ingredients) internal outputIngredients;
    /// @dev recipe id->active
    mapping(uint256 => bool) public isActive;

    constructor() Owned(msg.sender) {}

    /**
     * @notice create a new recipe
     * @dev assumes that the ids you are adding are valid based on the spec in BattlePass.sol
     * assume person creating the recipe knows what they are doing
     * will revert if length of ids is not equal to length of ids and tokens
     * @param input ingredients
     * @param output ingredients
     * @return recipe id
     */
    function addRecipe(Ingredients calldata input, Ingredients calldata output) external onlyOwner returns (uint256) {
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
        inputIngredients[recipeId] = input;
        outputIngredients[recipeId] = output;
        isActive[recipeId] = true;
        emit NewRecipe(recipeId);
        return recipeId;
    }

    /**
     * @notice craft new items based on given recipe id
     * @dev revert if user does not own input items
     * revert if recipe is not active
     * @param _recipeId given recipe id
     * @param user address of user
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
    }

    /// @notice toggle recipe on or off
    function toggleRecipe(uint256 _recipeId, bool toggle) public onlyOwner {
        isActive[_recipeId] = toggle;
    }

    /// @notice get input ingredients for a recipe id
    function getInputIngredients(uint256 _recipeId) public view returns (Ingredients memory) {
        return inputIngredients[_recipeId];
    }

    /// @notice get output ingredients for a recipe id
    function getOutputIngredients(uint256 _recipeId) public view returns (Ingredients memory) {
        return outputIngredients[_recipeId];
    }
}
