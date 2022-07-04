// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./rewards/interfaces/IMERC20.sol";
import "./rewards/interfaces/IMERC721.sol";
import "./rewards/interfaces/IMERC1155.sol";

/// @dev constants used throughout our contracts
bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
bytes32 constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

/// @dev used when token to be added isnt given minter role
/// @param minter address of contract that needs minter role
/// @param token address of token that is to be added
error TokenNotGivenMinterRole(address minter, address token);

/**
 * @dev
 * token: address of MERC20
 * qty: how much to give out
 */
struct ERC20Reward {
    address token;
    uint256 qty;
}

/**
 * @dev
 * token: address of MERC721
 * id: what id to mint,
 * if using autoid, then id will be passed to mint function but ignored
 * else id will be minted, however, only the first person to mint it will be able to redeem it
 * therefore, we will always use auto id
 * However, this becomes imp for crafting recipes u might want to burn a specific id to create one off recipes
 */
struct ERC721Reward {
    address token;
    uint256 id;
}

/**
 * @dev
 * token: address of MERC1155
 * qty: how much to give
 * id: what id to give
 */
struct ERC1155Reward {
    address token;
    uint256 id;
    uint256 qty;
}

/// @dev helpers for deposits and withdrawls
abstract contract Utils {
    function deposit(address token) internal view {
        if (!IAccessControl(token).hasRole(MINTER_ROLE, address(this))) {
            revert TokenNotGivenMinterRole(address(this), token);
        }
    }

    function withdrawERC20(ERC20Reward memory reward, address user) internal {
        IMERC20(reward.token).mint(user, reward.qty);
    }

    function withdrawERC721(ERC721Reward memory reward, address user) internal {
        IMERC721(reward.token).mint(user);
    }

    function withdrawERC1155(ERC1155Reward memory reward, address user) internal {
        IMERC1155(reward.token).mint(user, reward.id, reward.qty, "");
    }
}
