// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "../src/BattlePassFactory.sol";
import "../src/Crafting.sol";
import "forge-std/Test.sol";

contract BattlePassFactoryTest is Test {
    BattlePassFactory factory;
    Crafting crafting;

    function setUp() public {
        crafting = new Crafting();
        factory = new BattlePassFactory(address(crafting));
    }

    function testConstructor() public {
        assertEq(address(this), factory.owner());
        assertEq(address(crafting), factory.craftingProxy());
    }

    function testDeploy(uint256 creatorId) public {
        BattlePass bp = factory.deployBattlePass(creatorId);
        assertEq(address(bp), address(factory.getBattlePassFromUnderlying(creatorId)));
    }

    function testRevertDeployNonOwner(address hacker) public {
        vm.assume(hacker != address(this));
        vm.startPrank(hacker);
        vm.expectRevert(abi.encodePacked("UNAUTHORIZED"));
        factory.deployBattlePass(1);
    }

    function testRevertDeployAlreadyDeployed() public {
        factory.deployBattlePass(1);
        vm.expectRevert();
        factory.deployBattlePass(1);
    }

    function testIsBattlePassDeployed() public {
        BattlePass bp;
        assertFalse(factory.isBattlePassDeployed(bp));
        bp = factory.deployBattlePass(1);
        assertTrue(factory.isBattlePassDeployed(bp));
    }
}
