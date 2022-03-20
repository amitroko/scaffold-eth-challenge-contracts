pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import 'hardhat/console.sol';
import './ExampleExternalContract.sol';

/// @title Staker.sol
/// @notice Enables the collection of funds towards a staking goal
contract Staker {
  ExampleExternalContract public exampleExternalContract;

  mapping(address => uint256) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 public deadline;
  bool openForWithdraw;
  bool executed;

  event Stake(address _staker, uint256 _amount);

  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    deadline = block.timestamp + 30 seconds;
    openForWithdraw = false;
    executed = false;
  }

  /// @notice Allow user to stake ETH
  function stake() public payable {
    require(!executed, 'Execute has already been called');
    require(msg.value > 0, 'Insufficient stake amount');
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  /// @notice Allow any user to initiate the transfer of funds to the external contract once the deadline has passed
  function execute() public {
    require(!executed, 'Execute has already been called');
    require(block.timestamp > deadline, 'Staking deadline has not passed');
    if (address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    } else {
      openForWithdraw = true;
    }
    executed = true;
  }

  /// @notice Allow users to withdraw funds if the deadline passes and the threshold is not met
  function withdraw(address _user) public payable {
    require(openForWithdraw, 'Funds can not currently be withdrawn.');
    require(balances[_user] > 0, 'No funds to withdraw');
    uint256 amt = balances[_user];
    balances[_user] = 0;
    payable(_user).transfer(amt);
  }

  /// @notice Returns the time left until the deadline (UNIX time)
  function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    }
    return deadline - block.timestamp;
  }

  /// @notice ETH sent directly to the contract falls back to stake()
  receive() external payable {
    stake();
  }
}
