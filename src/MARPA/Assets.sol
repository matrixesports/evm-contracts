// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*//////////////////////////////////////////////////////////////////////
                                DEFENDERS
//////////////////////////////////////////////////////////////////////*/

///@dev ID 0 is special, cannot be minted; 1-10 reserved for defensive units

///@dev special: static, in middle, if health == 0 then attacking party wins
uint256 constant castleHealth = 10;
uint256 constant castleId = 0;

///@dev special:
uint256 constant turretHealth = 5;
uint256 constant turretDamage = 1;
uint256 constant turretRange = 2;
uint256 constant turretId = 1;

///@dev special: can only fire once every 3 ticks and does splash damage in its range
uint256 constant bomberHealth = 4;
uint256 constant bomberDamage = 3;
uint256 constant bomberRange = 2;
//can only fire once every 3 ticks
uint256 constant bomberFireTicks = 3;
uint256 constant bomberId = 2;

///@dev special: all other defences need a generator within 2 blocks of it or else they cannot defend
uint256 constant generatorHealth = 5;
uint256 constant generatorRange = 2;
uint256 constant generatorId = 3;

///@dev special:
uint256 constant wallHealth = 10;
uint256 constant wallId = 4;

/*//////////////////////////////////////////////////////////////////////
                                ATTACKERS
//////////////////////////////////////////////////////////////////////*/

///@dev 11-20 reserved for attacking units

///@dev special:
uint256 constant meleeHealth = 10;
uint256 constant meleeDamage = 2;
uint256 constant meleeRange = 1;
//1 move per tick
uint256 constant meleeMoveTicks = 2;
uint256 constant meleeId = 11;

///@dev special:
uint256 constant rangedHealth = 3;
uint256 constant rangedDamage = 1;
uint256 constant rangedRange = 2;
uint256 constant rangedMoveTicks = 3;
uint256 constant rangedId = 12;

///@dev special: health goes to 0 upon first attack
uint256 constant explosiveHealth = 5;
uint256 constant explosiveDamage = 5;
uint256 constant explosiveRange = 1;
uint256 constant explosiveMoveTicks = 1;
uint256 constant explosiveFireTicks = 3;
uint256 constant explosiveId = 13;

/*//////////////////////////////////////////////////////////////////////
                            15x15 GRID
//////////////////////////////////////////////////////////////////////*/
uint256 constant X = 14;
uint256 constant Y = 14;

/// @dev health determines if slot is empty or not
struct Asset {
    address owner;
    uint256 health;
    uint256 id;
}
