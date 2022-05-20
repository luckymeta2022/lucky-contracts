// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract LuckyFee is Ownable {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    uint256 public constant BASE = 100;
    uint256 public feeRate;
    address public feeOwner;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    
    IERC20 public TOKEN;
    
    constructor(IERC20 _TOKEN,uint256 _feeRate,address _feeOwner){
        TOKEN = _TOKEN;
        feeRate = _feeRate;
        feeOwner = _feeOwner;
    }
    
    function setFeeRate(uint256 _feeRate) public onlyOwner {
        feeRate = _feeRate;
    }
    
    function setFeeOwner(address _feeOwner)  public onlyOwner {
        feeOwner = _feeOwner;
    }
    
    function setChargeType(IERC20 _assetType) public onlyOwner {
        TOKEN = _assetType;
    }
    
    function chargeFee(address account, uint amount) internal {
        chargeFee(account,DEAD,amount);
    }
    
    function chargeFee(address account, address receipt, uint amount) internal {
        uint fee = amount.mul(feeRate)/BASE;
        TOKEN.safeTransferFrom(account,feeOwner,fee);
        TOKEN.safeTransferFrom(account,receipt,amount.sub(fee));
    }
    
    
}