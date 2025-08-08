//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Raffle} from "src/Raffle.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function deployRaffle() private returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subId == 0) {
            CreateSubscription createsub = new CreateSubscription();
            (config.subId, config.vrfCoordinator) = createsub
                .createSubscription(config.vrfCoordinator, config.deployerKey);

            FundSubscription fundsub = new FundSubscription();
            fundsub.fundSubscription(
                config.vrfCoordinator,
                config.subId,
                config.link,
                config.deployerKey
            );
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.keyHash,
            config.subId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addconsumer = new AddConsumer();
        addconsumer.addConsumer(
            address(raffle),
            config.vrfCoordinator,
            config.subId,
            config.deployerKey
        );
        return (raffle, helperConfig);
    }

    function run() public returns (Raffle, HelperConfig) {
        return deployRaffle();
    }
}
