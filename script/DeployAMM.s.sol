// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/AMM.sol";
import "../test/MockERC20.sol";

contract DeployAMM is Script {
    function run() external {
        vm.startBroadcast();

        
        MockERC20 tokenA = new MockERC20("Token A", "TKA", 18);
        MockERC20 tokenB = new MockERC20("Token B", "TKB", 18);

        
        AMM amm = new AMM(address(tokenA), address(tokenB));

        
        tokenA.mint(msg.sender, 100000 * 1e18);
        tokenB.mint(msg.sender, 100000 * 1e18);

        
        tokenA.approve(address(amm), type(uint256).max);
        tokenB.approve(address(amm), type(uint256).max);

        
        amm.addLiquidity(1000 * 1e18, 2000 * 1e18);

        vm.stopBroadcast();
    }
}