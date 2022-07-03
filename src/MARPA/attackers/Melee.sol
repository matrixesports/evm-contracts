// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../../rewards/MERC1155.sol";
import "../interfaces/IBoard.sol";
import "../interfaces/IDefender.sol";

/**
@notice a explosive defense asset
@dev 
- user is rewarded a explosive by a lootbox
- id in contract must be equal to the creator_id
 */

contract Melee is MERC1155, IDefender {
    //move 1 unit 2 tick
    uint256 public moveTick = 2;
    uint256 public range = 1;
    uint256 public health = 10;
    uint256 public damage = 2;
    uint256 count;
    address public _board;
    IBoard private board = IBoard(_board);

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
    //read and call maybe?
    // loop over all stuff on board
    //maybe bot looks up all and their health and only calls ones that have health?
    function defend(uint256 _x, uint256 _y) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (count % firingRate != 0) return;
        (uint256 attack_x, uint256 attack_y, uint256 _attackerHealth) = board.find(_x, _y, range, false);
        //check for underflow
        if (_attackerHealth >= damage) {
            _attackerHealth -= damage;
        } else {
            health = 0;
        }
        board.update(attack_x, attack_y, _attackerHealth);
        board.update(_x, _y, 0);
    }

    //check if owner that they tryna place, if yea then call place in board, burn it too
    function place(
        address owner,
        uint256 id,
        uint256 _x,
        uint256 _y
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(balanceOf[owner][id] > 0, "no");
        burn(owner, id, 1);
        board.place(_x, _y, false, owner, address(this), health, id);
    }

    //check if owner matches the asset placed on the board, if yea then unplace it and mint it again
    function unplace(
        address owner,
        uint256 _x,
        uint256 _y
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        //confirm if it actually does lol
        (, address _owner, , , uint256 id) = board.getAsset(_x, _y);
        require(_owner == owner, "no");
        board.unplace(_x, _y);
        mint(_owner, id, 1, "");
    }
}
