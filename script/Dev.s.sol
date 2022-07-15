// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "../src/misc/SoupcansNFT.sol";

contract DevScript is Script {
    SoupcansNFT token;

    function run() public {
        vm.startBroadcast();
        // token = new SoupcansNFT("ipfs://QmdFYm5TLuBDKgMXKt8zVem2LNQiUGyCgrmxf5F9zRYntL/");
        token = SoupcansNFT(payable(0x1BdcA566E7097E4b45e82d3BC6298ADefD537245));
        //mint private
        token.mintForAuction();
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
