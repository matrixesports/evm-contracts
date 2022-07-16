// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "../src/battle-pass/BattlePass.sol";
import "../src/battle-pass/CreatorToken.sol";

//deploy pass
//new season
//new lootbox if any
//deploy token
//set token in pass

//xp
contract PassScript is Script {
    BattlePass pass = BattlePass(0x0cd2EC07524fFbF80334304101C7bD34886A286a);

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
        uint256 xp = 5610;
        address user = 0x15fF62427589165189B2eD3d4FF6C7455b326E45;
        //me:
        //rama:0x04405FE47BFA78306E67bAc1C3914de229b54192
        //zach:0x15fF62427589165189B2eD3d4FF6C7455b326E45;
        vm.startBroadcast();
        pass.giveXp(_seasonId, xp, user);
    }

    function newSeason() public {
        LevelInfo[] memory levels = new LevelInfo[](10);
        levels[0].xpToCompleteLevel = 175;
        levels[0].freeRewardId = 1;
        levels[0].freeRewardQty = 2;
        levels[0].premiumRewardId = 1000;
        levels[0].premiumRewardQty = 10;

        levels[1].xpToCompleteLevel = 200;
        levels[1].freeRewardId = 1002;
        levels[1].freeRewardQty = 1;
        levels[1].premiumRewardId = 10000;
        levels[1].premiumRewardQty = 2;

        levels[2].xpToCompleteLevel = 200;
        levels[2].freeRewardId = 20000;
        levels[2].freeRewardQty = 1;
        levels[2].premiumRewardId = 20101;
        levels[2].premiumRewardQty = 1;

        levels[3].xpToCompleteLevel = 300;
        levels[3].freeRewardId = 1;
        levels[3].freeRewardQty = 1;
        levels[3].premiumRewardId = 1000;
        levels[3].premiumRewardQty = 10;

        levels[4].xpToCompleteLevel = 500;
        levels[4].freeRewardId = 1;
        levels[4].freeRewardQty = 1;
        levels[4].premiumRewardId = 1000;
        levels[4].premiumRewardQty = 10;

        levels[5].xpToCompleteLevel = 700;
        levels[5].freeRewardId = 1002;
        levels[5].freeRewardQty = 1;
        levels[5].premiumRewardId = 1;
        levels[5].premiumRewardQty = 1;

        levels[6].xpToCompleteLevel = 1000;
        levels[6].freeRewardId = 1000;
        levels[6].freeRewardQty = 1;
        levels[6].premiumRewardId = 1;
        levels[6].premiumRewardQty = 1;

        levels[7].xpToCompleteLevel = 1000;
        levels[7].freeRewardId = 1;
        levels[7].freeRewardQty = 1;
        levels[7].premiumRewardId = 1;
        levels[7].premiumRewardQty = 1;

        levels[8].xpToCompleteLevel = 1135;
        levels[8].freeRewardId = 1;
        levels[8].freeRewardQty = 1;
        levels[8].premiumRewardId = 1;
        levels[8].premiumRewardQty = 1;

        levels[9].xpToCompleteLevel = 0;
        levels[9].freeRewardId = 1;
        levels[9].freeRewardQty = 1;
        levels[9].premiumRewardId = 1;
        levels[9].premiumRewardQty = 1;

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
        LootboxOption[] memory options = new LootboxOption[](2);
        options[0].rarityRange[0] = 0;
        options[0].rarityRange[1] = 5;
        uint256[] memory x = new uint256[](1);
        x[0] = 1;
        options[0].ids = x;
        x = new uint256[](1);
        x[0] = 1;
        options[0].qtys = x;

        options[1].rarityRange[0] = 5;
        options[1].rarityRange[1] = 10;
        x = new uint256[](1);
        x[0] = 1000;
        options[1].ids = x;
        x = new uint256[](1);
        x[0] = 1000;
        options[1].qtys = x;

        vm.startBroadcast();
        uint256 lootboxId = pass.newLootbox(options);
        console.log(lootboxId);
    }
}
