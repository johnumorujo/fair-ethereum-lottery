//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2PlusMock} from "chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2PlusMock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 deployerKey = helperConfig.getConfig().deployerKey;
        (uint256 subsId, ) = createSubscription(vrfCoordinator, deployerKey);
        return (subsId, vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinator,
        uint256 deployerKey
    ) public returns (uint256, address) {
        console.log("creating subscription on chainId: ", block.chainid);
        vm.startBroadcast(deployerKey);
        uint256 subsId = VRFCoordinatorV2PlusMock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console.log("subscription created with subId: ", subsId);
        console.log("please update subscriptionId in HelperConfig!");
        return (subsId, vrfCoordinator);
    }

    function run() external returns (uint256, address) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 300 ether; // 3 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subId = helperConfig.getConfig().subId;
        address linkToken = helperConfig.getConfig().link;
        uint256 deployerKey = helperConfig.getConfig().deployerKey;
        fundSubscription(vrfCoordinator, subId, linkToken, deployerKey);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subId,
        address link,
        uint256 deployerKey
    ) public {
        console.log(
            "funding subscription %s with %s using %s",
            subId,
            FUND_AMOUNT,
            vrfCoordinator
        );

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2PlusMock(vrfCoordinator).fundSubscription(
                subId,
                uint96(FUND_AMOUNT) /////review
            );
            vm.stopBroadcast();
            console.log("funded subscription %s with %s", subId, FUND_AMOUNT);
        } else {
            vm.startBroadcast(deployerKey);
            LinkToken(link).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subId = helperConfig.getConfig().subId;
        uint256 deployerKey = helperConfig.getConfig().deployerKey;
        addConsumer(mostRecentlyDeployed, vrfCoordinator, subId, deployerKey);
    }

    function addConsumer(
        address contractToAddtoVrf,
        address vrfCoordinator,
        uint256 subId,
        uint256 deployerKey
    ) public {
        console.log(
            "adding consumer contract %s to %s on chainid %s",
            contractToAddtoVrf,
            vrfCoordinator,
            block.chainid
        );
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2PlusMock(vrfCoordinator).addConsumer(
            subId,
            contractToAddtoVrf
        );
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
