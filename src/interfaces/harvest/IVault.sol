pragma solidity ^0.8.13;

interface IVault {
    function deposit(uint256 amountWei) external;
    function withdrawAll() external;
    function withdraw(uint256 numberOfShares) external;
    function balanceOf(address who) external returns (uint256);
}