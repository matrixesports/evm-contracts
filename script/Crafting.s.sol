// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "../src/Crafting.sol";

contract CraftingScript is Script {
    Crafting crafting;

    function newCrafting() public {
        vm.startBroadcast();
        crafting = new Crafting();
    }
}
