// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title A raffle contract
 * @author John Umoru
 * @notice just a notice
 */
import {IVRFCoordinatorV2Plus} from "chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFV2PlusClient} from "chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {VRFCoordinatorV2_5} from "chainlink/contracts/src/v0.8/vrf/dev/VRFCoordinatorV2_5.sol";
import {VRFConsumerBaseV2Plus} from "chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {AutomationCompatibleInterface} from "chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    /* EVENTS */

    event Playerjoined(address indexed player);
    event WinnerPicked(address indexed winner);
    event requestedRaffleWinner(uint256 indexed requestId);

    /* ERRORS */
    error Raffle__NotEnoughEthSent();
    error Raffle__Transfer_Failed();
    error Raffle__Raffle_Closed();
    error Raffle__upKeepNotNeeded(
        uint256 balance,
        uint256 playersLength,
        uint256 raffleState
    );

    /* Type Declarations */

    //**NOTE** ENUM IS A TYPE
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* GLOBAL VARIABLES */
    address payable[] private s_players;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    uint32 private immutable i_callbackGasLimit;
    bytes32 private immutable i_keyHash; //gaslane
    uint256 private immutable i_subId;
    uint256 private immutable i_interval; //@Dev the duration of each lottery run in seconds.
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    IVRFCoordinatorV2Plus private immutable i_vrfCoordinatorContract; // new addition

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address _vrfCoordinator,
        bytes32 keyHash,
        uint256 subId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_entranceFee = entranceFee;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
        s_raffleState = RaffleState.OPEN;
        i_vrfCoordinatorContract = IVRFCoordinatorV2Plus(_vrfCoordinator);
        i_keyHash = keyHash; //gaslane
        i_subId = subId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__Raffle_Closed();
        }
        s_players.push(payable(msg.sender));

        emit Playerjoined(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. There are players registered.
     * 5. Implicitly, your subscription is funded with LINK.
     */
    function checkUpkeep(
        bytes memory /* checkdata */
    ) public view returns (bool upkeepNeeded, bytes memory /*perfoemData*/) {
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (isOpen && timePassed && hasBalance && hasPlayers);
        return (upkeepNeeded, "0X0");
    }

    //get random number
    //pick winner with random number
    //be automatically called
    function performUpkeep(bytes calldata /* performData */) public {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__upKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinatorContract.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        emit requestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        uint256 indexofWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexofWinner];
        s_recentWinner = winner;
        emit WinnerPicked(winner);
        (bool callSuccess, ) = winner.call{value: address(this).balance}("");
        if (!callSuccess) {
            revert Raffle__Transfer_Failed();
        }
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
    }

    function getentranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getplayers(uint256 id) public view returns (address) {
        return s_players[id];
    }

    function getPlayerslength() public view returns (uint256) {
        return s_players.length;
    }

    function getrequestConfirmations() public pure returns (uint16) {
        return REQUEST_CONFIRMATIONS;
    }

    function getnumWords() public pure returns (uint32) {
        return NUM_WORDS;
    }

    function getinterval() public view returns (uint256) {
        return i_interval;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }
}
