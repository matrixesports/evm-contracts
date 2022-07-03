

// contract Engine {
//     ///@dev share storage with Board and have it delegate call this
//     mapping(uint256 => mapping(uint256 => Asset)) public assets;

//     ///@dev convenience var to check how many attackers there are,
//     ///dont want to loop through the grid
//     uint256 public attackerCount;

//     ///@dev number of ticks
//     uint256 public count;

//     ///@notice FE will call action for all grid elements,
//     ///then call move which will only move attackers
//     ///then check with continueGame if it should continue the game
//     //FE doesnt need to be aware of whats at x,y
//     //just needs to call it and contract will figure it out
//     //dont want to loop over it coz of memeory issues
//     //+ want to introduce randomness through tx ordereing
//     //will call this function for all x,y
//     ///@dev ignore if castle or dead
//     function action(uint256 _x, uint256 _y) public {
//         Asset memory _asset = assets[_x][_y];
//         uint256 id = _asset.id;
//         if (_asset.isAttacker) {
//             if (id == meleeId) {
//                 attackMelee(_x, _y, _asset);
//             } else if (id == rangedId) {
//                 attackRanged(_x, _y, _asset);
//             } else if (id == explosiveId) {
//                 attackExplosive(_x, _y, _asset);
//             } else {
//                 revert How(id);
//             }
//         } else {
//             if (id == castleId || id == wallId) {} else if (id == turretId) {
//                 defendTurret(_x, _y, _asset);
//             } else if (id == bomberId) {
//                 defendBomber(_x, _y, _asset);
//             } else if (id == generatorId) {
//                 defendGenerator(_x, _y, _asset);
//             } else {
//                 revert How(id);
//             }
//         }
//     }

//     /// @dev calculate max x,y coordinates within range, dont want it to overflow beytond range
//     /// @param _x x coordinate
//     /// @param _y y coordinate
//     /// @param range range of asset
//     /// @return x_range adjusted x range
//     /// @return y_range adjusted y range
//     function adjustRange(
//         uint256 _x,
//         uint256 _y,
//         uint256 range
//     ) public view returns (uint256 x_range, uint256 y_range) {
//         x_range = _x + range;
//         if (x_range > x) x_range = x;
//         y_range = _y + range;
//         if (y_range > y) y_range = y;
//     }

//     /// @notice find attacker/defender in range of _x and _y
//     /// @dev skip over assets with health == 0
//     /// @param _x x coordinate of asset
//     /// @param _y y coordinate of asset
//     /// @param range range of asset
//     /// @param isAttacker true if asset is looking for attacker, false if looking for a defender
//     /// @param findAll true if want to find all attackers/defenders
//     /// @return xFound x coordinate of all found
//     /// @return yFound y coordinate of all found
//     /// @return health health of asset of all found
//     function find(
//         uint256 _x,
//         uint256 _y,
//         uint256 range,
//         bool isAttacker
//     )
//         public
//         view
//         returns (
//             uint256 xFound,
//             uint256 yFound,
//             uint256 health
//         )
//     {
//         (uint256 x_range, uint256 y_range) = adjustRange(_x, _y, range);

//         for (uint256 a = _x; a <= x_range; a++) {
//             for (uint256 b = _y; b <= y_range; b++) {
//                 Asset memory _asset = assets[a][b];
//                 if (_asset.health == 0) continue;
//                 if (isAttacker) {
//                     if (!_asset.isAttacker) continue;
//                 } else {
//                     if (_asset.isAttacker) continue;
//                 }
//                 xFound[found] = a;
//                 yFound[found] = b;
//                 health[found] = _asset.health;
//                 found++;
//                 // if (foundAll)
//             }
//         }
//         return (xFound, yFound, health);
//     }
// )

//     function findAll(
//         uint256 _x,
//         uint256 _y,
//         uint256 range,
//         bool isAttacker
//     )
//         public
//         view
//         returns (
//             uint256[] memory xFound,
//             uint256[] memory yFound,
//             uint256[] memory health
//         )
//     {
//         (uint256 x_range, uint256 y_range) = adjustRange(_x, _y, range);
//         xFound = new uint256[]((x_range * y_range) + 1);
//         yFound = new uint256[]((x_range * y_range) + 1);
//         health = new uint256[]((x_range * y_range) + 1);
//         uint256 found;
//     }

//     function defend() public {}

//     function attack() public {}

//     function defendTurret(
//         uint256 _x,
//         uint256 _y,
//         Asset memory _asset
//     ) public {}

//     function defendBomber(
//         uint256 _x,
//         uint256 _y,
//         Asset memory _asset
//     ) public {}

//     function defendGenerator(
//         uint256 _x,
//         uint256 _y,
//         Asset memory _asset
//     ) public {}

//     function attackMelee(
//         uint256 _x,
//         uint256 _y,
//         Asset memory _asset
//     ) public {}

//     function attackRanged(
//         uint256 _x,
//         uint256 _y,
//         Asset memory _asset
//     ) public {}

//     function attackExplosive(
//         uint256 _x,
//         uint256 _y,
//         Asset memory _asset
//     ) public {}

//     ///@dev same thing as above but it checks for attacking units
//     function move(uint256 _x, uint256 _y) public {}

//     ///@dev continue game only if there are attackers that are alive or castle health is > 0
//     function continueGame() public {}
// }
