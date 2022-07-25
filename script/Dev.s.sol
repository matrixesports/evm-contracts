// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "../src/misc/SoupcansNFT.sol";
import "../src/battle-pass/BattlePass.sol";

contract DevScript is Script {
    SoupcansNFT token;

    function run() public {
        vm.startBroadcast();
        BattlePass pass = BattlePass(0x7Fe677f2CbD414F8E8e963a88d1dDaCD4fc033bd);
        pass.mint(0x136E461a56dDA46A1fbA60e773799A797f8C4395, pass.seasonId(), 1);

        // // token = new SoupcansNFT("ipfs://Qmd5fxbqFVwSMEvwW3fDCgpeNAd7zvoaWNi37Xd7AvDbLN/");
        // token = SoupcansNFT(payable(0xA3BA0b27cfC458eeEd970E71AEa9C51C1c56CFd2));
        // //mint private
        // token.mintForAuction();
        // token.mintForAuction();
        // token.mintForAuction();
        // token.mintForAuction();
        // token.mintForAuction();
        // token.mintForAuction();
        // token.mintForAuction();
        // token.mintForAuction();
        // token.mintForAuction();
        // token.mintForAuction();
    }
}
