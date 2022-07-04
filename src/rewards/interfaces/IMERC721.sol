// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "openzeppelin-contracts/contracts/access/IAccessControl.sol";

/// @notice expose mint, burn and access control methods
interface IMERC721 is IAccessControl {
    function mint(address to) external;

    function burn(address from, uint256 id) external;
}
