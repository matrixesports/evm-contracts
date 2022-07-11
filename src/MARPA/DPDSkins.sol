// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title DPDRepository
/// @notice The Decentralized Programmable Data (DPD) Repository stores data content identifiers, versions, authorized owners, and upgraders.
/// @dev edited to meet Pathfinder's requirements
/// each asset is a DPD, the communnity decides what their in game assets looks like
/// @author David Lucid <david@pentagon.xyz>
contract DPDSkins {
    /// @dev asset id->dpd data
    mapping(uint256 => bytes) public dpds;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    /// @notice Function to add/update a new DPD.
    /// @param assetId asset id
    /// @param cid DPD CID (content identifier).
    function updateDpd(uint256 assetId, bytes calldata cid) external {
        require(owner == msg.sender, "NO");
        dpds[assetId] = cid;
    }
}
