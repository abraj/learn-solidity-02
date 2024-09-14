// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { PriceConverter } from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
  using PriceConverter for uint256;

  uint256 private constant MINIMUM_USD = 5;

  address private immutable i_owner;
  AggregatorV3Interface private immutable i_priceFeed;

  address[] private s_funders;
  mapping(address => uint256) private s_amounts;

  constructor(address priceFeedAddress) {
    i_owner = msg.sender;
    i_priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  modifier OnlyOwner() {
    if (msg.sender != i_owner) revert FundMe__NotOwner();
    _;
  }

  function fund() public payable {
    require(msg.value.getEthValueInUsd(i_priceFeed) >= MINIMUM_USD * 1e18, "Please send at least 5 USD");

    if (s_amounts[msg.sender] == 0) {
      s_funders.push(msg.sender);
    }
    s_amounts[msg.sender] += msg.value;
  }

  function withdraw() public OnlyOwner {
    uint256 fundersLength = s_funders.length;

    for (uint256 i = 0; i < fundersLength; i++) {
      address funder = s_funders[i];
      s_amounts[funder] = 0;
    }
    s_funders = new address[](0);

    // // transfer
    // payable(msg.sender).transfer(address(this).balance);

    // // send
    // bool sendSuccess = payable(msg.sender).send(address(this).balance);
    // require(sendSuccess, "Send failed");

    // call
    (bool callSuccess,) = payable(msg.sender).call{ value: address(this).balance }("");
    require(callSuccess, "Send failed");
  }

  function getVersion() public view returns (uint256) {
    return i_priceFeed.version();
  }

  function getOwner() public view returns (address) {
    return i_owner;
  }

  function getAddressAmount(address fundedAddress) public view returns (uint256) {
    return s_amounts[fundedAddress];
  }

  function getFunder(uint256 index) public view returns (address) {
    return s_funders[index];
  }

  receive() external payable {
    fund();
  }

  fallback() external payable {
    fund();
  }
}
