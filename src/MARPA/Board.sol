// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Assets.sol";

/// @notice
/// @author rayquaza7
contract Board is Assets {
    /// @dev thrown when the id trying to add is invalid
    error InvalidId(uint256 id);

    /// @dev emitted when asset dies
    event AssetDead(uint256 indexed _x, uint256 indexed _y);
    /// @dev emitted when asset inflicts damage
    event UpdateHealth(uint256 indexed _x, uint256 indexed _y, uint256 _xDamaged, uint256 _yDamaged);
    /// @dev emitted when game's over; winner is true if the defenders won
    event GameOver(bool indexed winner);

    /// @dev number of times the action function has been called
    uint256 public countTicks;
    /// @dev updated when attackers are added or they die
    uint256 public numberOfAttackers;
    /// @dev true if game has started
    bool public start;
    /// @dev x->y->Asset info
    mapping(uint256 => mapping(uint256 => Asset)) public asset;
    /// @dev assetId->cid for ipfs/dpd
    mapping(uint256 => bytes32) public metadata;

    /// @dev uses for actions that can only be undertaken when game is either ongoing or stoppped
    /// @param _start true if need game to have already started, false otherwise
    modifier gameStatus(bool _start) {
        require(_start == start, "Cannot perform action in this game state");
        _;
    }

    /// @dev add castle in the middle
    constructor(
        string memory uri,
        address pass,
        address recipe
    ) MERC1155(uri, pass, recipe) {
        uint256 xMiddle = (X + 1) / 2;
        uint256 yMiddle = (Y + 1) / 2;
        asset[xMiddle][yMiddle] = Asset(address(this), CASTLE_HEALTH, CASTLE_ID);
    }

    /**
     * @notice check if a given asset is a defense unit or an attacking unit
     * @dev ids 1-10 reserved for defenders, 11-20 for attackers, castle is 0;
     * for simplicity castle is assumned to be a defensive unit
     * @param assetId asset id of asset to check
     * @return true if defender, false if attacker
     */
    function checkType(uint256 assetId) public pure returns (bool) {
        return assetId <= 10;
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
    ) external onlyRole(DEFAULT_ADMIN_ROLE) gameStatus(false) {
        bool isDefender = checkType(id);
        if (!isDefender) numberOfAttackers++;
        burn(owner, id, 1);
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
    ) external onlyRole(DEFAULT_ADMIN_ROLE) gameStatus(false) {
        Asset memory _asset = asset[_x][_y];
        bool isDefender = checkType(_asset.id);
        if (!isDefender) numberOfAttackers--;
        mint(owner, _asset.health, 1, "");
        delete asset[_x][_y];
    }

    /// @notice toggle game start/stop
    /// @dev only admin can toggle game
    /// @param toggle set to true to start game, false otherwise
    function toggleGame(bool toggle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        start = toggle;
    }

    // Keeper functions
    // -------------------------------------------------

    /**
     * @notice keeper will call this function for all _x,_y on board
     * @dev checks if unit has health > 0, if yes that means its dead or empty
     * call action function for corresponding asset at that location;
     * all action functions then call the update function
     * add countTicks
     * castle does not defend itself
     * for defender actions, a generator must be around
     */
    function action(uint256 _x, uint256 _y) external onlyRole(DEFAULT_ADMIN_ROLE) gameStatus(true) {
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
                if (countTicks % BOMBER_FIRE_TICKS == 0) {
                    defendBomber(_x, _y);
                }
            }
        } else {
            if (assetId == EXPLOSIVE_ID) {
                if (countTicks % EXPLOSIVE_FIRE_TICKS == 0) {
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
        countTicks++;
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
        uint256 xMiddle = (X + 1) / 2;
        uint256 yMiddle = (Y + 1) / 2;
        Asset memory _asset = asset[xMiddle][yMiddle];
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

    function move(uint256 _x, uint256 _y) external onlyRole(DEFAULT_ADMIN_ROLE) gameStatus(true) {}
}
