// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Assets.sol";
import "../rewards/MERC1155.sol";

/// @notice
/// @author rayquaza7
contract Board is MERC1155 {
    /// @dev thrown when the id trying to add is invalid
    error InvalidId(uint256 id);

    /// @dev emitted when asset dies
    event AssetDead(uint256 indexed _x, uint256 indexed _y);
    /// @dev emitted when asset inflicts damage
    event UpdateHealth(uint256 indexed _x, uint256 indexed _y, uint256 _xDamaged, uint256 _yDamaged);

    /// @dev number of times the action function has been called
    uint256 public countTicks;
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
        asset[xMiddle][yMiddle] = Asset(address(this), castleHealth, castleId);
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
     * @param id asset id to be placed
     */
    function checkPlaceConditions(
        uint256 _x,
        uint256 _y,
        uint256 id
    ) public view {
        bool isDefender = checkType(id);
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
        if (assetId == turretId) {
            health = turretHealth;
        } else if (assetId == bomberId) {
            health = bomberHealth;
        } else if (assetId == generatorId) {
            health = generatorHealth;
        } else if (assetId == wallId) {
            health = wallHealth;
        } else if (assetId == meleeId) {
            health = meleeHealth;
        } else if (assetId == rangedId) {
            health = rangedHealth;
        } else if (assetId == explosiveId) {
            health = explosiveHealth;
        } else {
            revert InvalidId(assetId);
        }
    }

    /// @notice adjust x y coordinates according to board size and its range
    function adjustInRange(
        uint256 _x,
        uint256 _y,
        uint256 range
    ) public view returns (uint256 xRange, uint256 yRange) {
        xRange = _x + range;
        if (xRange > X) xRange = X;
        yRange = _y + range;
        if (yRange > Y) yRange = Y;
    }

    /**
     * @notice check if there is a generator around _x,_y
     * @dev adjust for board size
     * @return true if there is a generator
     */
    function isGeneratorAround(uint256 _x, uint256 _y) public view returns (bool) {
        (uint256 xRange, uint256 yRange) = adjustInRange(_x, _y, generatorRange);

        for (uint256 a = _x; a <= xRange; a++) {
            for (uint256 b = _y; b <= yRange; b++) {
                Asset memory _asset = asset[a][b];
                if (_asset.id == generatorId) return true;
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
        burn(owner, id, 1);
        checkPlaceConditions(_x, _y, id);
        uint256 health = getHealthForAsset(id);
        asset[_x][_y] = Asset(owner, health, id);
    }

    /**
     * @notice unplace asset at _x,_y
     * @dev owner must own the asset at _x,_y
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
            if (assetId == turretId) {
                range = turretRange;
                damage = turretDamage;
            } else if (assetId == bomberId) {
                if (countTicks % bomberFireTicks == 0) {
                    (uint256[] memory _xEnemies, uint256[] memory _yEnemies, bool enemiesExist) = findAll(
                        _x,
                        _y,
                        bomberRange,
                        isDefender
                    );
                    if (enemiesExist) {
                        for (uint256 z; z < _xEnemies.length; z++) {
                            update(_xEnemies[z], _yEnemies[z], bomberDamage, _x, _y);
                        }
                    }
                    return;
                }
            }
        } else {
            if (assetId == explosiveId) {
                if (countTicks % explosiveFireTicks == 0) {
                    range = explosiveRange;
                    damage = explosiveDamage;
                }
            } else if (assetId == rangedId) {
                range = rangedRange;
                damage = rangedDamage;
            } else if (assetId == meleeId) {
                range = meleeRange;
                damage = meleeDamage;
            }
        }
        (uint256 _xEnemy, uint256 _yEnemy, bool exists) = find(_x, _y, turretRange, isDefender);
        if (exists) {
            update(_xEnemy, _yEnemy, turretDamage, _x, _y);
        }
        countTicks++;
    }

    /**
     * @dev update health of asset at _xDamaged,_yDamaged
     * assume find function filters out empty slots and there is an alive asset at these coordinates
     * if health is being set to 0, then delete that asset; emit AssetDead event
     * emit UpdatHealth event with new health
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
            delete asset[_xDamaged][_yDamaged];
            emit AssetDead(_xDamaged, _yDamaged);
        }
    }

    function move(uint256 _x, uint256 _y) external onlyRole(DEFAULT_ADMIN_ROLE) gameStatus(true) {}

    function checkWinner() public view {}
}
