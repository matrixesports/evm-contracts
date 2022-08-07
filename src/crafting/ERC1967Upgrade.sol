// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/interfaces/draft-IERC1822.sol";

bytes32 constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

/// @notice modified and minimal upgradable UUPS proxy
/// @dev adapted from
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.2/contracts/proxy/ERC1967/ERC1967Upgrade.sol
abstract contract ERC1967Upgrade {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
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
