// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../src/uups/ERC1967Proxy.sol";
import "../src/uups/UUPSUpgradeable.sol";
import "solmate/utils/Bytes32AddressLib.sol";

contract V1 is UUPSUpgradeable {
    address owner;

    function initialize() public {
        owner = msg.sender;
    }

    function upgradeTo(address newImplementation) external {
        if (msg.sender == owner) {
            _upgradeTo(newImplementation);
        }
    }
}

contract V2 is UUPSUpgradeable {
    address owner;
    uint256 x;

    function initialize() public {
        owner = msg.sender;
    }

    function setX(uint256 _x) public {
        x = _x;
    }

    function upgradeTo(address newImplementation) external {
        if (msg.sender == owner) {
            _upgradeTo(newImplementation);
        }
    }
}

/// @dev test proxy
contract ERC1967ProxyTest is Test {
    using Bytes32AddressLib for address;
    using Bytes32AddressLib for bytes32;

    ERC1967Proxy proxy;
    V1 v1;

    event Upgraded(address indexed implementation);

    function setUp() public {
        v1 = new V1();
        bytes memory data = abi.encodeWithSelector(v1.initialize.selector, address(this));
        proxy = new ERC1967Proxy(address(v1),data);
    }

    function testConstructor() public {
        bytes32 impl = vm.load(address(proxy), _IMPLEMENTATION_SLOT);
        assertEq(impl.fromLast20Bytes(), address(v1));
        bytes32 owner = vm.load(address(proxy), 0);
        assertEq(address(this), owner.fromLast20Bytes());
    }

    function testUpgrade() public {
        V2 v2 = new V2();
        vm.expectEmit(true, true, false, false);
        emit Upgraded(address(v2));
        (bool success,) = address(proxy).call(abi.encodeWithSelector(v1.upgradeTo.selector, address(v2)));
        assertTrue(success);
        bytes32 impl = vm.load(address(proxy), _IMPLEMENTATION_SLOT);
        console.log(impl.fromLast20Bytes());
        assertEq(impl.fromLast20Bytes(), address(v2));

        uint256 x_val = 10;
        (success,) = address(proxy).call(abi.encodeWithSelector(v2.setX.selector, x_val));
        assertTrue(success);
        uint256 slot = 1;
        bytes32 x = vm.load(address(proxy), bytes32(slot));
        assertEq(x, bytes32(x_val));
    }
}
