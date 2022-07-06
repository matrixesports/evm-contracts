// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";

contract DevScript is Script {
    function run() public {}
}

contract Hello {
    function hello() public returns (Asset[] memory) {
        Asset[] memory assets = new Asset[](2);
        assets[1].owner = address(this);
        return assets;
    }
}
