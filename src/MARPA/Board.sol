// // SPDX-License-Identifier: MIT
// pragma solidity >=0.8.0;

// import "../rewards/MERC1155.sol";

// struct Asset {
//     //true if attacker asset
//     bool isAttacker;
//     //user owns it in the asset contract
//     address owner;
//     //current health of asset
//     uint256 health;
//     //id in the asset contract
//     uint256 id;
// }

// /**
// @notice 
//  */
// contract Board is MERC1155 {
//     bool public started;
//     modifier gameStarted() {
//         require(started, "no");
//         _;
//     }

//     modifier gameNotStarted() {
//         require(!started, "no");
//         _;
//     }

//     //15x15 grid, 0 indexed, [x,y]
//     uint256 public constant x = 14;
//     uint256 public constant y = 14;
//     mapping(uint256 => mapping(uint256 => Asset)) public assets;

//     event AssetHit(uint256 indexed x, uint256 indexed y);
//     event AssetDead(uint256 indexed x, uint256 indexed y);
//     event AssetPlaced(uint256 indexed x, uint256 indexed y);
//     event AssetUnplaced(uint256 indexed x, uint256 indexed y);
//     //true if mtx wins false otherwise
//     event GameOver(bool indexed mtx);

//     ///@dev place castle in the middle
//     constructor(
//         string memory uri,
//         address pass,
//         address recipe
//     ) MERC1155(uri, pass, recipe) {
//         uint256 _x = (x + 1) / 2;
//         uint256 _y = (y + 1) / 2;
//         assets[keccak256(abi.encodePacked(_x, _y))] = Asset(false, address(this), address(this), 100, 0);
//     }

//     //start/stop game
//     function toggleGame(bool _started) public onlyRole(DEFAULT_ADMIN_ROLE) {
//         started = _started;
//     }

//     /*//////////////////////////////////////////////////////////////////////
//                                     GRID READ
//     //////////////////////////////////////////////////////////////////////*/

//     ///@dev if there isnt a generator within 2 units of _x,_y then it cannot defend
//     ///@param _x x coordinate of defence asset
//     ///@param _y y coordinate of defence asset
//     ///@return true if there is a generator around
//     function isGeneratorAround(uint256 _x, uint256 _y) public view returns (bool) {
//         uint256 x_range = _x + 2;
//         if (x_range > x) x_range = x;
//         uint256 y_range = _y + 2;
//         if (y_range > y) y_range = y;

//         //[a,b]
//         for (uint256 a = _x; a <= x_range; a++) {
//             for (uint256 b = _y; b <= y_range; b++) {
//                 if (isGenerator[getHash(a, b)]) return true;
//             }
//         }
//         return false;
//     }

//     //find unit in range of _x,_y
//     //OOHHH only need to find one; return first one
//     //if attacker == true find attackers with non zero health, else defenders
//     //return: x,y,health of unit found
//     function find(
//         uint256 _x,
//         uint256 _y,
//         uint256 range,
//         bool attacker
//     )
//         public
//         view
//         returns (
//             uint256,
//             uint256,
//             uint256
//         )
//     {
//         uint256 x_range = _x + range;
//         if (x_range > x) x_range = x;
//         uint256 y_range = _y + range;
//         if (y_range > y) y_range = y;

//         //[a,b]
//         for (uint256 a = _x; a <= x_range; a++) {
//             for (uint256 b = _y; b <= y_range; b++) {
//                 Asset memory _asset = getAsset(_x, _y);
//                 //nothing or dead
//                 if (_asset.health == 0) continue;
//                 //look for defenders
//                 if (attacker) {
//                     //just another attacker there
//                     if (_asset.attacker) continue;
//                     return (a, b, _asset.health);
//                 } else {
//                     //look for attackers
//                     if (_asset.attacker) {
//                         return (a, b, _asset.health);
//                     }
//                 }
//             }
//         }
//         //if nothing found
//         return (0, 0, 0);
//     }

//     //find all in range, needed for splash damage
//     function findAll(
//         uint256 _x,
//         uint256 _y,
//         uint256 range,
//         bool attacker
//     )
//         public
//         view
//         returns (
//             uint256[] memory allX,
//             uint256[] memory allY,
//             uint256[] memory allHealth
//         )
//     {
//         uint256 x_range = _x + range;
//         if (x_range > x) x_range = x;
//         uint256 y_range = _y + range;
//         if (y_range > y) y_range = y;

//         //worst case all need to be included coz surrounded by attackers F
//         //+1 coz prevent out of bounds
//         allX = new uint256[]((x_range * y_range) + 1);
//         allY = new uint256[]((x_range * y_range) + 1);
//         allHealth = new uint256[]((x_range * y_range) + 1);
//         //keep track of pushed elements to above lists
//         uint256 counter;

//         //[a,b]
//         for (uint256 a = _x; a <= x_range; a++) {
//             for (uint256 b = _y; b <= y_range; b++) {
//                 Asset memory _asset = getAsset(_x, _y);
//                 //nothing or dead
//                 if (_asset.health == 0) continue;
//                 //look for defenders
//                 if (attacker) {
//                     //just another attacker there
//                     if (_asset.attacker) continue;
//                 } else {
//                     //look for attackers
//                     if (!_asset.attacker) {
//                         continue;
//                     }
//                 }
//                 allX[counter] = a;
//                 allY[counter] = b;
//                 allHealth[counter] = _asset.health;
//                 counter++;
//             }
//         }
//         //if nothing found
//         return (allX, allY, allHealth);
//     }

//     /*//////////////////////////////////////////////////////////////////////
//                                 UPDATE BOARD
//     //////////////////////////////////////////////////////////////////////*/

//     //update health
//     function update(
//         uint256 _x,
//         uint256 _y,
//         uint256 _newHealth
//     ) public gameStarted whitelisted {
//         if (_newHealth == 0) emit AssetDead(_x, _y);
//         Asset memory _asset = getAsset(_x, _y);
//         _asset.health = _newHealth;
//         emit AssetHit(_x, _y);
//     }

//     /*//////////////////////////////////////////////////////////////////////
//                                 PLACE/UNPLACE
//     //////////////////////////////////////////////////////////////////////*/

//     //dont allow to put defence around boundary since thats where attacks will be placed
//     //dont allow to put attack anywhere except boundary
//     //make sure its within boundary
//     //if attacker true then check attacker conditions
//     function checkPlacementCondition(
//         uint256 _x,
//         uint256 _y,
//         bool attacker
//     ) public view {
//         //if health 0 then nothing placed
//         Asset memory _asset = getAsset(_x, _y);
//         require(_asset.health == 0, "no");
//         if (attacker) {
//             require(_x == 0 || _y == 0 || _x == x || _y == y, "no");
//         } else {
//             require(_x != 0 && _y != 0 && _x < x && _y < y, "no");
//         }
//     }

//     function place(
//         uint256 _x,
//         uint256 _y,
//         bool attacker,
//         address _owner,
//         address assetContract,
//         uint256 health,
//         uint256 assetId
//     ) public gameNotStarted whitelisted {
//         checkPlacementCondition(_x, _y, attacker);
//         assets[getHash(_x, _y)] = Asset(attacker, _owner, assetContract, health, assetId);
//         emit AssetPlaced(_x, _y);
//     }

//     function placeGenerator(
//         uint256 _x,
//         uint256 _y,
//         bool attacker,
//         address _owner,
//         address assetContract,
//         uint256 health,
//         uint256 assetId
//     ) public gameNotStarted whitelisted {
//         place(_x, _y, attacker, _owner, assetContract, health, assetId);
//         isGenerator[getHash(_x, _y)] = true;
//     }

//     //remove from assets
//     function unplace(uint256 _x, uint256 _y) public gameNotStarted whitelisted {
//         delete assets[getHash(_x, _y)];
//         emit AssetUnplaced(_x, _y);
//     }

//     /*//////////////////////////////////////////////////////////////////////
//                                     UTILS
//     //////////////////////////////////////////////////////////////////////*/

//     function getHash(uint256 _x, uint256 _y) public pure returns (bytes32) {
//         return keccak256(abi.encodePacked(_x, _y));
//     }

//     function getAsset(uint256 _x, uint256 _y) public view returns (Asset memory) {
//         return assets[getHash(_x, _y)];
//     }

//     //if castle health == 0 or all attackers dead then stop game
//     function continueGame() public {
//         uint256 _x = (x + 1) / 2;
//         uint256 _y = (y + 1) / 2;
//         Asset memory _asset = getAsset(_x, _y);
//         if (_asset.health == 0) emit GameEnd();
//     }

//    

//     /*//////////////////////////////////////////////////////////////////////
//                             BEFORE AND AFTER
//     //////////////////////////////////////////////////////////////////////*/

//     //call from bot
//     function updateAttackers() public gameStarted whitelisted {}

//     //check if castl health more than 0 or attackers alive
//     function continueGame() public gameStarted whitelisted {}

//     /*//////////////////////////////////////////////////////////////////////
//                                 READ BOARD
//     //////////////////////////////////////////////////////////////////////*/
// }


//