// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./EternalGlory.sol";
import "./AssetStats.sol";
import "../battle_pass/IRewards.sol";
import {InvalidId} from "../battle_pass/Rewards.sol";
import "solmate/auth/Owned.sol";

/// @dev track info on asset placed on a grid location
/// health determines if slot is empty or not
struct Asset {
    address owner;
    uint256 health;
    uint256 id;
}

/**
 * @title MTX Game
 * @notice logic and state for the MTX Game
 * @author rayquaza7
 * @dev each community gets one copy of this contract
 * players win defenders by completing quests for their creator in the Battle Pass
 * they talk among themelves on discord, figure out where to put their defenders
 * they can place their defenders on the game map until the deadline
 * the goal is to protect their castle in the middle
 * after the deadline, placing/unplacing is freezed
 * MTX has attackers that it places randomly before the deadline as well
 * at the deadline the attack begins, all actions happen automatically afterwards
 * the attackers move on their own and the defenders defend themselved accordingly
 * the game ends if the castle health == 0 or all attackers die
 * if the community loses then they get a soul bound token indicating a loss
 * if they win they get a win SBT and their creator may get something 👀
 */
contract Engine is EternalGlory, Owned {
    /// @dev emitted when asset dies
    event AssetDead(uint256 indexed _x, uint256 indexed _y);
    /// @dev emitted when asset inflicts damage
    event UpdateHealth(uint256 indexed _x, uint256 indexed _y, uint256 _xDamaged, uint256 _yDamaged);
    /// @dev emitted when game's over; winner is true if the defenders won
    event GameOver(bool indexed winner);
    /// @dev emiited when an attacker moves
    event AttackerMove(uint256 _x, uint256 _y, uint256 newX, uint256 newY);

    /// @dev grid size of the board
    uint256 public constant X = 14;
    uint256 public constant Y = 14;
    /// @dev castle is put in the middle
    uint256 public constant CASTLE_X = (X + 1) / 2;
    uint256 public constant CASTLE_Y = (Y + 1) / 2;

    uint256 public constant DEFENDER_STARTING_ID = 20_100;
    uint256 public constant CASTLE_ID = 20_100;
    uint256 public constant TURRET_ID = 20_101;
    uint256 public constant WALL_ID = 20_102;
    uint256 public constant GENERATOR_ID = 20_103;

    uint256 public constant ATTACKER_STARTING_ID = 20_200;
    uint256 public constant BOMBER_ID = 20_200;
    uint256 public constant RANGED_ID = 20_201;
    uint256 public constant MELEE_ID = 20_202;
    uint256 public constant EXPLOSIVE_ID = 20_203;

    /// @dev uses for actions that can only be undertaken when game is either ongoing or stoppped
    /// @param _start true if need game to have already started, false otherwise
    modifier gameStatus(bool _start) {
        require(_start == start, "Cannot perform action in this game state");
        _;
    }

    /// @dev add castle in the middle
    /// @param uri SBT uri
    constructor(string memory uri) EternalGlory(uri) Owned(msg.sender) {
        asset[CASTLE_X][CASTLE_Y] = Asset(address(this), CASTLE_HEALTH, CASTLE_ID);
    }

    /*//////////////////////////////////////////////////////////////////////
                                ADMIN 
    //////////////////////////////////////////////////////////////////////*/

    /// @dev battle pass address associated with this board
    address public battlePass;
    /// @dev true if game has started
    bool public start;

    /// @notice toggle game start/stop
    /// @dev only admin can toggle game
    /// @param toggle set to true to start game, false otherwise
    function toggleGame(bool toggle) external onlyOwner {
        start = toggle;
    }

    /// @notice set pass address
    function setPass(address _battlePass) external onlyOwner gameStatus(false) {
        battlePass = _battlePass;
    }

    /*//////////////////////////////////////////////////////////////////////
                                UTILS
    //////////////////////////////////////////////////////////////////////*/

    /**
     * @notice check if a given asset is a defense unit or an attacking unit
     * @param assetId asset id of asset to check
     * @return true if defender, false if attacker
     */
    function checkType(uint256 assetId) public pure returns (bool) {
        if (assetId >= DEFENDER_STARTING_ID && assetId < ATTACKER_STARTING_ID) {
            return true;
        } else if (assetId >= ATTACKER_STARTING_ID) {
            return false;
        } else {
            revert InvalidId(assetId);
        }
    }

    /**
     * @notice check if a given asset can be placed at _x,_y acc to rules
     * @dev attacking units can only be placed at the boundary of the grid
     * similarly defender units cannot be placed at the boundary
     * revert if rules are not followed
     * @param _x x coordinate to place it in
     * @param _y y coordinate to place it in
     * @param isDefender true if defender is being placed
     */
    function checkPlaceConditions(
        uint256 _x,
        uint256 _y,
        bool isDefender
    ) public view {
        require(asset[_x][_y].health == 0, "space occupied");
        bool onBoundary = _x == 0 || _y == 0 || _x == X || _y == Y;
        if (isDefender) {
            require(!onBoundary, "invalid defender location");
        } else {
            require(onBoundary, "invalid attacker location");
        }
    }

    /**
     * @notice return health for asset id
     * @dev revert if id is invalid
     * @param assetId asset id of asset to check
     * @return health of asset
     */
    function getHealthForAsset(uint256 assetId) public pure returns (uint256 health) {
        if (assetId == TURRET_ID) {
            health = TURRET_HEALTH;
        } else if (assetId == BOMBER_ID) {
            health = BOMBER_HEALTH;
        } else if (assetId == GENERATOR_ID) {
            health = GENERATOR_HEALTH;
        } else if (assetId == WALL_ID) {
            health = WALL_HEALTH;
        } else if (assetId == MELEE_ID) {
            health = MELEE_HEALTH;
        } else if (assetId == RANGED_ID) {
            health = RANGED_HEALTH;
        } else if (assetId == EXPLOSIVE_ID) {
            health = EXPLOSIVE_HEALTH;
        } else {
            revert InvalidId(assetId);
        }
    }

    /// @notice adjust x y coordinates according to board size and its range
    function adjustInRange(
        uint256 _x,
        uint256 _y,
        uint256 range
    ) public pure returns (uint256 xRange, uint256 yRange) {
        xRange = _x + range;
        if (xRange > X) xRange = X;
        yRange = _y + range;
        if (yRange > Y) yRange = Y;
    }

    /**
     * @notice check if there is a generator around _x,_y
     * @dev adjust for board size
     * @return yes true if there is a generator
     */
    function isGeneratorAround(uint256 _x, uint256 _y) public view returns (bool yes) {
        (uint256 xRange, uint256 yRange) = adjustInRange(_x, _y, GENERATOR_RANGE);

        for (uint256 a = _x; a <= xRange; a++) {
            for (uint256 b = _y; b <= yRange; b++) {
                Asset memory _asset = asset[a][b];
                if (_asset.id == GENERATOR_ID) yes = true;
            }
        }
    }

    /**
     * @notice find first enemy within range for asset at _x,_y
     * @dev skip empty slots, find attackers for defenders and vice versa
     * adjust for board size
     * @param _x x coordinate of asset
     * @param _y y coordinate of asset
     * @param range range of asset
     * @param isDefender true if defender
     * @return _xEnemy x coordinate of enemy
     * @return _yEnemy y coordinate of enemy
     * @return exists true if exists, if we didnt have this then
     * since the default value of uint is 0, the coordinates would have been
     * 0,0 which is a valid location on the board
     */
    function find(
        uint256 _x,
        uint256 _y,
        uint256 range,
        bool isDefender
    )
        public
        view
        returns (
            uint256 _xEnemy,
            uint256 _yEnemy,
            bool exists
        )
    {
        (uint256 xRange, uint256 yRange) = adjustInRange(_x, _y, range);

        for (uint256 a = _x; a <= xRange; a++) {
            for (uint256 b = _y; b <= yRange; b++) {
                Asset memory _asset = asset[a][b];
                if (!(isDefender && checkType(_asset.id))) {
                    _xEnemy = a;
                    _yEnemy = b;
                    exists = true;
                    break;
                }
            }
        }
    }

    /**
     * @notice find all enemies within range for asset at _x,_y
     * @dev skip empty slots, find attackers for defenders and vice versa
     * adjust for board size
     * @param _x x coordinate of asset
     * @param _y y coordinate of asset
     * @param range range of asset
     * @param isDefender true if defender
     * @return _xEnemy x coordinate of enemies
     * @return _yEnemy y coordinate of enemies
     * @return exists true if exists, if we didnt have this then
     * since the default value of uint is 0, the coordinates would have been
     * 0,0 which is a valid location on the board
     */
    function findAll(
        uint256 _x,
        uint256 _y,
        uint256 range,
        bool isDefender
    )
        public
        view
        returns (
            uint256[] memory _xEnemy,
            uint256[] memory _yEnemy,
            bool exists
        )
    {
        (uint256 xRange, uint256 yRange) = adjustInRange(_x, _y, range);
        // max added elemets will always be xRange * yRange -1 since this asset
        // wont be added to it.
        _xEnemy = new uint256[](xRange * yRange);
        _yEnemy = new uint256[](xRange * yRange);
        uint256 count;
        for (uint256 a = _x; a <= xRange; a++) {
            for (uint256 b = _y; b <= yRange; b++) {
                Asset memory _asset = asset[a][b];
                if (!(isDefender && checkType(_asset.id))) {
                    _xEnemy[count] = a;
                    _yEnemy[count] = b;
                    exists = true;
                    count++;
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////
                                PLACE/UNPLACE
    //////////////////////////////////////////////////////////////////////*/

    /// @dev x->y->Asset info
    mapping(uint256 => mapping(uint256 => Asset)) public asset;
    /// @dev updated when attackers are added or they die
    uint256 public numberOfAttackers;

    /**
     * @notice place asset at _x,_y
     * @dev has to abide by game rules and owner needs to own id
     * update number of attackers if an attacker is being placed
     * @param _x x coordinate to place it in
     * @param _y y coordinate to place it in
     * @param owner address that owns the asset
     * @param id id of the asset to place
     */
    function place(
        uint256 _x,
        uint256 _y,
        address owner,
        uint256 id
    ) external gameStatus(false) onlyOwner {
        bool isDefender = checkType(id);
        if (!isDefender) numberOfAttackers++;
        IRewards(battlePass).burn(owner, id, 1);
        checkPlaceConditions(_x, _y, isDefender);
        uint256 health = getHealthForAsset(id);
        asset[_x][_y] = Asset(owner, health, id);
    }

    /**
     * @notice unplace asset at _x,_y
     * @dev owner must own the asset at _x,_y
     * decrease number of attackers
     * @param _x x coordinate to place it in
     * @param _y y coordinate to place it in
     * @param owner address that owns the asset
     */
    function unplace(
        uint256 _x,
        uint256 _y,
        address owner
    ) external gameStatus(false) {
        Asset memory _asset = asset[_x][_y];
        bool isDefender = checkType(_asset.id);
        if (!isDefender) numberOfAttackers--;
        IRewards(battlePass).mint(owner, _asset.health, 1);
        delete asset[_x][_y];
    }

    /*//////////////////////////////////////////////////////////////////////
                                FUN
    //////////////////////////////////////////////////////////////////////*/

    /// @dev number of times the action function has been called
    uint256 public ticks;

    /**
     * @notice keeper will call this function for all _x,_y on board
     * @dev checks if unit has health > 0, if yes that means its dead or empty
     * call action function for corresponding asset at that location;
     * all action functions then call the update function
     * add ticks
     * castle does not defend itself
     * for defender actions, a generator must be around
     */
    function action(uint256 _x, uint256 _y) external gameStatus(true) {
        Asset memory _asset = asset[_x][_y];
        uint256 assetId = _asset.id;
        bool isDefender = checkType(assetId);

        if (_asset.health == 0) return;
        uint256 range;
        uint256 damage;
        if (isDefender && isGeneratorAround(_x, _y)) {
            if (assetId == TURRET_ID) {
                range = TURRET_RANGE;
                damage = TURRET_DAMAGE;
            } else if (assetId == BOMBER_ID) {
                if (ticks % BOMBER_FIRE_TICKS == 0) {
                    defendBomber(_x, _y);
                }
                ticks++;
                return;
            }
        } else {
            if (assetId == EXPLOSIVE_ID) {
                if (ticks % EXPLOSIVE_FIRE_TICKS == 0) {
                    range = EXPLOSIVE_RANGE;
                    damage = EXPLOSIVE_DAMAGE;
                }
            } else if (assetId == RANGED_ID) {
                range = RANGED_RANGE;
                damage = RANGED_DAMAGE;
            } else if (assetId == MELEE_ID) {
                range = MELEE_RANGE;
                damage = MELEE_DAMAGE;
            }
        }
        (uint256 _xEnemy, uint256 _yEnemy, bool exists) = find(_x, _y, TURRET_RANGE, isDefender);
        if (exists) {
            update(_xEnemy, _yEnemy, TURRET_DAMAGE, _x, _y);
        }
        ticks++;
    }

    /// @dev execute bomber's defense action
    function defendBomber(uint256 _x, uint256 _y) private {
        (uint256[] memory _xEnemies, uint256[] memory _yEnemies, bool enemiesExist) = findAll(
            _x,
            _y,
            BOMBER_RANGE,
            true
        );
        if (enemiesExist) {
            for (uint256 z; z < _xEnemies.length; z++) {
                update(_xEnemies[z], _yEnemies[z], BOMBER_DAMAGE, _x, _y);
            }
        }
        return;
    }

    /**
     * @dev update health of asset at _xDamaged,_yDamaged
     * assume find function filters out empty slots and there is an alive asset at these coordinates
     * if health is being set to 0, then delete that asset; emit AssetDead event
     * emit UpdatHealth event with new health
     * if an attacker is dead then update number of attackers on the board
     * @param _xDamaged x coordinate of asset thats damaged
     * @param _yDamaged y coordinate of asset thats damaged
     * @param damage amount to subtract from _xDamaged,_yDamaged's health
     * @param _x x coordinate of asset inflicting damage
     * @param _y y coordinate of asset inflicting damage
     */
    function update(
        uint256 _xDamaged,
        uint256 _yDamaged,
        uint256 damage,
        uint256 _x,
        uint256 _y
    ) private {
        Asset storage _asset = asset[_xDamaged][_yDamaged];
        if (_asset.health > damage) {
            _asset.health -= damage;
            emit UpdateHealth(_x, _y, _xDamaged, _yDamaged);
        } else {
            bool isDefender = checkType(_asset.id);
            if (!isDefender) numberOfAttackers--;
            delete asset[_xDamaged][_yDamaged];
            emit AssetDead(_xDamaged, _yDamaged);
        }
    }

    /**
     * @notice check if game is over or not
     * @dev require game to be onmgoing
     * we dont want to calculate number of alive attackers by looping so we maintain another variable
     * game is over if castle health == 0 or number of attackers == 0
     * if game is over then terminate game
     * emit GameOver event
     * give SBT of win/lose
     * @return over true if over false otherwise
     */
    function isGameOver() public returns (bool over) {
        Asset memory _asset = asset[CASTLE_X][CASTLE_Y];
        if (_asset.health == 0) {
            over = true;
            start = false;
            emit GameOver(false);
        } else if (numberOfAttackers == 0) {
            over = true;
            start = false;
            emit GameOver(true);
        } else {}
    }

    /**
     * @notice move attackers, called for every unit in grid once action and check for isGameOver is made
     * @dev
     * return if health of unit == 0 or is a defender
     * check if there are any defences in range; if yes then dont move
     * if not then move towards the castle making sure that u dont go where another attacker already is
     * will revert if game ended
     * @param _x x coordinate
     * @param _y y coordinate
     */
    function move(uint256 _x, uint256 _y) external gameStatus(true) {
        Asset memory _asset = asset[_x][_y];
        bool defenderExists;
        if (_asset.health == 0 || checkType(_asset.id)) return;
        if (_asset.id == MELEE_ID && ticks % MELEE_MOVE_TICKS == 0) {
            (, , defenderExists) = find(_x, _y, MELEE_RANGE, false);
        } else if (_asset.id == RANGED_ID && ticks % RANGED_MOVE_TICKS == 0) {
            (, , defenderExists) = find(_x, _y, RANGED_RANGE, false);
        } else if (_asset.id == EXPLOSIVE_ID) {
            (, , defenderExists) = find(_x, _y, EXPLOSIVE_RANGE, false);
        }
        if (defenderExists) return;

        uint256 newX = _x;
        uint256 newY = _y;
        // each attacker can only move once per tick
        (uint256 xRange, uint256 yRange) = adjustInRange(_x, _y, 1);
        uint256 xDistance = (_x << 2) + (CASTLE_X << 2) - (2 * _x * CASTLE_X);
        uint256 yDistance = (_y << 2) + (Y << 2) - (2 * _y * Y);
        uint256 distance = sqrt(xDistance + yDistance);

        //if there is someone else in moving range skip that location
        //if distnace to centre from a point is more than the current distance, skip that
        //if distance is less then move there
        for (uint256 a = _x; a <= xRange; a++) {
            for (uint256 b = _y; b <= yRange; b++) {
                //save computation
                if (a == _x && b == _y) continue;
                // dont go there if there is an attacker there already
                if (asset[a][b].health != 0) continue;
                uint256 dist = sqrt(
                    (a << 2) + (CASTLE_X << 2) - (2 * a * CASTLE_X) + (b << 2) + (Y << 2) - (2 * b * Y)
                );
                if (dist < distance) {
                    newX = a;
                    newY = b;
                    distance = dist;
                }
            }
        }
        asset[newX][newY] = _asset;
        delete asset[_x][_y];
        emit AttackerMove(_x, _y, newX, newY);
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     * copied from OZ since I dont wanna use an  entire lib to use 1 function
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb computation, we are able to compute `result = 2**(k/2)` which is a
        // good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
