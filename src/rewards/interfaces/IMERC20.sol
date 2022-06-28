// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "openzeppelin-contracts/contracts/access/IAccessControl.sol";

interface IMERC20 is IAccessControl {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}
