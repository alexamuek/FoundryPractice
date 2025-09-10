// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "forge-std/console.sol";
import {MockERC20} from "../src/mock/MockERC20.sol";
import {StakingRewards} from "../src/Rewards.sol";

contract Rewards_Test is Test {
    event Log(string message);

    address payable admin;
    address payable staker1;
    address payable staker2;

    MockERC20 public dai;
    MockERC20 public usdt;
    StakingRewards public stakingPool;
    uint256 allRewardAmount = 100e18;
    uint256 duration = 10000;

    function setUp() public {
        // create accounts
        admin = payable(makeAddr({name: "Admin"}));
        staker1 = payable(makeAddr({name: "Staker1"}));
        staker2 = payable(makeAddr({name: "Staker2"}));
        vm.startPrank({msgSender: admin});
        usdt = new MockERC20("USDT", "USDT");
        dai = new MockERC20("DAI", "DAI");
        vm.stopPrank();
        // Labels
        vm.label({account: address(dai), newLabel: "stakingToken"});
        vm.label({account: address(usdt), newLabel: "rewardToken"});
        vm.label({account: admin, newLabel: "admin"});
        vm.label({account: staker1, newLabel: "staker1"});
        vm.label({account: staker2, newLabel: "staker2"});

        vm.deal({account: admin, newBalance: 100 ether});
        vm.deal({account: staker1, newBalance: 100 ether});
        vm.deal({account: staker2, newBalance: 100 ether});
        deal({token: address(dai), to: staker1, give: 1_000_000e18});
        deal({token: address(dai), to: staker2, give: 1_000_000e18});
        vm.startPrank(admin);
        stakingPool = new StakingRewards(address(dai), address(usdt));
        vm.label({account: address(stakingPool), newLabel: "StakingPool"});
        assertEq(stakingPool.owner(), admin);

        stakingPool.setRewardsDuration(duration);
        usdt.transfer(address(stakingPool), allRewardAmount);
        stakingPool.notifyRewardAmount(allRewardAmount);
        // add stakers to whiteList
        stakingPool.addToWhiteList(staker1);
        stakingPool.addToWhiteList(staker2);
        vm.stopPrank();

        vm.startPrank(staker1);
        dai.approve(address(stakingPool), dai.balanceOf(staker1));
        vm.stopPrank();
        vm.startPrank(staker2);
        dai.approve(address(stakingPool), dai.balanceOf(staker2));
        vm.stopPrank();
    }

    function test_staking() public {
        vm.startPrank(staker1);
        uint256 stakeAmount = 100e18;
        stakingPool.stake(stakeAmount);
        assertEq(stakingPool.balanceOf(staker1), stakeAmount);
        vm.warp({newTimestamp: stakingPool.finishAt() + 1});
        assertEq(stakingPool.earned(staker1), allRewardAmount);
        stakingPool.getReward();
        assertEq(usdt.balanceOf(staker1), allRewardAmount);
    }

    /// forge-config: default.fuzz.runs = 100
    function testFuzz_stake(uint256 amountToStake) public {
        vm.assume(amountToStake != 0);
        amountToStake = uint256(bound(amountToStake, 1, 1000e18));
        vm.prank(staker1);
        stakingPool.stake(amountToStake);
    }

    /// forge-config: default.fuzz.runs = 200
    function testFuzz_withdraw(uint256 amountToWithdraw) public {
        uint256 amountToStake = 1000e18;
        vm.startPrank(staker1);
        stakingPool.stake(amountToStake);
        vm.assume(amountToWithdraw != 0);
        amountToWithdraw = uint256(bound(amountToWithdraw, 1, 1000e18));
        stakingPool.withdraw(amountToStake);
        vm.stopPrank();
    }

    /// forge-config: default.fuzz.runs = 100
    function testFuzz_stake_8(uint8 amountToStake) public {
        vm.assume(amountToStake != 0);
        amountToStake = uint8(bound(amountToStake, 1, 1000e18));
        vm.prank(staker1);
        stakingPool.stake(amountToStake);
    }

    /// forge-config: default.fuzz.runs = 200
    function testFuzz_withdraw_8(uint8 amountToWithdraw) public {
        uint256 amountToStake = 1000e18;
        vm.startPrank(staker1);
        stakingPool.stake(amountToStake);
        vm.assume(amountToWithdraw != 0);
        amountToWithdraw = uint8(bound(amountToWithdraw, 1, 1000e18));
        stakingPool.withdraw(amountToStake);
        vm.stopPrank();
    }

    /// forge-config: default.fuzz.runs = 100
    function testFuzz_stake_different_stakers(uint8 index) public {
        address staker = payable(makeAddr(string(abi.encodePacked("user_", index))));
        deal({token: address(dai), to: staker, give: 1_000_000e18});
        uint256 amountToStake = 1000e18;
        vm.startPrank(staker);
        dai.approve(address(stakingPool), dai.balanceOf(staker));
        vm.assume(index != 0);
        vm.expectRevert("not trusted address");
        stakingPool.stake(amountToStake);
        vm.stopPrank();
    }
}
