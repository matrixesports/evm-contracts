// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "solmate/tokens/ERC1155.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

uint256 constant SBT_WIN_ID = 1;
uint256 constant SBT_LOSE_ID = 2;

/// @title ETERNAL GLORY OR SHAME
/// @notice Soul Bound token for when a community loses or wins a game
/// @dev no transfer or burn function good luck
abstract contract EternalGlory is ERC1155 {
    constructor(string memory _uri) {
        tokenURI = _uri;
    }

    /// @notice give this communnity's game a SBT if they win or lose a game
    /// @param win true if won the game, false otherwise
    function mintSBT(bool win) internal {
        if (win) {
            _mint(address(this), SBT_WIN_ID, 1, "");
        } else {
            _mint(address(this), SBT_LOSE_ID, 1, "");
        }
    }

    string public tokenURI;

    function uri(uint256 id) public view override returns (string memory) {
        return string.concat(tokenURI, "/", Strings.toString(id), ".json");
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
}
