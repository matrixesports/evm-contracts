// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice logic file for generator in MTX Game
contract Generator {
    ///@dev special: all other defences need a generator within 2 blocks of it or else they cannot defend
    uint256 public constant GENERATOR_HEALTH = 5;
    uint256 public constant GENERATOR_RANGE = 2;
}
