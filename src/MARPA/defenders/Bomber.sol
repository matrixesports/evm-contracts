// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice logic file for bomber in MTX Game
contract Bomber {
    uint256 public constant BOMBER_HEALTH = 4;
    uint256 public constant BOMBER_DAMAGE = 3;
    uint256 public constant BOMBER_RANGE = 2;
    //can only fire once every 3 ticks
    uint256 public constant BOMBER_FIRE_TICKS = 3;
}
