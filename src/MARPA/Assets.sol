// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../rewards/MERC1155.sol";

/*//////////////////////////////////////////////////////////////////////
                                DEFENDERS
//////////////////////////////////////////////////////////////////////*/

///@dev ID 0 is special, cannot be minted; 1-10 reserved for defensive units

///@dev special: static, in middle, if health == 0 then attacking party wins
uint256 constant CASTLE_HEALTH = 10;
uint256 constant CASTLE_ID = 0;

///@dev special:
uint256 constant TURRET_HEALTH = 5;
uint256 constant TURRET_DAMAGE = 1;
uint256 constant TURRET_RANGE = 2;
uint256 constant TURRET_ID = 1;

///@dev special: can only fire once every 3 ticks and does splash damage in its range
uint256 constant BOMBER_HEALTH = 4;
uint256 constant BOMBER_DAMAGE = 3;
uint256 constant BOMBER_RANGE = 2;
//can only fire once every 3 ticks
uint256 constant BOMBER_FIRE_TICKS = 3;
uint256 constant BOMBER_ID = 2;

///@dev special: all other defences need a generator within 2 blocks of it or else they cannot defend
uint256 constant GENERATOR_HEALTH = 5;
uint256 constant GENERATOR_RANGE = 2;
uint256 constant GENERATOR_ID = 3;

///@dev special:
uint256 constant WALL_HEALTH = 10;
uint256 constant WALL_ID = 4;

/*//////////////////////////////////////////////////////////////////////
                                ATTACKERS
//////////////////////////////////////////////////////////////////////*/

///@dev 11-20 reserved for attacking units

///@dev special:
uint256 constant MELEE_HEALTH = 10;
uint256 constant MELEE_DAMAGE = 2;
uint256 constant MELEE_RANGE = 1;
//1 move per tick
uint256 constant MELEE_MOVE_TICKS = 2;
uint256 constant MELEE_ID = 11;

///@dev special:
uint256 constant RANGED_HEALTH = 3;
uint256 constant RANGED_DAMAGE = 1;
uint256 constant RANGED_RANGE = 2;
uint256 constant RANGED_MOVE_TICKS = 3;
uint256 constant RANGED_ID = 12;

///@dev special: health goes to 0 upon first attack
uint256 constant EXPLOSIVE_HEALTH = 5;
uint256 constant EXPLOSIVE_DAMAGE = 5;
uint256 constant EXPLOSIVE_RANGE = 1;
uint256 constant EXPLOSIVE_MOVE_TICKS = 1;
uint256 constant EXPLOSIVE_FIRE_TICKS = 3;
uint256 constant EXPLOSIVE_ID = 13;

/*//////////////////////////////////////////////////////////////////////
                            15x15 GRID
//////////////////////////////////////////////////////////////////////*/
uint256 constant X = 14;
uint256 constant Y = 14;

/*//////////////////////////////////////////////////////////////////////
                        SOULBOUND WIN/LOSE
//////////////////////////////////////////////////////////////////////*/

uint256 constant SBT_WIN_ID = 101;
uint256 constant SBT_LOSE_ID = 100;

/// @dev health determines if slot is empty or not
struct Asset {
    address owner;
    uint256 health;
    uint256 id;
}

/**
 * @notice responsible for minting all assets for the game
 * @dev asset ids are given above
 * assets are defenders, attackers
 * there is also a special kind of ID
 * ID 100 is a Loser Soul Bound NFT
 * ID 101 is a Winner Sould Bound NFT
 * it is awarded when a community loses/wins games and cannot be burned or transfered
 * metadata handle through dpds
 */
contract Assets is MERC1155 {
    /// @dev assetId->cid for ipfs/dpd
    mapping(uint256 => bytes32) public metadata;

    constructor(
        string memory uri,
        address pass,
        address recipe
    ) MERC1155(uri, pass, recipe) {}

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

    function uri(uint256 id) public view virtual override returns (string memory) {
        return string.concat(tokenURI, "/", Strings.toString(id), ".json");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}
