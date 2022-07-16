// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC20.sol";

/// @dev use when a delagator tries to delegate more than they own
error InsufficientBalance(address delegator, uint256 owned, uint256 delegatedAmount);

/**
 * @title Creator Token contract
 * @author rayquaza7
 * @notice ERC20 creator specific token with delegation capabilities 
 * @dev
 */
contract CreatorToken is ERC20, Owned {
    /// @notice addresses that can mint/burn tokens
    /// @dev whitelists Battle Pass contract for the creator and msg.sender
    mapping(address => bool) public whitelist;

    /// @notice tracks who delegates to whom and how much
    /// @dev delegator->delegatee->amount
    mapping(address => mapping(address => uint256)) public delegatedBy;
    /// @dev tracks the total delegated amount to an address
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

    /// @notice toggles { true, false} for an address in the whitelist
    function toggleWhitelist(address addy, bool toggle) public onlyOwner {
        whitelist[addy] = toggle;
    }

    /// @notice delegates tokens to a delegatee
    /// @param delegator the address delegating the tokens
    /// @param delegatee the address receiving the delegated tokens
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

    /// @notice undelegates the tokens from a delegatee
    /// @param delegator the address who delegated tokens
    /// @param delegatee the address who recevied the delegated tokens
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

    /// @notice enables mint access
    function mint(address to, uint256 amount) public {
        require(whitelist[msg.sender], "NOT ALLOWED");
        _mint(to, amount);
    }

    /// @notice enables burn access
    function burn(address from, uint256 amount) public {
        require(whitelist[msg.sender], "NOT ALLOWED");
        _burn(from, amount);
    }
}
