// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "../src/misc/SoupcansNFT.sol";
import "../src/battle-pass/BattlePass.sol";

contract DevScript is Script {
    SoupcansNFT token;
    BattlePass pass;

    address crafting;

    /// @dev need new token, game, existing recipe
    function newCreator() public {
        // pass = new BattlePass();
    }

    function dev() public {
        vm.startBroadcast();
        //deploy
        // token = new SoupcansNFT("ipfs://QmXuU6EZhyYm2BBSZUxSzy4Lb3Xao2rMJDrsLYYGFW81Ke/");
        // token = SoupcansNFT(payable(0xb26399045F22bD6a30e28F15b2018D3dB7Dd0fEC));

        // pass = new BattlePass(
        //     "ipfs://QmNXxtwjDVmyGL9Ko5Qa7QYRf7sqWm5KGZsCjGmMqvk3En",
        //     address(0),
        //     address(0),
        //     address(0)
        // );

        pass = BattlePass(0xD4049fc1eeaeaAE7BD8cC3425fCC510e05E63A23);
        // pass.giveXp(1, 20, 0x136E461a56dDA46A1fbA60e773799A797f8C4395);
        // LevelInfo[] memory levelInfo = new LevelInfo[](2);
        // levelInfo[0].xpToCompleteLevel = 10;
        // levelInfo[0].freeRewardId = 1;
        // levelInfo[0].freeRewardQty = 1;
        // levelInfo[0].premiumRewardId = 10_000;
        // levelInfo[0].premiumRewardQty = 1;

        // levelInfo[1].xpToCompleteLevel = 0;
        // levelInfo[0].freeRewardId = 20_000;
        // levelInfo[0].freeRewardQty = 1;
        // levelInfo[0].premiumRewardId = 20_001;
        // levelInfo[0].premiumRewardQty = 1;

        console.log(pass.seasonId());

        //rinklebny
        // address rinkeby_address = 0x4612B82ca1650ed0982B40eB919abe812AdD48C8;
        // token = SoupcansNFT(payable(rinkeby_address));
        //set price
        //in wei
        // token.setPrice(1);

        //toggle auction
        // token.toggleMint(true);

        //mint private
        // token.mintForAuction();
        // token.mintForAuction();
        // token.mintForAuction();
        // token.mintForAuction();
        // token.mintForAuction();
        // token.setBaseTokenURI("ipfs://QmXuU6EZhyYm2BBSZUxSzy4Lb3Xao2rMJDrsLYYGFW81Ke/");
        // console.log(token.tokenURI(1));
    }
}
