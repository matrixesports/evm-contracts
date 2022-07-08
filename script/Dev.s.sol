// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "../src/soupcans/SoupcansNFT.sol";

contract DevScript is Script {
    SoupcansNFT token;

    function run() public {
        vm.startBroadcast();
        //deploy
        token = new SoupcansNFT("QmeV7Jn8A5wYmXK7XhM9uoQtJrj98Dk1stNijKUPMEyVs8");

        // token = SoupcansNFT();
        //set uri
        //in wei
        // token.setPrice(1);

        //toggle auction
        // token.toggleMint(true);

        //mint private
        // token.mintForAuction();
    }
}
