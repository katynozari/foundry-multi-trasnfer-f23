// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "../src/MultiTransfer.sol";

contract DeployMultiTransfer is Script {
    function run() external returns (MultiTransfer) {
        vm.startBroadcast();
        MultiTransfer multiTransfer = new MultiTransfer();
        vm.stopBroadcast();
        return multiTransfer;
    }
}
