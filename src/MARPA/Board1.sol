// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Assets.sol";
import "../rewards/MERC1155.sol";

contract Board is MERC1155 {
    /// @dev thrown when the id trying to add is invalid
    error InvalidId(uint256 id);

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
}
