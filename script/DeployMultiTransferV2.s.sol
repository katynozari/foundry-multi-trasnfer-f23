// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "../src/MultiTransferV2.sol";

contract DeployMultiTransferV2 is Script {
    function run() external returns (MultiTransferV2) {
        vm.startBroadcast();
        MultiTransferV2 multiTransfer = new MultiTransferV2();
        vm.stopBroadcast();
        return multiTransfer;
    }
}
