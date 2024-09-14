// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Script, console } from "forge-std/Script.sol";
import { MockV3Aggregator } from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
  NetworkConfig public networkConfig;

  uint8 public constant DECIMALS = 8;
  int256 public constant INITIAL_PRICE = 3123e8;

  struct NetworkConfig {
    address priceFeedAddress;
  }

  constructor() {
    if (block.chainid == 1) {
      networkConfig = getMainnetConfig();
    } else if (block.chainid == 11155111) {
      networkConfig = getSepoliaConfig();
    } else {
      networkConfig = getOrCreateAnvilConfig();
    }
  }

  function getMainnetConfig() public pure returns (NetworkConfig memory) {
    NetworkConfig memory mainnetConfig = NetworkConfig({ priceFeedAddress: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 });
    return mainnetConfig;
  }

  function getSepoliaConfig() public pure returns (NetworkConfig memory) {
    NetworkConfig memory sepoliaConfig = NetworkConfig({ priceFeedAddress: 0x694AA1769357215DE4FAC081bf1f309aDC325306 });
    return sepoliaConfig;
  }

  function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
    if (networkConfig.priceFeedAddress != address(0)) {
      return networkConfig;
    }

    vm.startBroadcast();
    MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
    vm.stopBroadcast();

    NetworkConfig memory anvilConfig = NetworkConfig({ priceFeedAddress: address(mockPriceFeed) });
    return anvilConfig;
  }
}
