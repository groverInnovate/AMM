//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract AMM {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public  reserveA;
    uint256 public  reserveB;

    uint256 public  totalSupply;
    mapping (address => uint256) public  balances;
    uint256 public constant FEE_PERCENT = 3;


    constructor (address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);   
        
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external returns (uint256 liquidity) {
        require(amountA >0 && amountB >0, "Amounts must be greater than 0");


        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        if(reserveA ==0 && reserveB ==0){
            liquidity = sqrt(amountA*amountB);
        } else {
            require(amountA * reserveB == amountB * reserveA, "Invalid ratio");  // Ration maintained chahiye hmesha 


            liquidity = min((amountA* totalSupply)/reserveA, (amountB * totalSupply)/reserveB);
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

    function min(uint256 a , uint256 b ) internal pure   returns (uint256 ) {
        return a < b ? a : b;
    }


    function removeLiquidity() external {

    }
    
    function swap() external {
// Include 0.3% fee for transactions , this fees goes to the Liquidity Poolers
    }

}