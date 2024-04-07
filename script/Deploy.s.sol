// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, stdJson} from "forge-std/Script.sol";

import "./Base.s.sol";

contract DeployScript is BaseScript {
    using stdJson for string;

    function run() public {
        vm.startBroadcast(deployer);

        deploy("TokenDistributor.sol", abi.encode(config.token, config.admin));

        vm.stopBroadcast();
    }
}
