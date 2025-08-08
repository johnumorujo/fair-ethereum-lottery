// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";
import {Raffle} from "src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";

contract InteractionsTest is Test {
    Raffle public raffle;
    DeployRaffle deployraffle;
    uint256 private constant STARTING_PLAYER_BALANCE = 10e18;
    uint256 private constant ENTERED_WITH = 2e18;
    uint256 private constant interval = 30; // 30 seconds

    address[] users;

    function setUp() external {
        deployraffle = new DeployRaffle();
        (raffle, ) = deployraffle.run();
        users = [
            makeAddr("john"),
            makeAddr("alice"),
            makeAddr("shiaki"),
            makeAddr("peter"),
            makeAddr("nesi"),
            makeAddr("honour")
        ];
    }

    function testuserscanenterRaffleWinnerisPickedandwinnerisPaid() public {
        for (uint256 i = 0; i < users.length; i++) {
            vm.deal(users[i], STARTING_PLAYER_BALANCE);
            vm.prank(users[i]);
            raffle.enterRaffle{value: ENTERED_WITH}();
        }
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
    }
}
