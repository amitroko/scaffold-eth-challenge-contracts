pragma solidity 0.8.4;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

/// @title Vendor.sol
/// @notice Functions enabling the exchange of ETH and our custom token
contract Vendor is Ownable {

  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);

  YourToken public yourToken;

  /// @notice Token : ETH exchange rate
  uint256 public constant tokensPerEth = 100;

  constructor(address tokenAddress) {
    yourToken = YourToken(tokenAddress);
  }

  /// @notice Allow the user to purchase tokens for ETH
  function buyTokens() public payable {
    uint256 amountToSend = msg.value * tokensPerEth;
    yourToken.transfer(msg.sender, amountToSend);
    emit BuyTokens(msg.sender, msg.value, amountToSend);
  }

  /// @notice Allow the contract owner to withdraw the ETH balance of the contract
  function withdraw() public onlyOwner {
    require(address(this).balance > 0, "Contract has no Ether");
    bool sent = payable(msg.sender).send(address(this).balance);
    require(sent, "Failed to send Ether");
  }

  /// @notice Allow users to sell their tokens for ETH
  function sellTokens(uint256 amtToSell) public payable {
    require(amtToSell > 0, "Must sell more than 0 tokens");
    require(yourToken.balanceOf(msg.sender) >= amtToSell, "Insufficient token balance");
    uint256 amtOfETHToTransfer = amtToSell / tokensPerEth;
    require(address(this).balance >= amtOfETHToTransfer, "Vendor cannot afford to fill request");
    bool sentTokens = yourToken.transferFrom(msg.sender, address(this), amtToSell);
    require(sentTokens, "Failed to send tokens from user to vendor");
    bool sentETH = payable(msg.sender).send(address(this).balance);
    require(sentETH, "Failed to send ETH from contract to user");
  }
}