// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "../src/Utils.sol";

contract UtilsTest is Test {
    ///@dev gotta check is someone accidentally changed roles
    function testRoles() public {
        assertEq(MINTER_ROLE, keccak256("MINTER_ROLE"));
        assertEq(ORACLE_ROLE, keccak256("ORACLE_ROLE"));
    }
}
