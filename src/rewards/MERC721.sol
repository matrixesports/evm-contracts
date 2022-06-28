// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../Utils.sol";
import "./interfaces/IMERC721.sol";
import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

error NotOwnedByUser(address user, uint256 id);

/// @dev default ERC721 reward with metadata support and minting access control, extremely basic, customize on top of this
contract MERC721 is ERC721, AccessControl, IMERC721 {
    string public uri;
    uint256 public currentId;

    //minter role to recipe,sender and pass/lootbox ctr
    constructor(
        string memory name,
        string memory symbol,
        string memory _uri,
        address passOrLootbox,
        address recipe
    ) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, passOrLootbox);
        _grantRole(MINTER_ROLE, recipe);
        uri = _uri;
    }

    /*//////////////////////////////////////////////////////////////////////
                                MINTING
    //////////////////////////////////////////////////////////////////////*/

    ///@dev id can be used if current id isnt, implementation specific
    function mint(address _to) public onlyRole(MINTER_ROLE) {
        unchecked {
            currentId++;
        }
        _mint(_to, currentId);
    }

    function burn(address from, uint256 id) public onlyRole(MINTER_ROLE) {
        if (_ownerOf[id] != from) revert NotOwnedByUser(from, id);
        _burn(id);
    }

    /*//////////////////////////////////////////////////////////////////////
                                    URI 
    //////////////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string.concat(uri, "/", Strings.toString(id), ".json");
    }

    function setURI(string memory _uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uri = _uri;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
