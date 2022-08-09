// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import {BattlePass} from "./BattlePass.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Bytes32AddressLib} from "solmate/utils/Bytes32AddressLib.sol";

/// @title BattlePass Factory
/// @dev  adapted from https://github.com/Rari-Capital/vaults/blob/main/src/VaultFactory.sol
/// @notice Factory which enables deploying a BattlePass for any creatorId
contract BattlePassFactory {
    using Bytes32AddressLib for bytes32;

    /// @dev they need to be constant for when we create2 addresses
    /// constructor args need to be constant
    address public immutable craftingProxy;
    address public immutable owner;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a BattlePass factory.
    constructor(address _craftingProxy) {
        craftingProxy = _craftingProxy;
        owner = msg.sender;
    }

    /*///////////////////////////////////////////////////////////////
                        BattlePass DEPLOYMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new BattlePass is deployed.
    /// @param bp The newly deployed BattlePass contract.
    /// @param creatorId The underlying creatorId the new BattlePass accepts.
    event BattlePassDeployed(BattlePass bp, uint256 creatorId);

    /// @notice Deploys a new BattlePass which supports a specific underlying creatorId.
    /// @dev This will revert if a BattlePass that accepts the same underlying creatorId has already been deployed.
    /// @param creatorId The creatorId that the BattlePass should accept.
    /// @return bp The newly deployed BattlePass contract
    function deployBattlePass(uint256 creatorId) external returns (BattlePass bp) {
        require(msg.sender == owner, "UNAUTHORIZED");
        bp = new BattlePass{salt: bytes32(creatorId)}(creatorId, craftingProxy,owner);
        emit BattlePassDeployed(bp, creatorId);
    }

    /*///////////////////////////////////////////////////////////////
                        BATTLEPASS LOOKUP LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Computes a BattlePass's address from its accepted underlying creatorId
    /// @param creatorId The creatorId that the BattlePass should accept.
    /// @return The address of a BattlePass which accepts the provided underlying creatorId.
    /// @dev The BattlePass returned may not be deployed yet. Use isBattlePassDeployed to check.
    function getBattlePassFromUnderlying(uint256 creatorId) external view returns (BattlePass) {
        return BattlePass(
            payable(
                keccak256(
                    abi.encodePacked(
                        bytes1(0xFF),
                        address(this),
                        creatorId,
                        keccak256(abi.encodePacked(type(BattlePass).creationCode, abi.encode(creatorId, craftingProxy, owner)))
                    )
                )
                    // Prefix:
                    // Creator:
                    // Salt:
                    // Bytecode hash:
                    // Deployment bytecode:
                    // Constructor arguments:
                    .fromLast20Bytes() // Convert the CREATE2 hash into an address.
            )
        );
    }

    /// @notice Returns if a BattlePass at an address has already been deployed.
    /// @param bp The address of a BattlePass which may not have been deployed yet.
    /// @return A boolean indicating whether the BattlePass has been deployed already.
    /// @dev This function is useful to check the return values of getBattlePassFromUnderlying,
    /// as it does not check that the BattlePass addresses it computes have been deployed yet.
    function isBattlePassDeployed(BattlePass bp) external view returns (bool) {
        return address(bp).code.length > 0;
    }
}
