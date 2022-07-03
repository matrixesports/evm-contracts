// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IDefender {
    function range() external returns (uint256);

    function health() external returns (uint256);

    function damage() external returns (uint256);

    function _board() external returns (address);

    function setBoard(address _newBoard) external;

    function defend(uint256 _x, uint256 _y) external;

    function place(
        address owner,
        uint256 id,
        uint256 _x,
        uint256 _y
    ) external;

    function unplace(
        address owner,
        uint256 _x,
        uint256 _y
    ) external;
}
