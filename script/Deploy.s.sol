// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, stdJson} from "forge-std/Script.sol";

import "./Base.s.sol";

contract DeployScript is BaseScript {
    using stdJson for string;

    function run() public {
        vm.startBroadcast(deployer);

//        RedeemableCard card = RedeemableCard(deploy("RedeemableCard.sol", abi.encode(deployer), false));
//        ConsumableProvider provider = ConsumableProvider(deploy("ConsumableProvider.sol", abi.encode(deployer)));
//
//        for (uint256 i = 0; i < config.signers.length; i++) {
//            address signer = config.signers[i];
//            manager.grantRole(manager.API_SIGNER_ROLE(), signer);
//        }
//
//        manager.grantRole(manager.DEFAULT_ADMIN_ROLE(), config.admin);
//        manager.renounceRole(manager.DEFAULT_ADMIN_ROLE(), deployer);

        vm.stopBroadcast();
    }
}
