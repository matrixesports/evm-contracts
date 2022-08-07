// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {_IMPLEMENTATION_SLOT} from "./CraftingStorage.sol";

contract Proxy {
    constructor(address implementation) {
        (bool success,) = implementation.delegatecall(abi.encodeWithSignature("initialize(address)", msg.sender));
        require(success);
        (success,) = implementation.delegatecall(abi.encodeWithSignature("initialize(address)", msg.sender));
    }

    fallback() external {
        assembly {
            let implementation := sload(_IMPLEMENTATION_SLOT)
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
