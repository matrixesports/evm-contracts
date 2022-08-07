// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../src/crafting/ERC1967Proxy.sol";
import "forge-std/Test.sol";

contract V1 is ERC1967Upgrade {
    uint256 x;
}

contract ERC1967ProxyTest is Test {
    function setUp() public {}
    function testConstructor() public {}
}
