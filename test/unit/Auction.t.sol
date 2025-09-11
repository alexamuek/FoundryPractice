// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "forge-std/console.sol";
import {MockERC721} from "../../src/mock/MockERC721.sol";
import {EnglishAuction} from "../../src/Auction.sol";

contract Auction_Test is Test {
    event Log(string message);

    address payable organizer;
    address payable buyer1;
    address payable buyer2;

    MockERC721 public nft;
    EnglishAuction public auction;

    function setUp() public {
        // create accounts
        organizer = payable(makeAddr({name: "Organizer"}));
        buyer1 = payable(makeAddr({name: "Buyer1"}));
        buyer2 = payable(makeAddr({name: "Buyer2"}));
        // Labels
        vm.label({account: address(nft), newLabel: "NFT"});
        vm.label({account: organizer, newLabel: "organizer"});
        vm.label({account: buyer1, newLabel: "buyer1"});
        vm.label({account: buyer2, newLabel: "buyer2"});

        vm.deal({account: organizer, newBalance: 100 ether});
        vm.deal({account: buyer1, newBalance: 100 ether});
        vm.deal({account: buyer2, newBalance: 100 ether});

        vm.startPrank({msgSender: organizer});
        nft = new MockERC721("Mock ERC721", "ERC");
        uint256 tokenId = 0;
        auction = new EnglishAuction(address(nft), tokenId, 0.1 ether);
        vm.label({account: address(auction), newLabel: "Auction"});
        nft.setApprovalForAll(address(auction), true);
        vm.stopPrank();
    }

    function test_make_bid() public {
        vm.prank(organizer);
        auction.start();
        vm.prank(buyer1);
        auction.bid{value: 0.2 ether}();
        vm.prank(buyer2);
        auction.bid{value: 0.3 ether}();
        vm.warp({newTimestamp: auction.endAt() + 1});
        vm.prank(buyer2);
        auction.end();
        vm.prank(buyer1);
        auction.withdraw();
    }
}
