// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "../src/battle-pass/BattlePass.sol";
import "../src/battle-pass/CreatorToken.sol";

//deploy pass
//new lootbox if any
//new season
//deploy token
//set token in pass
contract PassScript is Script {
    BattlePass pass = BattlePass(0x8d8631397A54d277E3b3F545D2b2c828e0074638);

    function newBattlePass() public {
        address crafting;
        address game;
        address creatorTokenCtr;
        string memory uri;
        vm.startBroadcast();
        pass = new BattlePass(uri, crafting, game, creatorTokenCtr);
    }

    function giveXp() public {
        uint256 _seasonId = 1;
        uint256 xp = 1000;
        address user = 0x4B59801376C1fCE0ab8E5d1F7de44E89FAAB07b0;
        //me:
        //rama:0x04405FE47BFA78306E67bAc1C3914de229b54192
        //zach:0x15fF62427589165189B2eD3d4FF6C7455b326E45;
        vm.startBroadcast();
        pass.giveXp(_seasonId, xp, user);
    }

    function newSeason() public {
        LevelInfo[] memory levels = new LevelInfo[](3);
        levels[0].xpToCompleteLevel = 175;
        levels[0].freeRewardId = 1001;
        levels[0].freeRewardQty = 2;
        levels[0].premiumRewardId = 10000;
        levels[0].premiumRewardQty = 10;

        levels[1].xpToCompleteLevel = 200;
        levels[1].freeRewardId = 1001;
        levels[1].freeRewardQty = 10;
        levels[1].premiumRewardId = 10000;
        levels[1].premiumRewardQty = 2;

        levels[2].xpToCompleteLevel = 0;
        levels[2].freeRewardId = 10000;
        levels[2].freeRewardQty = 20;
        levels[2].premiumRewardId = 1001;
        levels[2].premiumRewardQty = 1;

        vm.startBroadcast();
        uint256 seasonId = pass.newSeason(levels);
        console.log(seasonId);
    }

    function changeReward() public {
        vm.startBroadcast();
        pass.addReward(1, 5, false, 10000, 5);
        pass.addReward(1, 6, false, 10000, 5);
        pass.addReward(1, 7, false, 10000, 5);
    }

    function newCreatorToken() public {
        vm.startBroadcast();
        CreatorToken token = new CreatorToken("HELOO", "H", 18, address(pass));
    }

    function setCreatorToken() public {
        vm.startBroadcast();
        pass.setCreatorTokenCtr(0x1612835E37cA75d8c5Ec97246af6136fd081a886);
    }

    function toggleWhitelist() public {
        bool toggle = true;
        address grant;

        vm.startBroadcast();
        pass.togglewhitelisted(grant, toggle);
    }

    function setURI() public {
        vm.startBroadcast();
        pass.setURI("ipfs://QmVzGmSUwQdv7seqdXRoWdHYC4fJbjahdiTE9rjCb7qjz7");
    }

    function newLootbox() public {
        LootboxOption[] memory options = new LootboxOption[](1);
        options[0].rarityRange[0] = 0;
        options[0].rarityRange[1] = 10;
        uint256[] memory x = new uint256[](1);
        x[0] = 1;
        options[0].ids = x;
        x = new uint256[](1);
        x[0] = 1;
        options[0].qtys = x;

        vm.startBroadcast();
        uint256 lootboxId = pass.newLootbox(options);
        console.log(lootboxId);
    }
}
