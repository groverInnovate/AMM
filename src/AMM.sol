// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract AMM is ERC20 {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    uint256 public constant FEE_PERCENT = 30; 
    uint256 public constant PRECISION = 10000;

    bool private locked;

    modifier noReentrancy() {
        require(!locked, "Reentrancy detected!");
        locked = true;
        _;
        locked = false;
    }

    event LiquidityAdded(
        address indexed provider,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );
    event LiquidityRemoved(
        address indexed provider,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );
    event SwapExecuted(
        address indexed trader,
        address tokenIn,
        uint256 amountIn,
        uint256 amountOut
    );

    constructor(address _tokenA, address _tokenB) ERC20("LP Token", "LPT") {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function addLiquidity(
        uint256 amountA,
        uint256 amountB
    ) external noReentrancy returns (uint256 liquidity) {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than 0");

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        if (reserveA == 0 && reserveB == 0) {
            liquidity = sqrt(amountA * amountB);
            require(liquidity > 1000, "Insufficient initial liquidity");
            _mint(msg.sender, liquidity - 1000);
        } else {
            liquidity = min(
                (amountA * totalSupply()) / reserveA,
                (amountB * totalSupply()) / reserveB
            );
        }

        require(liquidity > 0, "Liquidity must be greater than 0");
        _mint(msg.sender, liquidity);

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
    }

    function removeLiquidity(
        uint256 liquidity
    ) external noReentrancy returns (uint256 amountA, uint256 amountB) {
        require(liquidity > 0, "Liquidity must be greater than 0");
        require(balanceOf(msg.sender) >= liquidity, "Insufficient LP balance");

        uint256 totalLPSupply = totalSupply();
        amountA = (liquidity * reserveA) / totalLPSupply;
        amountB = (liquidity * reserveB) / totalLPSupply;

        require(
            amountA > 0 && amountB > 0,
            "Withdraw amount must be greater than 0"
        );

        _burn(msg.sender, liquidity);

        reserveA -= amountA;
        reserveB -= amountB;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, liquidity);
    }

    function swap(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut
    ) external noReentrancy returns (uint256 amountOut) {
        require(amountIn > 0, "Input amount must be greater than zero");
        require(
            tokenIn == address(tokenA) || tokenIn == address(tokenB),
            "Invalid Token"
        );

        bool isTokenA = (tokenIn == address(tokenA));
        IERC20 tokenInContract = isTokenA ? tokenA : tokenB;
        IERC20 tokenOutContract = isTokenA ? tokenB : tokenA;
        uint256 reserveIn = isTokenA ? reserveA : reserveB;
        uint256 reserveOut = isTokenA ? reserveB : reserveA;

        tokenInContract.transferFrom(msg.sender, address(this), amountIn);

        uint256 amountInWithFee = (amountIn * (PRECISION - FEE_PERCENT)) /
            PRECISION;
        amountOut =
            (reserveOut * amountInWithFee) /
            (reserveIn + amountInWithFee);

        require(amountOut >= minAmountOut, "Slippage exceeded");
        require(amountOut > 0, "Insufficient output amount");

        tokenOutContract.transfer(msg.sender, amountOut);

        if (isTokenA) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }

        emit SwapExecuted(msg.sender, tokenIn, amountIn, amountOut);
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
}
