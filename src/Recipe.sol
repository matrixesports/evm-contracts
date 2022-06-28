// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Utils.sol";
import "./rewards/MERC1155.sol";
import "solmate/utils/ReentrancyGuard.sol";

error RecipeNotActive(uint256 recipeId, address user);

struct Ingredients {
    ERC721Reward[] erc721s;
    ERC1155Reward[] erc1155s;
}

/** 
@notice a recipe is just a list of input and output tokens
a user that has all the input tokens required by a recipe can 'craft' new items
for ex: there exists a recipe that takes input token X and gives output token Y
- user wants item Y and has item X
- they 'craft' the recipe, i.e., their X token is burned and Y token is minted to them

You can also specify multiple qtys, ids of tokens
premium passes, lootbox,redeemable items, and recipe token itself can be in a recipe

Recipe is an MERC1155, so if u want to give someone the right to craft an item, right to create a recipe etc, you'll have to mint a recipe token to them
*/

// pass needs to be given minter role manually
contract Recipe is ReentrancyGuard, MERC1155, Utils {
    event Crafted(address indexed user, uint256 indexed recipeId);
    event NewRecipe(address indexed admin, uint256 recipeId);

    //current number of recipes created
    uint256 public recipeId;
    //since there is no primitve var, the getter will have nothing to return
    //but a custom defined getter says explicityly what to return, idk why the custom one works tho
    mapping(uint256 => Ingredients) internal inputIngredients;
    mapping(uint256 => Ingredients) internal outputIngredients;
    mapping(uint256 => bool) public isActive;

    ///@dev give minter role to this address
    ///cant give pass minter role here since one has to be deployed first
    constructor(string memory uri) MERC1155(uri, address(this), address(this)) {}

    function addRecipe(Ingredients calldata input, Ingredients calldata output)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256)
    {
        unchecked {
            recipeId++;
        }

        inputIngredients[recipeId] = input;
        outputIngredients[recipeId] = output;
        isActive[recipeId] = true;
        for (uint256 x; x < output.erc721s.length; x++) {
            deposit(output.erc721s[x].token);
        }
        for (uint256 x; x < output.erc1155s.length; x++) {
            deposit(output.erc1155s[x].token);
        }
        emit NewRecipe(_msgSender(), recipeId);
        return recipeId;
    }

    ///@dev revert if recipe is not active
    function craft(uint256 _recipeId) external nonReentrant {
        if (!isActive[_recipeId]) revert RecipeNotActive(_recipeId, _msgSender());
        burnIngredients(inputIngredients[_recipeId]);
        Ingredients memory output = outputIngredients[_recipeId];
        for (uint256 x; x < output.erc721s.length; x++) {
            withdrawERC721(output.erc721s[x], _msgSender());
        }
        for (uint256 x; x < output.erc1155s.length; x++) {
            withdrawERC1155(output.erc1155s[x], _msgSender());
        }
        emit Crafted(_msgSender(), _recipeId);
    }

    function toggleRecipe(uint256 _recipeId, bool toggle) public onlyRole(DEFAULT_ADMIN_ROLE) {
        isActive[_recipeId] = toggle;
    }

    function burnIngredients(Ingredients memory input) private {
        for (uint256 x; x < input.erc721s.length; x++) {
            IMERC721(input.erc721s[x].token).burn(_msgSender(), input.erc721s[x].id);
        }
        for (uint256 x; x < input.erc1155s.length; x++) {
            IMERC1155(input.erc1155s[x].token).burn(_msgSender(), input.erc1155s[x].id, input.erc1155s[x].qty);
        }
    }

    function getInputIngredients(uint256 _recipeId) public view returns (Ingredients memory) {
        return inputIngredients[_recipeId];
    }

    function getOutputIngredients(uint256 _recipeId) public view returns (Ingredients memory) {
        return outputIngredients[_recipeId];
    }
}
