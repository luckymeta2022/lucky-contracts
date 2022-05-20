// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LuckyMetaGold is ERC20 ,Ownable {
    
    uint256 private constant preMineSupply = 10000000000 * 1e18;

    constructor() ERC20("LuckyMeta Gold", "LMG"){
        _mint(msg.sender, preMineSupply);
    }

    function mint(address _to, uint256 _amount) public onlyOwner returns (bool) {
        _mint(_to, _amount);
        return true;
    }
   
}