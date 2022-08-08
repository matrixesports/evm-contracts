// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Script.sol";
import "../src/BattlePassFactory.sol";
import "../src/Crafting.sol";
import "../src/uups/ERC1967Proxy.sol";

contract DeployScript is Script {
    function run() public {}

    function deploy() public {
        vm.startBroadcast();
        Crafting crafting = new Crafting();
        bytes memory data = abi.encodeWithSelector(crafting.initialize.selector);
        ERC1967Proxy proxy = new ERC1967Proxy(address(crafting), data);
        BattlePassFactory factory = new BattlePassFactory(address(proxy));
    }

    /// @dev make sure storage layout is same, u inherit from uups, only core logic changes and do test runs
    function upgrade() public {
        //ERC1967Proxy proxy = ERC1967Proxy(<address>);
        // (bool success,) = address(proxy).call(abi.encodeWithSelector(Crafting.upgradeTo.selector, <new crafting>));
        //require(succcess)
    }
}
