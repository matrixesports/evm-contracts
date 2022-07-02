// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

struct Asset {
    //true if attacker asset, false otherwise
    bool offensive;
    //who owns it in the asset contract
    address owner;
    //where is this thing coming from
    //read this to figure out more about the asset
    address assetContract;
    //current health of unit
    uint256 health;
    //id in the asset contract
    uint256 assetId;
}

/**
@notice 
- maintain grid state
- place/unplace assets
- track attacers/defenders
- track if game has started/ended
- track who won
- all events are emitted here
- deploy asset contracts first and whitelist contarcts that can execute above functions
 */
contract Board {
    bool public started;
    address public immutable owner;

    //15x15 grid, 0 indexed, [x,y]
    uint256 public constant x = 14;
    uint256 public constant y = 14;
    //check how 5outof9 handle sboard representation
    uint256[x][y] public grid;

    //address of asset contarcts
    mapping(address => bool) public whitelist;
    //keccak256(abi.encodePacked(x,y))->health
    //each hash correspondo to a single point on the gird
    //and since x,y will always point to a unique spot we good
    mapping(bytes32 => Asset) public assets;

    modifier onlyOwner() {
        require(msg.sender == owner, "no");
        _;
    }

    modifier whitelisted() {
        require(whitelist[msg.sender], "no");
        _;
    }

    modifier gameStarted() {
        require(started, "no");
        _;
    }

    modifier gameNotStarted() {
        require(!started, "no");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    //start stop game
    function toggleGame(bool _started) public onlyOwner {
        started = _started;
    }

    //add asset addresses
    function addToWhitelist(address[] calldata addys) public onlyOwner {
        for (uint256 z; z < addys.length; z++) {
            whitelist[addys[z]] = true;
        }
    }

    function getHash(uint256 _x, uint256 _y) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_x, _y));
    }

    /*//////////////////////////////////////////////////////////////////////
                                READ BOARD
    //////////////////////////////////////////////////////////////////////*/

    //find units in range of _x,_y
    //OOHHH only need to find one; return first one
    //if offensive == true find attackers with non zero health, else defenders
    //return: array of x,y,health of unit found
    function find(
        uint256 _x,
        uint256 _y,
        uint256 range,
        bool offensive
    )
        public
        view
        returns (
            uint256[] memory _xRange,
            uint256[] memory _yRange,
            uint256[] memory _health
        )
    {
        uint256 x_range = _x + range;
        if (x_range > x) x_range = x;
        uint256 y_range = _y + range;
        if (y_range > y) y_range = y;

        //can have atmost x_range * y_range elements
        _xRange = new uint256[](x_range * y_range);
        _yRange = new uint256[](x_range * y_range);
        _health = new uint256[](x_range * y_range);

        //[a,b]
        for (uint256 a = _x; a <= x_range; a++) {
            for (uint256 b = _y; b <= y_range; b++) {
                Asset memory _asset = assets[getHash(a, b)];
                if (_asset.health == 0) continue;
                //look for defenders
                if (offensive) {
                    //just another attacker there
                    if (_asset.offensive) continue;
                    // _xRange.push(a);
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////
                                PLACE/UNPLACE
    //////////////////////////////////////////////////////////////////////*/

    function place() public gameNotStarted whitelisted {}

    function unplace() public gameNotStarted whitelisted {}

    // //x->y->asset placed or not
    // mapping(uint256 => mapping(uint256 => bool)) public occupied;
    // //x->y->health of asset placed
    // mapping(uint256 => mapping(uint256 => uint256)) public health;
    // //assets placed
    // mapping(uint256 => mapping(uint256 => PlacedAsset)) public placedAsset;
    // //asset info
    // mapping(uint256 => Asset) public asset;

    // constructor(
    //     string memory uri,
    //     address passOrLootbox,
    //     address recipe
    // ) MERC1155(uri, passOrLootbox, recipe) {
    //     //define assets
    //     //castle
    //     asset[0] = Asset(100, 0, 0);
    //     //defenders: 1-10 reserved for defenders
    //     asset[1] = Asset(20, 10, 1);
    //     //attacker: 11-20 for attackers
    //     asset[11] = Asset(100, 10, 1);

    //     //place castle in the middle
    //     uint256 _x = (x / 2) + 1;
    //     uint256 _y = (y / 2) + 1;
    //     occupied[_x][_y] = true;
    //     placedAsset[_x][_y] = PlacedAsset(address(this), 0);
    // }

    // /*//////////////////////////////////////////////////////////////////////
    //                             PLACEMENT
    // //////////////////////////////////////////////////////////////////////*/

    // //dont allow to put defence around boundary since thats where attacks will be placed
    // //dont allow to put attack anywhere except boundary
    // //make sure its within boundary
    // //id 0 reserved for castle, nobody gets it
    // //id 1-10 reserved for defensive assets
    // //id 11-20 for attacking assets
    // function checkPlacementCondition(
    //     uint256 _x,
    //     uint256 _y,
    //     uint256 id
    // ) public view {
    //     require(!occupied[_x][_y], "no");
    //     if (id <= 10) {
    //         require(_x != 0 && _y != 0 && _x < x && _y < y, "no");
    //     } else {
    //         require(_x == 0 || _y == 0 || _x == x || _y == y, "no");
    //     }
    // }

    // function place(
    //     uint256 _x,
    //     uint256 _y,
    //     uint256 id,
    //     address owner
    // ) public onlyRole(DEFAULT_ADMIN_ROLE) gameStopped {
    //     burn(owner, id, 1);
    //     checkPlacementCondition(_x, _y, id);
    //     occupied[_x][_y] = true;
    //     placedAsset[_x][_y] = PlacedAsset(owner, id);
    // }

    // function unplace(
    //     uint256 _x,
    //     uint256 _y,
    //     address owner
    // ) public onlyRole(DEFAULT_ADMIN_ROLE) gameStopped {
    //     PlacedAsset memory _placedAsset = placedAsset[_x][_y];
    //     if (_placedAsset.owner == owner) {
    //         mint(owner, _placedAsset.id, 1, "");
    //     }
    //     occupied[_x][_y] = false;
    //     delete placedAsset[_x][_y];
    // }

    // function runEngine() public onlyRole(DEFAULT_ADMIN_ROLE) gameStarted {
    //     for (uint256 _x; _x <= x; _x++) {
    //         for (uint256 _y; _y <= y; _y++) {
    //             //castle cant do anything
    //             uint256 id = placedAsset[_x][_y].id;
    //             if (id == 0) {
    //                 continue;
    //             } else if (id <= 10) {
    //                 defendInRange(_x, _y, id);
    //             } else {
    //                 attackInRange(_x, _y, id);
    //             }
    //         }
    //     }
    // }

    // //defense units dont need to calculate range everytime
    // function defendInRange(
    //     uint256 _x,
    //     uint256 _y,
    //     uint256 id
    // ) private {
    //     Asset memory _asset = asset[id];
    //     uint256 x_range = _asset.range + _x;
    //     uint256 y_range = _asset.range + _y;
    //     if (x_range > x) x_range = x;
    //     if (x_range > y) y_range = y;
    //     // for (uint x_idx;x_idx<=+)
    // }

    // function attackInRange(
    //     uint256 _x,
    //     uint256 _y,
    //     uint256 id
    // ) private {}

    // //run every other block
    // function updatePositions() public onlyRole(DEFAULT_ADMIN_ROLE) gameStarted {}

    // /*//////////////////////////////////////////////////////////////////////
    //                             ADMIN CONTROLS
    // //////////////////////////////////////////////////////////////////////*/

    // function toggleGame(bool _toggle) public onlyRole(DEFAULT_ADMIN_ROLE) {
    //     started = _toggle;
    // }

    // modifier gameStarted() {
    //     require(started == true, "no");
    //     _;
    // }

    // modifier gameStopped() {
    //     require(started == false, "no");
    //     _;
    // }
}
