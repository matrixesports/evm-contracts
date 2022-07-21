// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "../src/misc/SoupcansNFT.sol";
import "../src/battle-pass/BattlePass.sol";

contract DevScript is Script {
    SoupcansNFT token;

    function run() public {
        vm.startBroadcast();
        BattlePass pass = BattlePass(0x8d8631397A54d277E3b3F545D2b2c828e0074638);
        console.log(pass.getLootboxOptionsLength(1001));

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
