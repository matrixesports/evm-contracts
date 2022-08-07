// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./CraftingStorage.sol";
import "solmate/utils/Bytes32AddressLib.sol";

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

abstract contract UUPSUpgradeable is CraftingStorage, IERC1822Proxiable {
    using Bytes32AddressLib for bytes32;

    address private immutable __self = address(this);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /**
     * @dev Check that the execution is being performed through a delegatecall call
     * second require statement will only be true if address of this contract is the same as the one stored in the implementation slot,
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
     * proxy->Crafting
     */
    function proxiableUUID() external view virtual override returns (bytes32) {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy onlyOwner {
        try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
            require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
        } catch {
            revert("ERC1967Upgrade: new implementation is not UUPS");
        }
        require(newImplementation.code.length > 0, "ERC1967: new implementation is not a contract");
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
        emit Upgraded(newImplementation);
    }
}
