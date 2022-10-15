// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Script.sol";
import "../src/BattlePassFactory.sol";
import "../src/Crafting.sol";
import "../src/uups/ERC1967Proxy.sol";

contract DeployScript is Script {
    function run() public {
        deploy();
    }

    function deploy() public {
        vm.startBroadcast();
        Crafting crafting = new Crafting();
        bytes memory data = abi.encodeWithSelector(crafting.initialize.selector);
        ERC1967Proxy proxy = new ERC1967Proxy(address(crafting), data);
        BattlePassFactory factory = new BattlePassFactory(address(proxy));
    }

    /// @dev make sure storage layout is same, u inherit from uups, only core logic changes and do test runs
    function upgrade() public {
        // vm.startBroadcast();
        //ERC1967Proxy proxy = ERC1967Proxy(<address>);
        // (bool success,) = address(proxy).call(abi.encodeWithSelector(Crafting.upgradeTo.selector, <new crafting>));
        //require(succcess)
    }

    function deployCreator() public {
        // vm.startBroadcast();
        // BattlePassFactory factory = BattlePassFactory(0x5E81bEC5DEBE7e3330407E76C018eC5cBCcA1a1e);
        // // factory.deployBattlePass(1);
        // BattlePass bp = factory.getBattlePassFromUnderlying(1);
        // console.log(address(bp));
    }
}
