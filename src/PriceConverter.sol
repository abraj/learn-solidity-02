// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
    uint8 decimals = priceFeed.decimals();
    (, int256 answer,,,) = priceFeed.latestRoundData();
    return uint256(answer) * 10 ** (18 - decimals);
  }

  function getEthValueInUsd(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
    uint256 ethPrice = getPrice(priceFeed);
    uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1e18;
    return ethAmountInUsd;
  }
}
