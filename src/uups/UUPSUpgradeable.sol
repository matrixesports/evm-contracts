// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC1967Upgrade.sol";
import "solmate/utils/Bytes32AddressLib.sol";

abstract contract UUPSUpgradeable is ERC1967Upgrade {
    using Bytes32AddressLib for bytes32;

    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call
     * second require statement will only be true if address of this contract is the same as the one stored in the proxy implementation slot,
     * and since thats done in the proxy, this is a check to make sure that its coming from a proxy that prepared to handle this delegatecall
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        bytes32 implementationValue;
        assembly {
            implementationValue := sload(_IMPLEMENTATION_SLOT)
        }
        address implementation = implementationValue.fromLast20Bytes();
        require(implementation == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     *
     */
    function proxiableUUID() external view returns (bytes32) {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        return _IMPLEMENTATION_SLOT;
    }
}
