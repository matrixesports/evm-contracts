// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./CraftingStorage.sol";
import "./UUPSUpgradeable.sol";

interface IRewards {
    function burn(address user, uint256 id, uint256 qty) external;

    function mint(address user, uint256 id, uint256 qty) external;
}

/// @dev used when crafting with an inactive recipe
error RecipeNotActive();

/// @dev used when creating a new recipe with incorrect ingredients
error IncorrectRecipeDetails();

/**
 * @title Craft recipes, make new yummy items
 * @author rayquaza7
 * @notice
 * Recipe is just a list of input and output tokens
 * User who has all the required input tokens can 'craft' new items.
 * Ingredients get burn and new items are minted
 * @dev implements a modified/minimal version of
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.2/contracts/proxy/utils/UUPSUpgradeable.sol
 * Removed inheritance in order to simplify storage layout
 */
contract Crafting is UUPSUpgradeable, CraftingStorage {
    /// @dev emitted when new recipe is created
    event NewRecipe(uint256 indexed recipeId);

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    constructor() {}

    function initialize(address _owner) public {
        require(address(this).code.length == 0, "hehe no.");
        owner = _owner;
    }

    /**
     * @notice creates a new recipe
     * @dev assumes that the ids you are adding are valid based on the spec in BattlePass.sol
     * reverts when:
     * ids.length != qtys.length != battlePasses.length for both input and output tokens
     * @param input ingredients
     * @param output ingredients
     * @return recipeId
     */
    function addRecipe(Ingredients calldata input, Ingredients calldata output) external onlyOwner returns (uint256) {
        if (
            input.battlePasses.length != input.ids.length || input.ids.length != input.qtys.length
                || output.ids.length != output.qtys.length || output.battlePasses.length != output.qtys.length
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
            IRewards(input.battlePasses[x]).burn(user, input.ids[x], input.qtys[x]);
        }
        for (uint256 x; x < output.battlePasses.length; x++) {
            IRewards(output.battlePasses[x]).mint(user, output.ids[x], output.qtys[x]);
        }
    }

    /// @notice gets input ingredients for a recipe id
    function getInputIngredients(uint256 _recipeId) external view returns (Ingredients memory) {
        return inputIngredients[_recipeId];
    }

    /// @notice gets output ingredients for a recipe id
    function getOutputIngredients(uint256 _recipeId) external view returns (Ingredients memory) {
        return outputIngredients[_recipeId];
    }

    /*//////////////////////////////////////////////////////////////////////
                            UTILS
    //////////////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;
    }

    function _msgSender() internal view returns (address sender) {
        if (msg.sender == owner) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function upgradeTo(address newImplementation) external onlyOwner onlyProxy {
        super._upgradeTo(newImplementation);
    }
}
