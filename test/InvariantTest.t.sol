// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {AMM} from "../src/AMM.sol";
import {MockERC20} from "./MockERC20.sol";

contract InvariantTest is Test {
    AMM amm;
    MockERC20 tokenA;
    MockERC20 tokenB;

    address user1 = address(0x1);
    address user2 = address(0x2);

    function setUp() public {
        tokenA = new MockERC20("Token A", "TKA", 18);
        tokenB = new MockERC20("Token B", "TKB", 18);

        amm = new AMM(address(tokenA), address(tokenB));

        tokenA.mint(user1, 10000 * 1e18);
        tokenB.mint(user1, 10000 * 1e18);
        tokenA.mint(user2, 10000 * 1e18);
        tokenB.mint(user2, 10000 * 1e18);

        vm.startPrank(user1);
        tokenA.approve(address(amm), type(uint256).max);
        tokenB.approve(address(amm), type(uint256).max);
        amm.addLiquidity(1000 * 1e18, 2000 * 1e18);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenA.approve(address(amm), type(uint256).max);
        tokenB.approve(address(amm), type(uint256).max);
        vm.stopPrank();
    }

    function testInvariantConstantProduct() public {
        uint256 reserveA = amm.reserveA();
        uint256 reserveB = amm.reserveB();

        uint256 totalPoolBeforeSwapping = reserveA * reserveB;

        vm.startPrank(user2);
        amm.swap(address(tokenA), 100 * 1e18, 1); 
        amm.swap(address(tokenB), 200 * 1e18, 1); 
        vm.stopPrank();

        uint256 newReserveA = amm.reserveA();
        uint256 newReserveB = amm.reserveB();
        uint256 totalPoolAfterSwapping = newReserveA * newReserveB;

        
        assertGe(
            totalPoolAfterSwapping,
            (totalPoolBeforeSwapping * 997) / 1000
        );
    }

    /* function testLiquidityProportions() public {
        uint256 initialTotalSupply = amm.totalSupply();
        uint256 initialReserveA = amm.reserveA();
        uint256 initialReserveB = amm.reserveB();

        vm.startPrank(user2);
        amm.addLiquidity(500 * 1e18, 1000 * 1e18);
        vm.stopPrank();

        uint256 newTotalSupply = amm.totalSupply();
        uint256 newReserveA = amm.reserveA();
        uint256 newReserveB = amm.reserveB();

        uint256 expectedLiquidity = (500 * initialTotalSupply) /
            initialReserveA;
        assertEq(newTotalSupply, initialTotalSupply + expectedLiquidity);
        assertEq(newReserveA, initialReserveA + 500 * 1e18);
        assertEq(newReserveB, initialReserveB + 1000 * 1e18);
    }*/

    function testPoolBalancesAfterSwaps() public {
        uint256 initialReserveA = amm.reserveA();
        uint256 initialReserveB = amm.reserveB();

        vm.startPrank(user2);
        amm.swap(address(tokenA), 200 * 1e18, 1);
        amm.swap(address(tokenB), 400 * 1e18, 1);
        vm.stopPrank();

        uint256 finalReserveA = amm.reserveA();
        uint256 finalReserveB = amm.reserveB();

        assertGt(finalReserveA, initialReserveA - 200 * 1e18);
        assertGt(finalReserveB, initialReserveB - 400 * 1e18);
    }

    function testLiquidityTokenMinting() public {
        uint256 initialSupply = amm.totalSupply();

        vm.startPrank(user2);
        uint256 lpTokensMinted = amm.addLiquidity(500 * 1e18, 1000 * 1e18);
        vm.stopPrank();

        uint256 newSupply = amm.totalSupply();

        assertEq(newSupply, initialSupply + lpTokensMinted);
    }

    function testRemoveLiquidity() public {
        uint256 initialReserveA = amm.reserveA();
        uint256 initialReserveB = amm.reserveB();
        uint256 initialTotalSupply = amm.totalSupply();

        vm.startPrank(user1);
        amm.removeLiquidity(500 * 1e18);
        vm.stopPrank();

        uint256 newReserveA = amm.reserveA();
        uint256 newReserveB = amm.reserveB();
        uint256 newTotalSupply = amm.totalSupply();

        assertLt(newReserveA, initialReserveA);
        assertLt(newReserveB, initialReserveB);
        assertLt(newTotalSupply, initialTotalSupply);
    }

    function testSwapSlippageEnforcement() public {
        vm.startPrank(user2);
        vm.expectRevert(); 
        amm.swap(address(tokenA), 100 * 1e18, 5000 * 1e18); 
        vm.stopPrank();
    }

    function testReserveUpdateOnLiquidityAddition() public {
        uint256 initialReserveA = amm.reserveA();
        uint256 initialReserveB = amm.reserveB();

        vm.startPrank(user2);
        amm.addLiquidity(500 * 1e18, 1000 * 1e18);
        vm.stopPrank();

        uint256 newReserveA = amm.reserveA();
        uint256 newReserveB = amm.reserveB();

        assertEq(newReserveA, initialReserveA + 500 * 1e18);
        assertEq(newReserveB, initialReserveB + 1000 * 1e18);
    }

    function testInvariantAfterAddingLiquidity() public {
        uint256 initialK = amm.reserveA() * amm.reserveB();

        vm.startPrank(user2);
        amm.addLiquidity(500 * 1e18, 1000 * 1e18);
        vm.stopPrank();

        uint256 newK = amm.reserveA() * amm.reserveB();
        assertGe(newK, initialK);
    }
}
