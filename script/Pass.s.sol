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
    BattlePass pass = BattlePass(0x7Fe677f2CbD414F8E8e963a88d1dDaCD4fc033bd);

    function newBattlePass() public {
        address crafting;
        address game;
        address creatorTokenCtr;
        string memory uri;
        vm.startBroadcast();
        pass = new BattlePass(uri, crafting, game, creatorTokenCtr);
    }

    function giveXp() public {
        uint256 xp = 10000;

        vm.startBroadcast();
        // pass.giveXp(_seasonId, xp, 0x38F9Afe17Cf6F73895D064fBee74b2bA02ff7982);
        // pass.giveXp(_seasonId, xp, 0x04405FE47BFA78306E67bAc1C3914de229b54192);
        // pass.giveXp(_seasonId, xp, 0x15fF62427589165189B2eD3d4FF6C7455b326E45);
        pass.giveXp(pass.seasonId(), xp, 0xC595774F11548C577341297Fc1216Ed7E8215355);
    }

    function newSeason() public {
        LevelInfo[] memory levels = new LevelInfo[](11);
        levels[0].xpToCompleteLevel = 10;

        levels[1].xpToCompleteLevel = 200;
        levels[1].freeRewardId = 10007;
        levels[1].freeRewardQty = 1;
        levels[1].premiumRewardId = 10000;
        levels[1].premiumRewardQty = 1;

        levels[2].xpToCompleteLevel = 200;
        levels[2].freeRewardId = 1001;
        levels[2].freeRewardQty = 1;
        levels[2].premiumRewardId = 10007;
        levels[2].premiumRewardQty = 1;

        levels[3].xpToCompleteLevel = 300;
        levels[3].freeRewardId = 10004;
        levels[3].freeRewardQty = 1;
        levels[3].premiumRewardId = 1001;
        levels[3].premiumRewardQty = 1;

        levels[4].xpToCompleteLevel = 400;
        levels[4].freeRewardId = 10009;
        levels[4].freeRewardQty = 1;
        levels[4].premiumRewardId = 10003;
        levels[4].premiumRewardQty = 1;

        levels[5].xpToCompleteLevel = 500;
        levels[5].freeRewardId = 1001;
        levels[5].freeRewardQty = 1;
        levels[5].premiumRewardId = 10005;
        levels[5].premiumRewardQty = 1;

        levels[6].xpToCompleteLevel = 700;
        levels[6].freeRewardId = 1001;
        levels[6].freeRewardQty = 1;
        levels[6].premiumRewardId = 10001;
        levels[6].premiumRewardQty = 1;

        levels[7].xpToCompleteLevel = 1000;
        levels[7].freeRewardId = 10003;
        levels[7].freeRewardQty = 1;
        levels[7].premiumRewardId = 10006;
        levels[7].premiumRewardQty = 1;

        levels[8].xpToCompleteLevel = 1000;
        levels[8].freeRewardId = 1001;
        levels[8].freeRewardQty = 1;
        levels[8].premiumRewardId = 10002;
        levels[8].premiumRewardQty = 1;

        levels[9].xpToCompleteLevel = 1135;
        levels[9].freeRewardId = 10006;
        levels[9].freeRewardQty = 1;
        levels[9].premiumRewardId = 1001;
        levels[9].premiumRewardQty = 1;

        levels[10].xpToCompleteLevel = 0;
        levels[10].freeRewardId = 10000;
        levels[10].freeRewardQty = 1;
        levels[10].premiumRewardId = 10008;
        levels[10].premiumRewardQty = 1;

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
        pass.setURI("ipfs://QmQtjuBDwLLgSVW9nC1VezQZ5jB2BZTN94NkmDKmEq9ZfZ");
    }

    function newLootbox() public {
        LootboxOption[] memory options = new LootboxOption[](12);
        options[0].rarityRange[0] = 0;
        options[0].rarityRange[1] = 5;
        uint256[] memory x = new uint256[](1);
        x[0] = 10000;
        options[0].ids = x;
        x = new uint256[](1);
        x[0] = 1;
        options[0].qtys = x;

        options[1].rarityRange[0] = 5;
        options[1].rarityRange[1] = 10;
        x = new uint256[](1);
        x[0] = 10002;
        options[1].ids = x;
        x = new uint256[](1);
        x[0] = 1;
        options[1].qtys = x;

        options[2].rarityRange[0] = 10;
        options[2].rarityRange[1] = 15;
        x = new uint256[](1);
        x[0] = 10003;
        options[2].ids = x;
        x = new uint256[](1);
        x[0] = 1;
        options[2].qtys = x;

        options[3].rarityRange[0] = 15;
        options[3].rarityRange[1] = 20;
        x = new uint256[](1);
        x[0] = 10004;
        options[3].ids = x;
        x = new uint256[](1);
        x[0] = 1;
        options[3].qtys = x;

        options[4].rarityRange[0] = 20;
        options[4].rarityRange[1] = 30;
        x = new uint256[](1);
        x[0] = 10005;
        options[4].ids = x;
        x = new uint256[](1);
        x[0] = 1;
        options[4].qtys = x;

        options[5].rarityRange[0] = 30;
        options[5].rarityRange[1] = 45;
        x = new uint256[](1);
        x[0] = 10006;
        options[5].ids = x;
        x = new uint256[](1);
        x[0] = 1;
        options[5].qtys = x;

        options[6].rarityRange[0] = 45;
        options[6].rarityRange[1] = 55;
        x = new uint256[](1);
        x[0] = 10007;
        options[6].ids = x;
        x = new uint256[](1);
        x[0] = 1;
        options[6].qtys = x;

        options[7].rarityRange[0] = 55;
        options[7].rarityRange[1] = 65;
        x = new uint256[](1);
        x[0] = 10008;
        options[7].ids = x;
        x = new uint256[](1);
        x[0] = 1;
        options[7].qtys = x;

        options[8].rarityRange[0] = 65;
        options[8].rarityRange[1] = 75;
        x = new uint256[](1);
        x[0] = 10009;
        options[8].ids = x;
        x = new uint256[](1);
        x[0] = 1;
        options[8].qtys = x;

        options[9].rarityRange[0] = 75;
        options[9].rarityRange[1] = 85;
        x = new uint256[](1);
        x[0] = 10010;
        options[9].ids = x;
        x = new uint256[](1);
        x[0] = 1;
        options[9].qtys = x;

        options[10].rarityRange[0] = 85;
        options[10].rarityRange[1] = 95;
        x = new uint256[](1);
        x[0] = 10011;
        options[10].ids = x;
        x = new uint256[](1);
        x[0] = 1;
        options[10].qtys = x;

        options[11].rarityRange[0] = 95;
        options[11].rarityRange[1] = 100;
        x = new uint256[](1);
        x[0] = 10012;
        options[11].ids = x;
        x = new uint256[](1);
        x[0] = 1;
        options[11].qtys = x;

        vm.startBroadcast();
        uint256 lootboxId = pass.newLootbox(options);
        console.log(lootboxId);
    }
}
