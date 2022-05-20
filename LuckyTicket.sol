
//SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract LuckyTicket is ERC721URIStorage,ERC721Enumerable,Ownable {

  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address public feeOwner;
  IERC20  public feeToken;

  uint256 public priceDev=0;
  uint256 public priceWhitelist=10000000000000000000;
  uint256 public pricePublic   =20000000000000000000;

  string public baseURI;

  string public endingPrefix;

  // Booleans
  bool public isPublicSaleActive = false;
  bool public isWhitelistActive = false;
  bool public isDevSaleStarted = false;
  bool public isRevealed = false;

  // Base variables
  uint256 public circulatingSupply;
  uint256 public constant _totalSupply = 210000;
  uint256 public devReserved = 300;

  // Limits
  uint256 internal walletLimit = 210000;

  mapping(address => bool) private whitelist;
  mapping(address => bool) private devAllowlist;
  mapping(address => uint256) private addressIndices;



    constructor() ERC721("LuckyMeta Ticket", "LuckyTicket"){}


    function setPriceDev(uint256 _priceDev)  public onlyOwner {
        priceDev = _priceDev;
    }
    function setPriceWhitelist(uint256 _priceWhitelist)  public onlyOwner {
        priceWhitelist = _priceWhitelist;
    }
    function setPricePublic(uint256 _pricePublic)  public onlyOwner {
        pricePublic = _pricePublic;
    }



    function setFeeOwner(address _feeOwner)  public onlyOwner {
        feeOwner = _feeOwner;
    }

    function setFeeToken(IERC20 _feeToken) public onlyOwner {
        feeToken = _feeToken;
    }

    function chargeFee(address account, uint256 _fee) internal {
        feeToken.safeTransferFrom(account,feeOwner,_fee);
    }


    function setSalePublic() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }
    function setSaleWhitelist() external onlyOwner {
        isWhitelistActive = !isWhitelistActive;
    }
    function setSaleDev() external onlyOwner {
        isDevSaleStarted = !isDevSaleStarted;
    }

    function setReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

//   //Public mint, Whitelist mint, Raffle mint and Dev mint
    function mintPublic(uint256 _amount) external payable  tokensAvailable(_amount) callerIsUser(){
        address minter = msg.sender;
        require(isPublicSaleActive, "Public sale not started");
        require(addressIndices[minter] + _amount <= walletLimit, "Max wallet mint limit reached");

        for (uint256 i = 0; i < _amount; i++) {
            ++addressIndices[minter];
            _safeMint(minter, ++circulatingSupply);
            feeToken.safeTransferFrom(msg.sender,feeOwner,pricePublic);

        }
    }

    function mintWhitelist(uint256 _amount) external payable  tokensAvailable(_amount)  startedWhitelistSale()  callerIsUser()  {
        address minter = msg.sender;
        require(whitelist[minter] == true, "Not allowed to whitelist mint");
        require(addressIndices[minter] + _amount <= walletLimit, "Max wallet mint limit reached");

        if(addressIndices[minter] + _amount >= walletLimit) {
            whitelist[minter] = false;
        }

        for(uint256 i = 0; i < _amount; i++) {
            ++addressIndices[minter];
            _safeMint(minter, ++circulatingSupply);
            feeToken.safeTransferFrom(msg.sender,feeOwner,priceWhitelist);
        }
    }

    function mintDev(uint256 _amount) external payable tokensAvailable(_amount)  startedDevSale()   callerIsUser() {
        address minter = msg.sender;
        require(devAllowlist[minter] == true, "Not allowed");
        require(addressIndices[minter] + _amount <= walletLimit, "Max wallet mint limit reached");
        require(devReserved - _amount > 0, "Dev sale sold out");

        if(addressIndices[minter] + _amount >= walletLimit) {
            devAllowlist[minter] = false;
        }

        for(uint256 i = 0; i < _amount; i++) {
            --devReserved;
            ++addressIndices[minter];
            _safeMint(minter, ++circulatingSupply);
            if(priceDev>0){
                feeToken.safeTransferFrom(msg.sender,feeOwner,priceDev);
            }
        }

    }


    function giveTicket(address from,address to, uint256[] calldata _tokenIds) public virtual {
        for(uint256 i = 0; i < _tokenIds.length; i++){
            uint256 tokenId=_tokenIds[i];
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
            _transfer(from, to, tokenId);
        }
    }

    function approveBatch(address to, uint256[] calldata _tokenIds) public virtual{
        for(uint256 i = 0; i < _tokenIds.length; i++){
            uint256 tokenId=_tokenIds[i];
             super.approve(to, tokenId);
        }
    }

    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721,ERC721URIStorage) returns (string memory) {
            tokenId;
         return isRevealed ? string(abi.encodePacked(baseURI, '/', Strings.toString(0), endingPrefix)) : baseURI;
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

    function tokensRemaining() public view returns (uint256) {
        return _totalSupply - circulatingSupply;
    }


    function isWhitelistSaleAllowed() public view returns(bool) {
        return whitelist[msg.sender] == true;
    }
    function isDevSaleAllowed() public view returns(bool) {
        return devAllowlist[msg.sender] == true;
    }


    function addToWhitelist(address[] calldata _whitelistMinters) external onlyOwner {
        for(uint256 i = 0; i < _whitelistMinters.length; i++)
        whitelist[_whitelistMinters[i]] = true;
    }

    function addToDevList(address[] calldata _devSaleMinters) external onlyOwner {
        for(uint256 i = 0; i < _devSaleMinters.length; i++)
        devAllowlist[_devSaleMinters[i]] = true;
    }

    function totalSupply() public override view returns (uint256) {
        return circulatingSupply;
    }

    function burn( uint256 _tokenId) external onlyOwner validNFToken(_tokenId){
        circulatingSupply--;
        _burn(_tokenId);
    }

    //MODIFIERS
    modifier tokensAvailable(uint256 _amount) {
        require(_amount <= tokensRemaining(), "Try minting less tokens");
        _;
    }

    modifier startedWhitelistSale() {
        require(isWhitelistActive == true, "Whitelist sale is not started");
        _;
    }
    modifier startedDevSale() {
        require(isDevSaleStarted == true, "Dev sale not started");
        _;
    }

    function setDevReserveds(uint256 _amount) external onlyOwner {
        devReserved = _amount;
    }
     
    function setWalletLimit(uint256 _newLimit) external onlyOwner {
        walletLimit = _newLimit;
    }
    function unlistWhitelistMinter(address[] calldata _minters) external onlyOwner {
        for(uint256 i = 0; i < _minters.length; i++)
        whitelist[_minters[i]] = false;
    }

    /**
    * @dev Guarantees that _tokenId is a valid Token.
    * @param _tokenId ID of the NFT to validate.
    */
    modifier validNFToken(uint256 _tokenId){
        require(ownerOf(_tokenId) != address(0));
        _;
    }
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

}
