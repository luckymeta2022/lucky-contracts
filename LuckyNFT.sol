// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./WhiteList.sol";

contract LuckyNFT is ERC721URIStorage,ERC721Enumerable,WhiteList{

    string public baseURI;
    string public endingPrefix;

    event Mint(address indexed minter, uint tokenId);

    constructor() ERC721("LuckyMeta", "LuckyNFT"){}


    function setBaseURI(string memory __baseURI) external onlyOwner {
            baseURI = __baseURI;
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721,ERC721URIStorage) returns (string memory) {
         return string(abi.encodePacked(baseURI, '/', Strings.toString(tokenId), endingPrefix));
    }



    function safeMint(address _toAddress,uint256 tokenId) public   {
         address sender=msg.sender;
         require(isWhiteListed[sender], "ERC721: minter caller is not owner nor approved");
         _safeMint(_toAddress, tokenId);
    }


    function _burn(uint256 tokenId) internal virtual override(ERC721,ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from,address to,uint256 tokenId) internal virtual override(ERC721Enumerable,ERC721) {
        super._beforeTokenTransfer(from,to,tokenId);
    }

   
    function giveNFT(address from,address to, uint256[] calldata _tokenIds) public virtual  {
        for(uint256 i = 0; i < _tokenIds.length; i++){
            uint256 tokenId=_tokenIds[i];
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
            _transfer(from, to, tokenId);
        }
    }


}
