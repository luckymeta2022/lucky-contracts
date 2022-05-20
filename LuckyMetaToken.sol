// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LuckyMetaToken is ERC20  {
    
    uint256 private constant preMineSupply = 100000000 * 1e18;

    constructor() ERC20("LuckyMeta Token", "LMT"){
        _mint(msg.sender, preMineSupply);
    }
  
}