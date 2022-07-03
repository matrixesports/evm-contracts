// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../../rewards/MERC1155.sol";
import "../interfaces/IBoard.sol";

/**
@notice a turret defense asset
@dev 
- user is rewarded a turret by a lootbox
- id in contract must be equal to the creator_id
 */

contract Turret is MERC1155 {
    uint256 public attackRadius = 2;
    uint256 public health = 5;
    uint256 public damage = 1;
    address public _board;
    IBoard board = IBoard(_board);

    //defends every tick

    constructor(
        string memory uri,
        address pass,
        address recipe
    ) MERC1155(uri, pass, recipe) {}

    function setBoard(address _newBoard) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _board = _newBoard;
        board = IBoard(_board);
    }

    //find unit in range, damage it, send it back, i wish we could use delegate call here
    function defend() public {}

    //check if owner that they tryna place, if yea then call place in board, burn it too
    function place(
        address owner,
        uint256 id,
        uint256 _x,
        uint256 _y
    ) public {
        require(balanceOf[owner][id] > 0, "no");
        burn(owner, id, 1);
        board.place(_x, _y, false, owner, address(this), health, id);
    }

    //check if owner matches the asset placed on the board, if yea then unplace it and mint it again
    function unplace(
        address owner,
        uint256 _x,
        uint256 _y
    ) public {
        //confirm if it actually does lol
        (, address _owner, , , uint256 id) = board.getAsset(_x, _y);
        require(_owner == owner, "no");
        board.unplace(_x, _y);
        mint(_owner, id, 1, "");
    }
}
