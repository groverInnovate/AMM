//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

contract AMM {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    uint256 public totalSupply;
    mapping(address => uint256) public balances;
    uint256 public constant FEE_PERCENT = 3;

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function addLiquidity(
        uint256 amountA,
        uint256 amountB
    ) external returns (uint256 liquidity) {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than 0");

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        if (reserveA == 0 && reserveB == 0) {
            liquidity = sqrt(amountA * amountB);
        } else {
            require(amountA * reserveB == amountB * reserveA, "Invalid ratio"); // Ration maintained chahiye hmesha

            liquidity = min(
                (amountA * totalSupply) / reserveA,
                (amountB * totalSupply) / reserveB
            );
        }

        require(liquidity > 0, "Liquidity must be greater than 0 ");

        balances[msg.sender] += liquidity;
        totalSupply += liquidity;

        reserveA += amountA;
        reserveB += amountB;
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;

        uint256 z = (x + 1) / 2;
        uint256 y = x;

        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function removeLiquidity(
        uint256 liquidity
    ) external returns (uint256 amountA, uint256 amountB) {
        require(liquidity > 0, "Liquidity must be greater than 0");
        require(balances[msg.sender] >= liquidity, "Insufficient LP balance ");

        amountA = (liquidity * reserveA) / totalSupply;
        amountB = (liquidity * reserveB) / totalSupply;

        require(
            amountA > 0 && amountB > 0,
            "Withdraw amount must be greater than 0 "
        );

        balances[msg.sender] -= liquidity;
        totalSupply -= liquidity;

        reserveA -= amountA;
        reserveB -= amountB;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);
    }

    function swap(
    address tokenIn,
    uint256 amountIn
) external returns (uint256 amountOut) {
    require(amountIn > 0, "Input amount must be greater than zero");
    require(
        tokenIn == address(tokenA) || tokenIn == address(tokenB),
        "Invalid Token"
    );

    bool isTokenA = (tokenIn == address(tokenA));
    (
        IERC20 tokenInContract,
        IERC20 tokenOutContract,
        uint256 reserveIn,
        uint256 reserveOut
    ) = isTokenA
            ? (tokenA, tokenB, reserveA, reserveB)
            : (tokenB, tokenA, reserveB, reserveA);

    // Log initial reserves
    console.log("Before Swap - ReserveA:", reserveA);
    console.log("Before Swap - ReserveB:", reserveB);

    // Transfer `amountIn` first and update reserveIn
    tokenInContract.transferFrom(msg.sender, address(this), amountIn);
    reserveIn += amountIn; // Adjust reserveIn after transfer

    // Save old K (before swap)
    uint256 oldK = reserveA * reserveB;
    console.log("Old K:", oldK);

    uint256 amountInWithFee = (amountIn * 997) / 1000;
    amountOut = (reserveOut * amountInWithFee) / (reserveIn);

    require(amountOut > 0, "Insufficient output amount");

    // Transfer tokens *before* updating reserves
    tokenOutContract.transfer(msg.sender, amountOut);

    // Update reserves after transfer
    if (isTokenA) {
        reserveB -= amountOut;
    } else {
        reserveA -= amountOut;
    }

    // Log updated reserves
    console.log("After Swap - ReserveA:", reserveA);
    console.log("After Swap - ReserveB:", reserveB);

    // Calculate new k
    uint256 newK = reserveA * reserveB;
    console.log("New K:", newK);

    // Enforce invariant (newK should never be greater than oldK)
    require(newK <= oldK, "Invariant violation: k increased!");

    return amountOut;
}


    function getTokenPrices()
        external
        view
        returns (uint256 priceA, uint256 priceB)
    {
        require(reserveA > 0 && reserveB > 0, "No liquidity available");

        priceA = (reserveB * 1e18) / reserveA;
        priceB = (reserveA * 1e18) / reserveB;
    }
}
