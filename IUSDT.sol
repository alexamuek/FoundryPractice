// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface UChildERC20Proxy {
    event ProxyOwnerUpdate(address _new, address _old);
    event ProxyUpdated(address indexed _new, address indexed _old);

    fallback() external payable;

    receive() external payable;

    function implementation() external view returns (address);
    function proxyOwner() external view returns (address);
    function proxyType() external pure returns (uint256 proxyTypeId);
    function transferProxyOwnership(address newOwner) external;
    function updateAndCall(address _newProxyTo, bytes memory data) external payable;
    function updateImplementation(address _newProxyTo) external;
}
