// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, stdJson} from "forge-std/Script.sol";

import "../src/AccountModule.sol";

contract DeployScript is Script {
    using stdJson for string;

    struct Config {
        address admin;
        address[] signers;
    }

    Config internal config;
    address deployer;

    constructor() {
        deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        loadConfig();
    }

    function run() public {
        vm.startBroadcast(deployer);

        AccountModule manager = new AccountModule{salt: 0}(deployer);

        for (uint256 i = 0; i < config.signers.length; i++) {
            address signer = config.signers[i];
            manager.grantRole(manager.API_SIGNER_ROLE(), signer);
        }

        manager.grantRole(manager.DEFAULT_ADMIN_ROLE(), config.admin);
        manager.renounceRole(manager.DEFAULT_ADMIN_ROLE(), deployer);

        vm.stopBroadcast();
    }

    function loadConfig() internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/config.json");
        string memory json = vm.readFile(path);

        Chain memory chain = getChain(block.chainid);
        string memory key = string.concat(".", chain.chainAlias);

        config.admin = json.readAddress(string.concat(key, ".admin"));

        address[] memory signers = json.readAddressArray(string.concat(key, ".signers"));
        for (uint256 i = 0; i < signers.length; i++) {
            config.signers.push(signers[i]);
        }
    }
}
