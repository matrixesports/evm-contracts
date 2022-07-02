pragma solidity ^0.8.10;

interface Interface {
    event AssetDead(uint256 indexed x, uint256 indexed y);
    event AssetHit(uint256 indexed x, uint256 indexed y);
    event AssetPlaced(uint256 indexed x, uint256 indexed y);
    event AssetUnplaced(uint256 indexed x, uint256 indexed y);

    struct Asset {
        bool a;
        address b;
        address c;
        uint256 d;
        uint256 e;
    }

    function addToWhitelist(address[] memory addys) external;

    function assets(bytes32)
        external
        view
        returns (
            bool offensive,
            address owner,
            address assetContract,
            uint256 health,
            uint256 assetId
        );

    function checkPlacementCondition(
        uint256 _x,
        uint256 _y,
        bool offensive
    ) external view;

    function find(
        uint256 _x,
        uint256 _y,
        uint256 range,
        bool offensive
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getHash(uint256 _x, uint256 _y) external pure returns (bytes32);

    function grid(uint256, uint256) external view returns (uint256);

    function owner() external view returns (address);

    function place(
        uint256 _x,
        uint256 _y,
        Asset memory _asset
    ) external;

    function started() external view returns (bool);

    function toggleGame(bool _started) external;

    function unplace(uint256 _x, uint256 _y) external;

    function update(
        uint256 _x,
        uint256 _y,
        uint256 _newHealth
    ) external;

    function whitelist(address) external view returns (bool);

    function x() external view returns (uint256);

    function y() external view returns (uint256);
}
