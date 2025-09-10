// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Vault is ERC4626 {

	constructor(IERC20 asset_, string memory name_, string memory symbol_) 
	    ERC4626(asset_)
	    ERC20(name_, symbol_)
	{}

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        // If asset() is ERC-777, `transferFrom` can trigger a reentrancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }
}