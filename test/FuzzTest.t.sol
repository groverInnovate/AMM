// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/AMM.sol";
import "./MockERC20.sol";

contract FuzzTest is Test {
    AMM public amm;
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    address public owner;
    address public user;

    function testFuzz_AddLiquidity(uint256 amountA, uint256 amountB) public {
        vm.assume(amountA > 0 && amountA < 1e20);
        vm.assume(amountB > 0 && amountB < 1e20);

        vm.startPrank(user);

        amm.addLiquidity(amountA, amountB);

        assertGt(amm.balanceOf(user), 0);
        vm.stopPrank();
    }

    function testFuzz_RemoveLiquidity(uint256 liquidity) public {
        vm.startPrank(user);
        amm.addLiquidity(1e18, 1e18);
        vm.stopPrank();

        vm.assume(liquidity > 0 && liquidity <= amm.balanceOf(user));

        vm.startPrank(user);
        amm.removeLiquidity(liquidity);

        assertGt(tokenA.balanceOf(user), 0);
        assertGt(tokenB.balanceOf(user), 0);
        vm.stopPrank();
    }

    function testFuzz_Swap(uint256 amountIn) public {
        vm.startPrank(user);
        amm.addLiquidity(1e18, 1e18);
        vm.stopPrank();

        vm.assume(amountIn > 0 && amountIn < 1e18);

        vm.startPrank(user);
        uint256 minAmountOut = 1;
        amm.swap(address(tokenA), amountIn, minAmountOut);

        assertGt(tokenB.balanceOf(user), 0);
        vm.stopPrank();
    }
}
