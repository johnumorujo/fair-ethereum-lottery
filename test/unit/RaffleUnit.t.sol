//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2PlusMock} from "chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2PlusMock.sol";

contract RaffleTest is Test {
    event Playerjoined(address indexed player);

    Raffle public raffle;
    HelperConfig public helperConfig;

    address public sender = msg.sender;
    address john = makeAddr("john");
    address josh = makeAddr("josh");
    address mary = makeAddr("mary");
    uint256 public constant STARTING_PLAYER_BALANCE = 10e18;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 keyHash;
    uint256 subId;
    uint32 callbackGasLimit;
    uint256 deployerKey;

    modifier raffleEntredAndTimePassed() {
        vm.prank(john);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipfork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function setUp() external {
        DeployRaffle deploycontract = new DeployRaffle();
        (raffle, helperConfig) = deploycontract.run();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        keyHash = config.keyHash;
        subId = config.subId;
        callbackGasLimit = config.callbackGasLimit;
        deployerKey = config.deployerKey;
        vm.deal(john, STARTING_PLAYER_BALANCE);
        vm.deal(josh, STARTING_PLAYER_BALANCE);
        vm.deal(mary, STARTING_PLAYER_BALANCE);
    }

    function testentrancefeeis001() public view {
        assertEq(raffle.getentranceFee(), 0.01 ether);
    }

    function testraffleInitOpen() public view {
        assertEq(uint256(raffle.getRaffleState()), 0);
    }

    function testRafflerevertsifnotenougheth() public {
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        vm.prank(john);
        raffle.enterRaffle{value: 0.001 ether}();
    }

    function testplayeraddedtoarray() public {
        vm.prank(john);
        raffle.enterRaffle{value: 0.2 ether}();
        assert(raffle.getPlayerslength() == 1);
    }

    function testjohnaddedtoarray() public {
        vm.prank(john);
        raffle.enterRaffle{value: 0.2 ether}();
        assert(raffle.getplayers(0) == john);
    }

    function testemitEventonentrance() public {
        vm.prank(john);
        vm.expectEmit(true, false, false, false, address(raffle)); // raffle emits the event, true because only one index is in our event then false,false for the other 2 absent indexes, then false for absent data, then address of the emiter.
        emit Playerjoined(john);
        raffle.enterRaffle{value: 0.02 ether}();
    }

    function testdontallowentrywhilecalculating() public {
        vm.prank(john);
        raffle.enterRaffle{value: 0.02 ether}();
        vm.prank(josh);
        raffle.enterRaffle{value: 0.02 ether}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        vm.prank(josh);
        raffle.performUpkeep("");
        vm.expectRevert(Raffle.Raffle__Raffle_Closed.selector);
        vm.prank(mary);
        raffle.enterRaffle{value: 0.02 ether}();
    }

    function testcheckUpkeepfailswhennotentered() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testcheckupkeepfailswhenclosed() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        vm.prank(john);
        raffle.enterRaffle{value: 0.02 ether}();
        raffle.performUpkeep("");
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        vm.prank(john);
        raffle.enterRaffle{value: 0.02 ether}();
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueWhenParametersGood() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        vm.prank(john);
        raffle.enterRaffle{value: 0.02 ether}();
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
    }

    function testrequestconfirmations3() public view {
        assert(raffle.getrequestConfirmations() == 3);
    }

    function testnumwords1() public view {
        assert(raffle.getnumWords() == 1);
    }

    function testinterval() public view {
        assertEq(raffle.getinterval(), 30);
    }

    function testrafflestateclosedwhencalculating() public {
        vm.prank(john);
        raffle.enterRaffle{value: 0.02 ether}();
        vm.prank(josh);
        raffle.enterRaffle{value: 0.02 ether}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        vm.prank(josh);
        raffle.performUpkeep("");
        assertEq(uint256(raffle.getRaffleState()), 1);
    }

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        uint256 balance = address(raffle).balance;
        uint256 length = raffle.getPlayerslength();
        uint256 rafflestate = uint256(raffle.getRaffleState());

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // vm.prank(john);
        // raffle.enterRaffle{value: 0.002 ether}();
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__upKeepNotNeeded.selector,
                balance,
                length,
                rafflestate
            )
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId()
        public
        raffleEntredAndTimePassed
    {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assertEq(uint256(raffleState), 1);
    }

    function testFulfillrandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) public raffleEntredAndTimePassed skipfork {
        vm.expectRevert();
        VRFCoordinatorV2PlusMock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function testFulfillRandomWordsPicksWinnerResetsArrayAndSendsMoney()
        public
        raffleEntredAndTimePassed
        skipfork
    {
        uint256 startingIndex = 1;
        uint256 numPlayers = 3;

        for (uint256 i = startingIndex; i < numPlayers + startingIndex; i++) {
            address newPlayer = address(uint160(i));
            hoax(newPlayer, 1 ether);
            raffle.enterRaffle{value: 0.5 ether}();
        }

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2PlusMock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        assertEq(address(raffle).balance, 0);
        assert(raffle.getPlayerslength() == 0);
        assertEq(
            raffle.getRecentWinner().balance,
            (0.5 ether + entranceFee + 1.5 ether)
        );
    }
}
