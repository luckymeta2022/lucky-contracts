// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../library/MintLib.sol";
import "../library/LuckyLib.sol";


interface ILucky is IERC721 {
    
    function mint(MintLib.MintData memory mintData) external returns(uint tokenId);
    
    function luckys(uint tokenId) external view returns(LuckyLib.Lucky memory lucky);
    
    function origins(uint tokenId) external view returns(address origin);

}