// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultManager} from "../src/VaultManager.sol";
import {MockERC20} from "../src/mock/MockERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";


contract Vault_Test is Test {
    
    address payable admin;
    address payable staker1;

    IERC20 public usdt;
    IERC20 public usdc;
    Vault public vaultUSDT;
    Vault public vaultUSDC;
    VaultManager public manager;



    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    function setUp() public {
        string memory mainnetRpc = string.concat("https://mainnet.infura.io/v3/",vm.envString("WEB3_INFURA_PROJECT_ID"));
        vm.createSelectFork(mainnetRpc);
        // create accounts
        admin = payable(makeAddr({ name: "Admin" }));
        staker1 = payable(makeAddr({ name: "Staker1" }));
        vm.startPrank({ msgSender: admin });
        usdt = IERC20(USDT);
        usdc = IERC20(USDC);
        vm.stopPrank();
        // Labels
        vm.label({ account: address(usdt), newLabel: "USDT" });
        vm.label({ account: address(usdc), newLabel: "USDC" });
        vm.label({ account: admin, newLabel: "admin" });
        vm.label({ account: staker1, newLabel: "staker1" });

        vm.deal({ account: admin, newBalance: 100 ether });
        vm.deal({ account: staker1, newBalance: 100 ether });
        deal({ token: address(usdt), to: staker1, give: 1_000_000e18 });
        deal({ token: address(usdc), to: staker1, give: 1_000_000e18 });

        vm.startPrank(admin);
        vaultUSDT = new Vault(usdt, "USDT vault", "vUSDT");
        vaultUSDC = new Vault(usdc, "USDC vault", "vUSDC");
        manager = new VaultManager(vaultUSDT, vaultUSDC, ROUTER);
        vm.stopPrank();

        vm.label({ account: address(vaultUSDT), newLabel: "VaultUSDT" });
        vm.label({ account: address(vaultUSDC), newLabel: "VaultUSDC" });
    }

    function test_deposit() public {
        uint256 depositAmount = 100e18;
        vm.startPrank(staker1);
        safeApprove(usdt, address(manager), depositAmount);
        safeApprove(usdc, address(manager), depositAmount);
        manager.deposit(depositAmount, depositAmount, staker1);
        vm.stopPrank();
    }

    function safeApprove(IERC20 token, address spender, uint256 amount)
        internal
    {
        (bool success, bytes memory returnData) = address(token).call(
            abi.encodeCall(IERC20.approve, (spender, amount))
        );
        require(
            success
                && (returnData.length == 0 || abi.decode(returnData, (bool))),
            "Approve fail"
        );
    }
}