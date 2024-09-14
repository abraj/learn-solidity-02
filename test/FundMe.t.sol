// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { DeployFundMe, FundFundMe, WithdrawFundMe } from "../script/FundMe.s.sol";
import { FundMe } from "../src/FundMe.sol";

contract FundMeTest is Test {
  FundMe fundMe;

  address USER = makeAddr("user");
  address USER2 = makeAddr("user2");
  uint256 constant SEND_VALUE = 0.1 ether; // >= $5
  uint256 constant TINY_VALUE = 0.001 ether; // < $5
  uint256 constant STARTING_BALANCE = 10 ether;
  uint256 constant GAS_PRICE = 1;

  function setUp() external {
    DeployFundMe deployFundMe = new DeployFundMe();
    fundMe = deployFundMe.run();
    vm.deal(USER, STARTING_BALANCE);
    vm.deal(USER2, STARTING_BALANCE);
  }

  function test_OwnerisMsgSender() public view {
    // assertEq(fundMe.i_owner(), address(this));
    assertEq(fundMe.getOwner(), msg.sender);
  }

  function test_PriceFeedVersionIsCorrect() public view {
    assertEq(fundMe.getVersion(), 4);
  }

  function test_FundFailsWithZeroEth() public {
    vm.expectRevert(); // Next call should revert
    fundMe.fund(); // No ETH sent
  }

  function test_FundFailsWithoutEnoughEth() public {
    vm.expectRevert(); // Next call should revert
    fundMe.fund{ value: TINY_VALUE }();
  }

  modifier fundUser() {
    vm.prank(USER); // Next txn will be sent by USER
    fundMe.fund{ value: SEND_VALUE }();
    _;
  }

  modifier fundUser2() {
    vm.prank(USER2); // Next txn will be sent by USER2
    fundMe.fund{ value: SEND_VALUE }();
    _;
  }

  function test_FundMeIntegration() public {
    FundFundMe fundFundMe = new FundFundMe();
    fundFundMe.fundFundMe(address(fundMe));

    WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
    withdrawFundMe.withdrawFundMe(address(fundMe));

    assertEq(address(fundMe).balance, 0);
  }

  function test_FundUpdatesFundedDataStructure() public fundUser {
    assertEq(fundMe.getAddressAmount(USER), SEND_VALUE);
  }

  function test_FundAccumulatesFundedDataStructure() public fundUser {
    assertEq(fundMe.getAddressAmount(USER), SEND_VALUE);

    vm.prank(USER); // Next txn will be sent by USER
    fundMe.fund{ value: SEND_VALUE }();

    assertEq(fundMe.getAddressAmount(USER), 2 * SEND_VALUE);
  }

  function test_AddsFunderToArrayOfFunders1() public fundUser {
    assertEq(fundMe.getFunder(0), USER);

    vm.expectRevert();
    fundMe.getFunder(1);
  }

  function test_AddsFunderToArrayOfFunders2() public fundUser {
    assertEq(fundMe.getFunder(0), USER);

    vm.prank(USER);
    fundMe.fund{ value: SEND_VALUE }();

    assertEq(fundMe.getFunder(0), USER);

    vm.expectRevert();
    fundMe.getFunder(1);
  }

  function test_AddsFunderToArrayOfFunders3() public fundUser fundUser2 {
    assertEq(fundMe.getFunder(0), USER);
    assertEq(fundMe.getFunder(1), USER2);

    vm.expectRevert();
    fundMe.getFunder(2);
  }

  function test_OnlyOwnerCanWithdraw() public {
    vm.expectRevert();
    vm.prank(USER);
    fundMe.withdraw();
  }

  function test_WithdrawWithSingleFunder() public fundUser {
    // Arrange
    address owner = fundMe.getOwner();
    uint256 startingOwnerBalance = owner.balance;
    uint256 startingContractBalance = address(fundMe).balance;

    // vm.txGasPrice(GAS_PRICE);
    // uint256 gasStart = gasleft();

    // Act
    vm.prank(owner);
    fundMe.withdraw();

    // uint256 gasEnd = gasleft();
    // uint256 gasUsedPrice = (gasStart - gasEnd) * tx.gasprice;

    // Assert
    uint256 endingOwnerBalance = owner.balance;
    uint256 endingContractBalance = address(fundMe).balance;
    assertEq(endingOwnerBalance, startingOwnerBalance + startingContractBalance);
    assertEq(endingContractBalance, 0);
    assertEq(fundMe.getAddressAmount(USER), 0);
  }

  function test_WithdrawWithMultipleFunders() public fundUser fundUser2 {
    // Arrange
    address owner = fundMe.getOwner();
    uint256 startingOwnerBalance = address(owner).balance;
    uint256 startingContractBalance = address(fundMe).balance;

    // Act
    vm.prank(owner);
    fundMe.withdraw();

    // Assert
    uint256 endingOwnerBalance = address(owner).balance;
    uint256 endingContractBalance = address(fundMe).balance;
    assertEq(endingOwnerBalance, startingOwnerBalance + startingContractBalance);
    assertEq(endingContractBalance, 0);
    assertEq(fundMe.getAddressAmount(USER), 0);
    assertEq(fundMe.getAddressAmount(USER2), 0);
  }

  function test_WithdrawWithManyFunders() public {
    uint160 numberOfFunders = 10;
    address[10] memory addressList;

    for (uint160 i = 0; i < numberOfFunders; i++) {
      address userAddress = address(i + 1);
      addressList[i] = userAddress;

      hoax(userAddress, STARTING_BALANCE); // setup prank w/ some eth
      fundMe.fund{ value: SEND_VALUE }();
    }

    address owner = fundMe.getOwner();
    uint256 startingOwnerBalance = owner.balance;
    uint256 startingContractBalance = address(fundMe).balance;

    // showing usage of `startPrank/stopPrank`, instead of `prank`
    vm.startPrank(owner);
    fundMe.withdraw();
    vm.stopPrank();

    uint256 endingOwnerBalance = owner.balance;
    uint256 endingContractBalance = address(fundMe).balance;
    assert(endingOwnerBalance == startingOwnerBalance + startingContractBalance);
    assert(endingContractBalance == 0);

    for (uint8 i = 0; i < numberOfFunders; i++) {
      address userAddress = addressList[i];
      assertEq(fundMe.getAddressAmount(userAddress), 0);
    }
  }
}
