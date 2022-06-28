// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "../src/Pass.sol";
import "../src/Recipe.sol";
import "../src/rewards/Redeemable.sol";

/**
do dev stuff
run:
source .env &&
forge script script/Dev.s.sol:DevScript --rpc-url $POLYGON_RPC --private-key $PVT_KEY --broadcast --legacy
 */

contract DevScript is Script {
    LevelInfo[] levels;
    uint256 creator_id = 0;
    Pass pass;

    function run() public {
        vm.startBroadcast();
        pass = Pass(0x64dA27372168b38ab1bbFb566Cc5267316337582);
        LevelInfo memory level;

        level.xpToCompleteLevel = 100;
        levels.push(level);

        level.xpToCompleteLevel = 100;
        level.freeReward = ERC1155Reward(0x3AAEdc8bd6d6Fd4Ed436d1a23883Ae2Fd2B4ABEa, 1, 1);
        levels.push(level);

        level.xpToCompleteLevel = 100;
        level.freeReward = ERC1155Reward(0x3AAEdc8bd6d6Fd4Ed436d1a23883Ae2Fd2B4ABEa, 2, 1);
        levels.push(level);

        level.xpToCompleteLevel = 200;
        level.freeReward = ERC1155Reward(0x3AAEdc8bd6d6Fd4Ed436d1a23883Ae2Fd2B4ABEa, 3, 1);
        levels.push(level);

        level.xpToCompleteLevel = 200;
        level.freeReward = ERC1155Reward(0x3AAEdc8bd6d6Fd4Ed436d1a23883Ae2Fd2B4ABEa, 5, 1);
        levels.push(level);

        level.xpToCompleteLevel = 200;
        level.freeReward = ERC1155Reward(0x3AAEdc8bd6d6Fd4Ed436d1a23883Ae2Fd2B4ABEa, 6, 1);
        levels.push(level);

        level.xpToCompleteLevel = 300;
        level.freeReward = ERC1155Reward(0x3AAEdc8bd6d6Fd4Ed436d1a23883Ae2Fd2B4ABEa, 7, 1);
        levels.push(level);

        level.xpToCompleteLevel = 300;
        level.freeReward = ERC1155Reward(0x3AAEdc8bd6d6Fd4Ed436d1a23883Ae2Fd2B4ABEa, 8, 1);
        levels.push(level);

        level.xpToCompleteLevel = 300;
        level.freeReward = ERC1155Reward(0x3AAEdc8bd6d6Fd4Ed436d1a23883Ae2Fd2B4ABEa, 9, 1);
        levels.push(level);

        level.xpToCompleteLevel = 400;
        level.freeReward = ERC1155Reward(0x3AAEdc8bd6d6Fd4Ed436d1a23883Ae2Fd2B4ABEa, 10, 1);
        levels.push(level);

        level.xpToCompleteLevel = 0;
        level.freeReward = ERC1155Reward(0x3AAEdc8bd6d6Fd4Ed436d1a23883Ae2Fd2B4ABEa, 11, 1);
        levels.push(level);

        uint256 seasonId = pass.newSeason(10, levels);
        // =MERC1155(0x2f7Bcde61c87b255a26E9db906b765E68Ea93FB2)
    }
}
