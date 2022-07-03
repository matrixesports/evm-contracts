// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IBoard {
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

    function findAll(
        uint256 _x,
        uint256 _y,
        uint256 range,
        bool offensive
    )
        external
        view
        returns (
            uint256[] memory allX,
            uint256[] memory allY,
            uint256[] memory allHealth
        );

    function update(
        uint256 _x,
        uint256 _y,
        uint256 _newHealth
    ) external;

    function place(
        uint256 _x,
        uint256 _y,
        bool offensive,
        address _owner,
        address assetContract,
        uint256 health,
        uint256 assetId
    ) external;

    function placeGenerator(
        uint256 _x,
        uint256 _y,
        bool offensive,
        address _owner,
        address assetContract,
        uint256 health,
        uint256 assetId
    ) external;

    function unplace(uint256 _x, uint256 _y) external;

    function getAsset(uint256 _x, uint256 _y)
        external
        view
        returns (
            bool,
            address,
            address,
            uint256,
            uint256
        );

    function isGeneratorAround(uint256 _x, uint256 _y) external view returns (bool);
}
