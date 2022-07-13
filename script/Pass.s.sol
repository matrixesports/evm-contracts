// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "../src/battle-pass/BattlePass.sol";

contract PassScript is Script {
    BattlePass pass;

    function newBattlePass() public {
        address crafting;
        address game;
        address creatorTokenCtr;
        string memory uri;
        vm.startBroadcast();
        pass = new BattlePass(uri, crafting, game, creatorTokenCtr);
    }

    function giveXp() public {
        uint256 _seasonId;
        uint256 xp;
        address user;
        vm.startBroadcast();
        pass = BattlePass(address(1));
        pass.giveXp(_seasonId, xp, user);
    }

    function newSeason() public {
        LevelInfo[] memory levels = new LevelInfo[](11);
        levels[0].xpToCompleteLevel;
        levels[0].freeRewardId;
        levels[0].freeRewardQty;
        levels[0].premiumRewardId;
        levels[0].premiumRewardQty;

        levels[1].xpToCompleteLevel;
        levels[1].freeRewardId;
        levels[1].freeRewardQty;
        levels[1].premiumRewardId;
        levels[1].premiumRewardQty;

        levels[2].xpToCompleteLevel;
        levels[2].freeRewardId;
        levels[2].freeRewardQty;
        levels[2].premiumRewardId;
        levels[2].premiumRewardQty;

        levels[3].xpToCompleteLevel;
        levels[3].freeRewardId;
        levels[3].freeRewardQty;
        levels[3].premiumRewardId;
        levels[3].premiumRewardQty;

        levels[4].xpToCompleteLevel;
        levels[4].freeRewardId;
        levels[4].freeRewardQty;
        levels[4].premiumRewardId;
        levels[4].premiumRewardQty;

        levels[5].xpToCompleteLevel;
        levels[5].freeRewardId;
        levels[5].freeRewardQty;
        levels[5].premiumRewardId;
        levels[5].premiumRewardQty;

        levels[6].xpToCompleteLevel;
        levels[6].freeRewardId;
        levels[6].freeRewardQty;
        levels[6].premiumRewardId;
        levels[6].premiumRewardQty;

        levels[7].xpToCompleteLevel;
        levels[7].freeRewardId;
        levels[7].freeRewardQty;
        levels[7].premiumRewardId;
        levels[7].premiumRewardQty;

        levels[8].xpToCompleteLevel;
        levels[8].freeRewardId;
        levels[8].freeRewardQty;
        levels[8].premiumRewardId;
        levels[8].premiumRewardQty;

        levels[9].xpToCompleteLevel;
        levels[9].freeRewardId;
        levels[9].freeRewardQty;
        levels[9].premiumRewardId;
        levels[9].premiumRewardQty;

        levels[10].xpToCompleteLevel = 0;
        levels[10].freeRewardId;
        levels[10].freeRewardQty;
        levels[10].premiumRewardId;
        levels[10].premiumRewardQty;

        pass = BattlePass(address(1));
        vm.startBroadcast();
        uint256 seasonId = pass.newSeason(levels);
        console.log(seasonId);
    }

    function setCreatorToken() public {
        address newToken;
        pass = BattlePass(address(1));
        vm.startBroadcast();
        pass.setCreatorTokenCtr(newToken);
    }

    function toggleWhitelist() public {
        bool toggle;
        address grant;
        pass = BattlePass(address(1));
        vm.startBroadcast();
        pass.togglewhitelisted(grant, toggle);
    }

    function setURI() public {
        string memory newURI;
        pass = BattlePass(address(1));
        vm.startBroadcast();
        pass.setURI(newURI);
    }

    function newLootbox() public {
        LootboxOption[] memory options = new LootboxOption[](5);
        options[0].rarityRange[0];
        options[0].rarityRange[1];
        uint256[] memory x = new uint256[](2);
        options[0].ids = x;
        x = new uint256[](2);
        options[0].qtys = x;

        options[1].rarityRange[0];
        options[1].rarityRange[1];
        x = new uint256[](2);
        options[1].ids = x;
        x = new uint256[](2);
        options[1].qtys = x;

        options[2].rarityRange[0];
        options[2].rarityRange[1];
        x = new uint256[](2);
        options[2].ids = x;
        x = new uint256[](2);
        options[2].qtys = x;

        options[3].rarityRange[0];
        options[3].rarityRange[1];
        x = new uint256[](2);
        options[3].ids = x;
        x = new uint256[](2);
        options[3].qtys = x;

        options[4].rarityRange[0];
        options[4].rarityRange[1];
        x = new uint256[](2);
        options[4].ids = x;
        x = new uint256[](2);
        options[4].qtys = x;

        pass = BattlePass(address(1));
        vm.startBroadcast();
        uint256 lootboxId = pass.newLootbox(options);
        console.log(lootboxId);
    }
}
