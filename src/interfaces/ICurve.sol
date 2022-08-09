pragma solidity ^0.8.15;

interface IStableSwap {
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy)
        external;
    function underlying_coins(int128 i) external returns (address);
}