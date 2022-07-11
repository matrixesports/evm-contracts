// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC20.sol";

/// @dev used when delagator tries to delegate more than they have or undelegate more than they delegated
error InsufficientBalance(address delegator, uint256 owned, uint256 delegatedAmount);

/// @notice contract for erc20 token specific to the creator with delegation
contract CreatorToken is ERC20, Owned {
    /// @dev addresses that can mint/burn tokens
    /// @dev Pass contract for the creator and msg.sender will be whitelisted
    mapping(address => bool) public whitelist;

    /// @dev delegator->delegatee->amount; track who delegates to whom and how much
    mapping(address => mapping(address => uint256)) public delegatedBy;
    /// @dev track total delegated to an address
    mapping(address => uint256) public delegatedTotal;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address pass
    ) ERC20(_name, _symbol, _decimals) Owned(msg.sender) {
        whitelist[pass] = true;
        whitelist[msg.sender] = true;
    }

    /// @notice toggle true/false addy in whitelist
    function toggleWhitelist(address addy, bool toggle) public onlyOwner {
        whitelist[addy] = toggle;
    }

    /// @notice delegate tokens to delegatee
    /// @param delegator the address delegating tokens
    /// @param delegatee the address tokens are being delegated to
    /// @param amount the amount of tokens to delegate
    function delegate(
        address delegator,
        address delegatee,
        uint256 amount
    ) public onlyOwner {
        uint256 owned = balanceOf[delegator];
        if (owned < amount) revert InsufficientBalance(delegator, owned, amount);
        balanceOf[delegator] -= amount;
        delegatedBy[delegator][delegatee] += amount;
        delegatedTotal[delegatee] += amount;
    }

    /// @notice undeledelegate tokens from delegatee
    /// @param delegator the address that delegated tokens
    /// @param delegatee the address tokens were delegated to
    /// @param amount the amount of tokens to undelegate
    function undelegate(
        address delegator,
        address delegatee,
        uint256 amount
    ) public onlyOwner {
        uint256 amountDelegated = delegatedBy[delegator][delegatee];
        if (amountDelegated < amount) revert InsufficientBalance(delegator, amountDelegated, amount);
        balanceOf[delegator] += amount;
        delegatedBy[delegator][delegatee] -= amount;
        delegatedTotal[delegator] -= amount;
    }

    /// @notice enable mint access
    function mint(address to, uint256 amount) public {
        require(whitelist[msg.sender], "NOT ALLOWED");
        _mint(to, amount);
    }

    /// @notice enable burn access
    function burn(address from, uint256 amount) public {
        require(whitelist[msg.sender], "NOT ALLOWED");
        _burn(from, amount);
    }
}
