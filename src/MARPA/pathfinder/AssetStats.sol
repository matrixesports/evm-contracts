// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

uint256 constant BOMBER_HEALTH = 4;
uint256 constant BOMBER_DAMAGE = 3;
uint256 constant BOMBER_RANGE = 2;
//can only fire once every 3 ticks
uint256 constant BOMBER_FIRE_TICKS = 3;

uint256 constant CASTLE_HEALTH = 10;

///@dev special: all other defences need a generator within 2 blocks of it or else they cannot defend
uint256 constant GENERATOR_HEALTH = 5;
uint256 constant GENERATOR_RANGE = 2;

uint256 constant TURRET_HEALTH = 5;
uint256 constant TURRET_DAMAGE = 1;
uint256 constant TURRET_RANGE = 2;

uint256 constant WALL_HEALTH = 10;

uint256 constant RANGED_HEALTH = 3;
uint256 constant RANGED_DAMAGE = 1;
uint256 constant RANGED_RANGE = 2;
uint256 constant RANGED_MOVE_TICKS = 3;

uint256 constant MELEE_HEALTH = 10;
uint256 constant MELEE_DAMAGE = 2;
uint256 constant MELEE_RANGE = 1;
//1 move per tick
uint256 constant MELEE_MOVE_TICKS = 2;

uint256 constant EXPLOSIVE_HEALTH = 5;
uint256 constant EXPLOSIVE_DAMAGE = 5;
uint256 constant EXPLOSIVE_RANGE = 1;
uint256 constant EXPLOSIVE_MOVE_TICKS = 1;
uint256 constant EXPLOSIVE_FIRE_TICKS = 3;
