// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

/**
 * @title Roll a Dice
 * @dev implements chainlink vrf 2
 * @author Ayush Yadav
 */
contract RollaDice is VRFConsumerBaseV2, AutomationCompatibleInterface {
  //global variables
  // Chainlink VRF Variables
  VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
  uint64 private immutable i_subscriptionId;
  bytes32 private immutable i_gasLane;
  uint32 private immutable i_callbackGasLimit;
  uint16 private constant REQUEST_CONFIRMATIONS = 3;
  uint32 private constant NUM_WORDS = 2;

  //game  variables
  uint256 private immutable i_targetscore;
  uint256 private player1score = 0;
  uint256 private computerscore = 0;
  bool private clicked = false;

  //events
  event WinnerPicked(string indexed winner);

  //functions
  constructor(
    address vrfCoordinatorV2,
    uint64 subscriptionId,
    bytes32 gasLane, // keyHash
    uint256 targetscore,
    uint32 callbackGasLimit
  ) VRFConsumerBaseV2(vrfCoordinatorV2) {
    i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
    i_gasLane = gasLane;
    i_subscriptionId = subscriptionId;
    i_targetscore = targetscore;
    i_callbackGasLimit = callbackGasLimit;
  }

  /* @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. clicked should be true
     
     */
  function checkUpkeep(
    bytes memory /* checkData */
  )
    public
    view
    override
    returns (bool upkeepNeeded, bytes memory /* performData */)
  {
    upkeepNeeded = (clicked);
    return (upkeepNeeded, "0x0");
  }

  /**
   * @dev Once `checkUpkeep` is returning `true`, this function is called
   * and it kicks off a Chainlink VRF call to get a random winner.
   */
  function performUpkeep(bytes calldata /* performData */) external override {
    (bool upkeepNeeded, ) = checkUpkeep("");

    uint256 requestId = i_vrfCoordinator.requestRandomWords(
      i_gasLane,
      i_subscriptionId,
      REQUEST_CONFIRMATIONS,
      i_callbackGasLimit,
      NUM_WORDS
    );
  }

  /**
     * @dev This is the function that Chainlink VRF node
     * calls to get numbers

     */
  function fulfillRandomWords(
    uint256 /* requestId */,
    uint256[] memory randomWords
  ) internal override {
    player1score = randomWords[0] % 6;
    computerscore = randomWords[1] % 6;

    clicked = false;
    if (player1score >= i_targetscore) {
      emit WinnerPicked("you win");
    } else if (computerscore >= i_targetscore) {
      emit WinnerPicked("computerwins");
    }
  }

  //view functions
  function gettargetscore() public view returns (uint256) {
    return i_targetscore;
  }
}
