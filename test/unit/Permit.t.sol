// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {Dai} from "../../src/DAI.sol";
import {SigUtils} from "../../src/SigUtils.sol";

contract Permit_Test is Test {
    address payable admin;
    address payable holder;
    address internal owner;
    address internal spender;
    uint256 internal ownerPrivateKey;
    uint256 internal spenderPrivateKey;
    
    Dai public dai;
    SigUtils public sigUtils;

    function setUp() public {
        // create accounts
        admin = payable(makeAddr({name: "Admin"}));
        
        ownerPrivateKey = 0xA11CE;
        spenderPrivateKey = 0xB0B;

        owner = vm.addr(ownerPrivateKey);
        spender = vm.addr(spenderPrivateKey);
        
        vm.startPrank({msgSender: admin});
        dai = new Dai(block.chainid);
        sigUtils = new SigUtils(dai.DOMAIN_SEPARATOR());
        vm.stopPrank();
        // Labels
        vm.label({account: address(dai), newLabel: "DAI"});
        vm.label({account: admin, newLabel: "admin"});
        vm.label({account: owner, newLabel: "owner"});
        
        vm.deal({account: admin, newBalance: 100 ether});
        vm.deal({account: owner, newBalance: 100 ether});
        
        deal({token: address(dai), to: owner, give: 1_000_000e18});
    }

    function test_permit_1() public {
        uint256 nonce = 0;
        SigUtils.Permit memory permit = SigUtils.Permit({
           owner: owner,
           spender: spender,
           nonce: nonce,
           expiry: 1 days,
           allowed: true
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        console2.log(owner);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        vm.warp({newTimestamp: block.timestamp + 2 days});
        vm.expectRevert("Dai/permit-expired");
        vm.prank(owner);
        dai.permit(
            permit.owner,
            permit.spender,
            nonce,
            permit.expiry,
            true,
            v,
            r,
            s
        );
    }

    function test_permit_2() public {
        uint256 nonce = 0;
        SigUtils.Permit memory permit = SigUtils.Permit({
           owner: owner,
           spender: spender,
           nonce: nonce,
           expiry: 1 days,
           allowed: true
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        console2.log(owner);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        vm.prank(owner);
        dai.permit(
            permit.owner,
            permit.spender,
            nonce,
            permit.expiry,
            true,
            v,
            r,
            s
        );
    }
}
