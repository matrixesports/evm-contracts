// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../Utils.sol";
import "./interfaces/IMERC1155.sol";
import "solmate/tokens/ERC1155.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

///@dev default 1155 token
contract MERC1155 is ERC1155, AccessControl, IMERC1155 {
    string public tokenURI;

    ///@dev give minter role to sender, pass/lootbox and recipe
    constructor(
        string memory _uri,
        address passOrLootbox,
        address recipe
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, passOrLootbox);
        _grantRole(MINTER_ROLE, recipe);
        tokenURI = _uri;
    }

    /*//////////////////////////////////////////////////////////////////////
                                MINTING
    //////////////////////////////////////////////////////////////////////*/

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual onlyRole(MINTER_ROLE) {
        _mint(to, id, amount, data);
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public virtual onlyRole(MINTER_ROLE) {
        _burn(from, id, amount);
    }

    /*//////////////////////////////////////////////////////////////////////
                                    URI
    //////////////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual override returns (string memory) {
        return string.concat(tokenURI, "/", Strings.toString(id), ".json");
    }

    function setURI(string memory _uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenURI = _uri;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
