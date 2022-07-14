// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "../src/misc/SoupcansNFT.sol";

contract DevScript is Script {
    SoupcansNFT token;

    function dev() public {
        vm.startBroadcast();
        token = new SoupcansNFT("ipfs://QmXuU6EZhyYm2BBSZUxSzy4Lb3Xao2rMJDrsLYYGFW81Ke/");

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
