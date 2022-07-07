// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice logic file for melee in MTX Game
contract Bomber {
    uint256 public constant MELEE_HEALTH = 10;
    uint256 public constant MELEE_DAMAGE = 2;
    uint256 public constant MELEE_RANGE = 1;
    //1 move per tick
    uint256 public constant MELEE_MOVE_TICKS = 2;
}
