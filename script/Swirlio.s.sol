// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import {Swirlio} from "src/Swirlio.sol";

contract DeploySwirlio is Script {
    Swirlio swirlio;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        swirlio = new Swirlio();
        vm.stopBroadcast();
    }
}
