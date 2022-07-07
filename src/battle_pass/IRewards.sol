// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IRewards {
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;
}
