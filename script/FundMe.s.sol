// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Script, console } from "forge-std/Script.sol";
// import { DevOpsTools } from "foundry-devops/src/DevOpsTools.sol";
import { FundMe } from "../src/FundMe.sol";
import { HelperConfig } from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
  function run() external returns (FundMe) {
    HelperConfig helperConfig = new HelperConfig();
    address priceFeedAddress = helperConfig.networkConfig();

    vm.startBroadcast();
    FundMe fundMe = new FundMe(priceFeedAddress);
    vm.stopBroadcast();

    return fundMe;
  }
}

contract FundFundMe is Script {
  uint256 constant SEND_VALUE = 0.1 ether;

  function run() external {
    // address mostRecentDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
    address mostRecentDeployed = address(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);

    fundFundMe(mostRecentDeployed);
  }

  function fundFundMe(address mostRecentDeployed) public {
    vm.startBroadcast();
    FundMe(payable(mostRecentDeployed)).fund{ value: SEND_VALUE }();
    vm.stopBroadcast();
  }
}

contract WithdrawFundMe is Script {
  function run() external {
    // address mostRecentDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
    address mostRecentDeployed = address(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);

    withdrawFundMe(mostRecentDeployed);
  }

  function withdrawFundMe(address mostRecentDeployed) public {
    vm.startBroadcast();
    FundMe(payable(mostRecentDeployed)).withdraw();
    vm.stopBroadcast();
  }
}
