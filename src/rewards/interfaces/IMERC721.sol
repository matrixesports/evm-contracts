// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "openzeppelin-contracts/contracts/access/IAccessControl.sol";

interface IMERC721 is IAccessControl {
    function mint(address to) external;

    function burn(address from, uint256 id) external;
}
