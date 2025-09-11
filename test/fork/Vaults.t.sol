// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Vault} from "../../src/Vault.sol";
import {VaultManager} from "../../src/VaultManager.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Vault_Test is Test {
    address payable admin;
    address payable staker1;

    IERC20 public usdt;
    IERC20 public usdc;
    Vault public vaultUSDT;
    Vault public vaultUSDC;
    VaultManager public manager;

    address private constant USDT_eth = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant USDC_eth = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant ROUTER_eth = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address private constant USDT_matic = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address private constant USDC_matic = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address private constant ROUTER_matic = 0xedf6066a2b290C185783862C7F4776A2C8077AD1;

    function setUp() public {
        
        // create accounts
        admin = payable(makeAddr({name: "Admin"}));
        staker1 = payable(makeAddr({name: "Staker1"}));
        
        // Labels
        vm.label({account: admin, newLabel: "admin"});
        vm.label({account: staker1, newLabel: "staker1"});
    }

    function test_deposit() public {
        string memory mainnetRpc =
            string.concat("https://mainnet.infura.io/v3/", vm.envString("WEB3_INFURA_PROJECT_ID"));
        vm.createSelectFork(mainnetRpc);
        vm.startPrank({msgSender: admin});
        usdt = IERC20(USDT_eth);
        usdc = IERC20(USDC_eth);
        vm.stopPrank();
        vm.label({account: address(usdt), newLabel: "USDT"});
        vm.label({account: address(usdc), newLabel: "USDC"});
        deal({token: address(usdt), to: staker1, give: 1_000_000e18});
        deal({token: address(usdc), to: staker1, give: 1_000_000e18});
        vm.startPrank(admin);
        vaultUSDT = new Vault(usdt, "USDT vault", "vUSDT");
        vaultUSDC = new Vault(usdc, "USDC vault", "vUSDC");
        manager = new VaultManager(vaultUSDT, vaultUSDC, ROUTER_eth);
        vm.stopPrank();
        vm.label({account: address(vaultUSDT), newLabel: "VaultUSDT"});
        vm.label({account: address(vaultUSDC), newLabel: "VaultUSDC"});

        uint256 depositAmount = 100e18;
        vm.startPrank(staker1);
        safeApprove(usdt, address(manager), depositAmount);
        safeApprove(usdc, address(manager), depositAmount);
        manager.deposit(depositAmount, depositAmount, staker1);
        vm.stopPrank();

        
        string memory polygonRpc =
            string.concat("https://polygon-mainnet.infura.io/v3/", vm.envString("WEB3_INFURA_PROJECT_ID"));
        vm.createSelectFork(polygonRpc);
        vm.startPrank({msgSender: admin});
        usdt = IERC20(USDT_matic);
        usdc = IERC20(USDC_matic);
        vm.stopPrank();
        vm.label({account: address(usdt), newLabel: "USDT"});
        vm.label({account: address(usdc), newLabel: "USDC"});
        deal({token: address(usdt), to: staker1, give: 1_000_000e18});
        deal({token: address(usdc), to: staker1, give: 1_000_000e18});
        vm.startPrank(admin);
        vaultUSDT = new Vault(usdt, "USDT vault", "vUSDT");
        vaultUSDC = new Vault(usdc, "USDC vault", "vUSDC");
        manager = new VaultManager(vaultUSDT, vaultUSDC, ROUTER_matic);
        vm.stopPrank();
        vm.label({account: address(vaultUSDT), newLabel: "VaultUSDT"});
        vm.label({account: address(vaultUSDC), newLabel: "VaultUSDC"});

        depositAmount = 100e18;
        vm.startPrank(staker1);
        safeApprove(usdt, address(manager), depositAmount);
        safeApprove(usdc, address(manager), depositAmount);
        manager.deposit(depositAmount, depositAmount, staker1);
        vm.stopPrank();

    }

    function safeApprove(IERC20 token, address spender, uint256 amount) internal {
        (bool success, bytes memory returnData) = address(token).call(abi.encodeCall(IERC20.approve, (spender, amount)));
        require(success && (returnData.length == 0 || abi.decode(returnData, (bool))), "Approve fail");
    }
}
