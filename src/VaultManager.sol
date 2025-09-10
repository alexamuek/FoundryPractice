// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IUniswapV2Router {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
}

struct DepositResult {
    uint256 vaultShares1;
    uint256 vaultShares2;
    uint256 amountA;
    uint256 amountB;
    uint256 liquidity;
}

contract VaultManager {
    IERC4626 public immutable vault1;
    IERC4626 public immutable vault2;
    address public ROUTER;

    constructor(IERC4626 vault1_, IERC4626 vault2_, address UniswapV2Router_) {
        vault1 = vault1_;
        vault2 = vault2_;
        ROUTER = UniswapV2Router_;
    }

    function deposit(uint256 vaultAssets1, uint256 vaultAssets2, address receiver)
        public
        returns (DepositResult memory result)
    {
        SafeERC20.safeTransferFrom(IERC20(vault1.asset()), msg.sender, address(this), vaultAssets1);
        SafeERC20.safeTransferFrom(IERC20(vault2.asset()), msg.sender, address(this), vaultAssets2);
        SafeERC20.safeIncreaseAllowance(IERC20(vault1.asset()), ROUTER, vaultAssets1);
        SafeERC20.safeIncreaseAllowance(IERC20(vault2.asset()), ROUTER, vaultAssets2);

        result.vaultShares1 = vault1.deposit(vaultAssets1, receiver);
        result.vaultShares2 = vault2.deposit(vaultAssets2, receiver);

        (result.amountA, result.amountB, result.liquidity) = IUniswapV2Router(ROUTER).addLiquidity(
            vault1.asset(), vault2.asset(), vaultAssets1, vaultAssets2, 1, 1, address(this), block.timestamp
        );
    }
}
