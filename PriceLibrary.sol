// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IPancakeFactory.sol";
library PriceLibrary {

    using SafeMath for uint256;

    function price(address _factory, address _from, address _to) public view returns(uint inAmount,uint outAmount) { 
        inAmount = unit(_from);
        if(_from==_to){
            return (inAmount,inAmount);
        }
        
        address _pair = IPancakeFactory(_factory).getPair(_from, _to);
        
        if(_pair!=address(0)){
            IPancakePair pair = IPancakePair(_pair);
            (uint112 ureserve0, uint112 ureserve1,) = pair.getReserves();
            address token1 = pair.token1();
            if(token1!=address(_to)){
                ( ureserve0,  ureserve1) = (ureserve1, ureserve0);
            }
            outAmount = getAmountOut(inAmount, ureserve0, ureserve1);
        }
    }

    function unit(address token) public view returns(uint) {
        uint _decimals = ERC20(token).decimals();
        return 10**_decimals;
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PankSwapLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PankSwapLibrary: INSUFFICIENT_LIQUIDITY');
        amountOut = amountIn*reserveOut/reserveIn;
    }

}