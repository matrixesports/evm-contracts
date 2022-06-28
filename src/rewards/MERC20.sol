// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../Utils.sol";
import "./interfaces/IMERC20.sol";
import "solmate/tokens/ERC20.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";

/// @dev ERC20 reward with minting access control, extremely basic, customize on top of this
contract MERC20 is ERC20, AccessControl, IMERC20 {
    // minter role to recipe and pass/lootbox ctr
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address passOrLootbox,
        address recipe
    ) ERC20(name, symbol, decimals) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, passOrLootbox);
        _grantRole(MINTER_ROLE, recipe);
    }

    /*//////////////////////////////////////////////////////////////////////
                                MINTING
    //////////////////////////////////////////////////////////////////////*/

    /// @notice edit this contract according to req
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    //will underflow if not owned
    function burn(address from, uint256 amount) public onlyRole(MINTER_ROLE) {
        _burn(from, amount);
    }
}
