// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2, StdStyle} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "forge-std/console.sol";
import {MockERC20} from "../src/mock/MockERC20.sol";
import {CrowdFund} from "../src/Crowdfund.sol";

contract CrowdFund_Test is Test {
    event Log(string message);

    address payable founder;
    address payable contributor1;

    MockERC20 public dai;
    CrowdFund public crowdFund;
    uint256 campaignId = 1;
    uint256 goalAmount = 100e18;

    function setUp() public {
        // create accounts
        founder = payable(makeAddr({name: "founder"}));
        contributor1 = payable(makeAddr({name: "contributor1"}));
        vm.startPrank({msgSender: founder});
        dai = new MockERC20("DAI", "DAI");
        crowdFund = new CrowdFund(address(dai));
        vm.stopPrank();
        // Labels
        vm.label({account: address(dai), newLabel: "fundToken"});
        vm.label({account: address(crowdFund), newLabel: "CrowdFund"});
        vm.label({account: founder, newLabel: "founder"});
        vm.label({account: contributor1, newLabel: "contributor1"});
        vm.deal({account: founder, newBalance: 100 ether});
        vm.deal({account: contributor1, newBalance: 100 ether});
        deal({token: address(dai), to: contributor1, give: 1_000_000e18});
    }

    function test_launch() public {
        vm.startPrank(founder);
        vm.expectEmit();
        emit CrowdFund.Launch(
            campaignId, founder, goalAmount, uint32(block.timestamp + 1), uint32(block.timestamp + 89 days)
        );
        crowdFund.launch(goalAmount, uint32(block.timestamp + 1), uint32(block.timestamp + 89 days));
        vm.expectRevert("start at < now");
        crowdFund.launch(goalAmount, uint32(block.timestamp - 1), uint32(block.timestamp + 89 days));
        vm.expectRevert("end at > max duration");
        crowdFund.launch(goalAmount, uint32(block.timestamp + 1), uint32(block.timestamp + 91 days));
        vm.stopPrank();
    }

    function test_claim_success() public {
        uint32 startAt = uint32(block.timestamp + 1);
        uint32 endAt = uint32(block.timestamp + 89 days);
        uint256 amount = 100e18;
        launchAndRaize(startAt, endAt, amount);
        vm.warp({newTimestamp: endAt + 1});
        uint256 beforeBalance = dai.balanceOf(founder);
        vm.prank(founder);
        vm.expectEmit();
        emit CrowdFund.Claim(campaignId);
        crowdFund.claim(campaignId);
        assertEq(dai.balanceOf(founder), amount + beforeBalance);
        assertEq(dai.balanceOf(address(crowdFund)), 0);
    }

    function test_claim_not_creator() public {
        uint32 startAt = uint32(block.timestamp + 1);
        uint32 endAt = uint32(block.timestamp + 89 days);
        uint256 amount = 100e18;
        launchAndRaize(startAt, endAt, amount);
        vm.expectRevert("not creator");
        vm.prank(contributor1);
        crowdFund.claim(campaignId);
    }

    function test_claim_not_ended() public {
        uint32 startAt = uint32(block.timestamp + 1);
        uint32 endAt = uint32(block.timestamp + 89 days);
        uint256 amount = 100e18;
        launchAndRaize(startAt, endAt, amount);
        vm.warp({newTimestamp: endAt - 10});
        vm.expectRevert("not ended");
        vm.prank(founder);
        crowdFund.claim(campaignId);
    }

    function test_claim_not_reached_goal() public {
        uint32 startAt = uint32(block.timestamp + 1);
        uint32 endAt = uint32(block.timestamp + 89 days);
        uint256 amount = 90e18;
        launchAndRaize(startAt, endAt, amount);
        vm.warp({newTimestamp: endAt + 10});
        vm.expectRevert("pledged < goal");
        vm.prank(founder);
        crowdFund.claim(campaignId);
    }

    function test_refund_reverts() public {
        uint32 startAt = uint32(block.timestamp + 1);
        uint32 endAt = uint32(block.timestamp + 89 days);
        uint256 amount = 100e18;
        launchAndRaize(startAt, endAt, amount);
        vm.expectRevert("not ended");
        crowdFund.refund(campaignId);
        vm.warp({newTimestamp: endAt + 1});
        vm.expectRevert("pledged >= goal");
        crowdFund.refund(campaignId);
        vm.stopPrank();
    }

    function test_refund_success() public {
        uint32 startAt = uint32(block.timestamp + 1);
        uint32 endAt = uint32(block.timestamp + 89 days);
        uint256 amount = 90e18;
        vm.startPrank(founder);
        crowdFund.launch(goalAmount, startAt, endAt);
        vm.stopPrank();
        vm.warp({newTimestamp: startAt + 10});
        vm.startPrank(contributor1);
        dai.approve(address(crowdFund), amount);
        crowdFund.pledge(campaignId, amount);
        vm.warp({newTimestamp: endAt + 1});
        uint256 beforeBalance = dai.balanceOf(contributor1);
        vm.expectEmit();
        emit CrowdFund.Refund(campaignId, contributor1, amount);
        crowdFund.refund(campaignId);
        assertEq(dai.balanceOf(contributor1), beforeBalance + amount);
        assertEq(dai.balanceOf(address(crowdFund)), 0);
        vm.stopPrank();
    }

    function test_cancel_not_creator() public {
        uint32 startAt = uint32(block.timestamp + 1);
        uint32 endAt = uint32(block.timestamp + 89 days);
        vm.startPrank(founder);
        crowdFund.launch(goalAmount, startAt, endAt);
        vm.stopPrank();
        vm.prank(contributor1);
        vm.expectRevert("not creator");
        crowdFund.cancel(campaignId);
    }

    function test_cancel_started() public {
        uint32 startAt = uint32(block.timestamp + 1);
        uint32 endAt = uint32(block.timestamp + 89 days);
        vm.startPrank(founder);
        crowdFund.launch(goalAmount, startAt, endAt);
        vm.warp({newTimestamp: startAt + 10});
        vm.expectRevert("started");
        crowdFund.cancel(campaignId);
        vm.stopPrank();
    }

    function test_cancel_success() public {
        uint32 startAt = uint32(block.timestamp + 1);
        uint32 endAt = uint32(block.timestamp + 89 days);
        vm.startPrank(founder);
        crowdFund.launch(goalAmount, startAt, endAt);
        vm.expectEmit();
        emit CrowdFund.Cancel(campaignId);
        crowdFund.cancel(campaignId);
        vm.stopPrank();
    }

    function test_pledge_not_started() public {
        uint32 startAt = uint32(block.timestamp + 1);
        uint32 endAt = uint32(block.timestamp + 89 days);
        uint256 amount = 100e18;
        vm.startPrank(founder);
        crowdFund.launch(goalAmount, startAt, endAt);
        vm.stopPrank();
        vm.startPrank(contributor1);
        dai.approve(address(crowdFund), amount);
        vm.expectRevert("not started");
        crowdFund.pledge(campaignId, amount);
        vm.stopPrank();
    }

    function test_pledge_ended() public {
        uint32 startAt = uint32(block.timestamp + 1);
        uint32 endAt = uint32(block.timestamp + 89 days);
        uint256 amount = 100e18;
        vm.startPrank(founder);
        crowdFund.launch(goalAmount, startAt, endAt);
        vm.stopPrank();
        vm.warp({newTimestamp: endAt + 10});
        vm.startPrank(contributor1);
        dai.approve(address(crowdFund), amount);
        vm.expectRevert("ended");
        crowdFund.pledge(campaignId, amount);
        vm.stopPrank();
    }

    function test_unpledge_ended() public {
        uint32 startAt = uint32(block.timestamp + 1);
        uint32 endAt = uint32(block.timestamp + 89 days);
        uint256 amount = 100e18;
        launchAndRaize(startAt, endAt, amount);
        vm.warp({newTimestamp: endAt + 1});
        vm.startPrank(contributor1);
        vm.expectRevert("ended");
        crowdFund.unpledge(campaignId, amount);
        vm.stopPrank();
    }

    function test_unpledge_success() public {
        uint32 startAt = uint32(block.timestamp + 1);
        uint32 endAt = uint32(block.timestamp + 89 days);
        uint256 amount = 100e18;
        launchAndRaize(startAt, endAt, amount);
        vm.startPrank(contributor1);
        uint256 beforeBalance = dai.balanceOf(contributor1);
        vm.expectEmit();
        emit CrowdFund.Unpledge(campaignId, contributor1, amount);
        crowdFund.unpledge(campaignId, amount);
        vm.stopPrank();
        assertEq(dai.balanceOf(contributor1), beforeBalance + amount);
        assertEq(dai.balanceOf(address(crowdFund)), 0);
    }

    function launchAndRaize(uint32 startTime, uint32 endTime, uint256 amount) internal {
        vm.startPrank(founder);
        vm.expectEmit();
        emit CrowdFund.Launch(campaignId, founder, goalAmount, startTime, endTime);
        crowdFund.launch(goalAmount, startTime, endTime);
        vm.stopPrank();
        uint256 beforeBalance = dai.balanceOf(contributor1);
        vm.warp({newTimestamp: startTime + 10});
        vm.startPrank(contributor1);
        dai.approve(address(crowdFund), amount);
        vm.expectEmit();
        emit CrowdFund.Pledge(campaignId, contributor1, amount);
        crowdFund.pledge(campaignId, amount);
        assertEq(beforeBalance - amount, dai.balanceOf(contributor1));
        assertEq(dai.balanceOf(address(crowdFund)), amount);
        console.log(StdStyle.red("Raized amount: "), StdStyle.bold(dai.balanceOf(address(crowdFund))));
        vm.stopPrank();
    }
}
