// // SPDX-License-Identifier: MIT
// pragma solidity >=0.8.0;

// /**
// from wikipedia: 
// Presented as one of the most powerful known mystical entities within the Marvel Universe,
// Dormammu is acknowledged by Doctor Strange as his "most terrible foe";
// a threat to "the life of the universe itself",
// that "at full power no one could stand against." 

// @notice destroyer of villages; feed it creator village to attack, and it'll go ham
// @dev 
// - prep by init units
// - specify board positions
// - call attack
// - enjoy
// */
// contract Dormammu {
//     address gameMaster;

//     modifier onlyGameMaster() {
//         require(msg.sender == gameMaster, "no");
//         _;
//     }

//     constructor() {
//         gameMaster = msg.sender;
//     }

//     /**
//     @dev prep for attack by giving units to attack
//     @param village address to attack
//      */
//     function prepAttack(address village) public onlyOwner {}

//     /**
//     each time its called in the end compute optimal position/action for next block given current position of units
//     */
//     function attack(address village) public onlyOwner {}
// }
