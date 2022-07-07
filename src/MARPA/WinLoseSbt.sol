// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "solmate/tokens/ERC1155.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

uint256 constant SBT_WIN_ID = 1;
uint256 constant SBT_LOSE_ID = 2;

/// @notice Soul Bound token for when u lose or win game
/// @dev no transfer or burn function
abstract contract WinLoseSbt is ERC1155 {
    string tokenURI;

    constructor(string memory uri_) {
        tokenURI = uri_;
    }

    function safeBatchTransferFrom(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public override {
        return;
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public override {
        return;
    }

    function setApprovalForAll(address, bool) public override {
        return;
    }

    function uri(uint256 id) public view override returns (string memory) {
        return string.concat(tokenURI, "/", Strings.toString(id), ".json");
    }
}
