// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "../src/misc/SoupcansNFT.sol";

contract DevScript is Script {
    SoupcansNFT token;

    function run() public {
        vm.startBroadcast();
        // token = new SoupcansNFT("ipfs://Qmd5fxbqFVwSMEvwW3fDCgpeNAd7zvoaWNi37Xd7AvDbLN/");
        token = SoupcansNFT(payable(0xA3BA0b27cfC458eeEd970E71AEa9C51C1c56CFd2));
        //mint private
        token.mintForAuction();
        token.mintForAuction();
        token.mintForAuction();
        token.mintForAuction();
        token.mintForAuction();
        token.mintForAuction();
        token.mintForAuction();
        token.mintForAuction();
        token.mintForAuction();
        token.mintForAuction();
    }
}
