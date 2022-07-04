// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./rewards/MERC20.sol";

/**
 * @notice handles deploying new token and delegation of tokens
 */
contract Creator is MERC20 {
    //delegator->delegatee->amount
    mapping(address => mapping(address => uint256)) public delegatedBy;
    mapping(address => uint256) public delegatedTotal;

    error InsufficientBalance(address delegator, uint256 owned, uint256 delegatedAmount);
    event TokensDelegated();

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address passOrLootbox,
        address recipe
    ) MERC20(name, symbol, decimals, passOrLootbox, recipe) {}

    function delegate(
        address delegator,
        address delegatee,
        uint256 amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 owned = balanceOf[delegator];
        if (owned < amount) revert InsufficientBalance(delegator, owned, amount);
        balanceOf[delegator] -= amount;
        delegatedBy[delegator][delegatee] += amount;
        delegatedTotal[delegatee] += amount;
    }

    function undelegate(
        address delegator,
        address delegatee,
        uint256 amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amountDelegated = delegatedBy[delegator][delegatee];
        if (amountDelegated < amount) revert InsufficientBalance(delegator, amountDelegated, amount);
        balanceOf[delegator] += amount;
        delegatedBy[delegator][delegatee] -= amount;
        delegatedTotal[delegatee] -= amount;
    }
}
