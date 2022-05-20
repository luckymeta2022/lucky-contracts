// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Random.sol";

interface ILuckyUpdatable {
    function lmgForLevelup(uint256 roleLevel) external returns(uint256 goldRequired);
    function lmtForLevelup(uint256 roleLevel) external returns(uint256 tokenRequired);

    function lmgForLogin(uint256 roleLever) external returns(uint256 goldReceived);
    function lmtForLogin(uint256 roleLever) external returns(uint256 goldReceived);
}

interface ILuckyGold {
    function balanceOf(address account) external view returns (uint256);
    function mint(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
    function approve(address spender, uint256 amount) external;
}

interface ILuckyTicket {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address);
}

interface ILuckyNFT {
    function balanceOf(address owner) external view returns (uint256);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function safeMint(address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address);
}

contract LuckyFi is IERC721Receiver, Ownable {
    using Strings for uint256;
    using Random for uint256;
    using Address for address;

    uint256 constant private DAY = 1 days;
    uint256 constant public RARE_CONTAINER = 10000;
    uint256 constant private RANGE = 10;


    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private feeOwner= 0x000000000000000000000000000000000000dEaD;
    uint256 private feeRate = 5;
    address private dataAddress = 0xc91D87934C7Ec7Bf8B6178f070F1a228920a9f1e;

    uint256 public nextId = 1;
    uint256 private pointer = 0;
    uint256 private randomNum;
    uint256 private totalRare = 0;
    uint256 private totalNorm = 0;

    mapping(uint256 => uint256) private creatTime;
    mapping(uint256 => uint256) private level;
    mapping(uint256 => mapping(uint256 => bool)) private isLog;
    mapping(uint256 => bool)    private isFixed;
    mapping(uint256 => uint256) private isRare;
    mapping(uint256 => uint256) private lmgcost;
    mapping(uint256 => uint256) private lmtcost;
    mapping(uint256 => uint256) private lmgbonus;
    mapping(uint256 => uint256) private lmtbonus;
    mapping(address => uint256[]) private rareSet;
    mapping(address => uint256[]) private mintedIds; // owner => minted ID

    // event GetMintIds(uint256[] indexed mintId);
    // event Test(uint256 indexed tokenId);


    ILuckyGold private lmg;
    ILuckyGold private lmt;
    ILuckyTicket private luckyTicket;
    ILuckyNFT private luckyNFT;
    ILuckyUpdatable private lu;


    event Levelup(uint256 indexed personId, uint256 indexed newLevel, uint256 goldCost);

    constructor(address _LMG,address _LMT,address _LuckyNFT,address _LuckyTicket) {
        //address _LuckyNFT = 0x8a7136C010Ec4895dAF4645cb8b388802bf81c85;
        //address _LuckyTicket = 0xcdD3181BE71816F7bE2C9D22912ABCc82cd5a6D5;
        //address _LMG = 0xE4d9c756a253D9ea8ecec647fE65ea8011773b5a;
        //address _LMT = 0x93a5c9bD22Af9933d7959580c703A6Fac65608c0;
        // DEAD = 0x000000000000000000000000000000000000dEaD;
        // feeOwner = 0x666D34104A87C10686e342Ad264399CffE3BB7D4;

        lmg = ILuckyGold(_LMG);
        lmt = ILuckyGold(_LMT);
        luckyTicket = ILuckyTicket(_LuckyTicket);
        luckyNFT = ILuckyNFT(_LuckyNFT);
        updateValue(dataAddress);

    }



    function personLog(uint256 personId) public view returns (uint256) {
        return creatTime[personId];
    }

    function personLevel(uint256 personId) public view returns (uint256) {
        return level[personId];
    }

    function personInfo(uint256 _personId) public view returns (uint256 _log, uint256 _isRare, uint256 _level) {
        _log = creatTime[_personId];
        _level = level[_personId];
        _isRare = isRare[_personId];
    }


    function personsOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256[] memory personArray = new uint256[](luckyNFT.balanceOf(_owner));
        for(uint256 i = 0; i < luckyNFT.balanceOf(_owner); i++){
            personArray[i] = luckyNFT.tokenOfOwnerByIndex(_owner, i);
        }
        return personArray;
    }


    function queryIsRare(uint256 _personId) public view returns (uint256) {
        return isRare[_personId];
    }


    function rareNum() public view returns (uint256 _rareExist, uint256 _rareLeft) {
        return (totalRare, RARE_CONTAINER - totalRare);
    }

    function rareOfOwner() public view returns (uint256[] memory) {
        return rareSet[msg.sender];
    }

    function getMintIds(address _owner) public view returns (uint256[] memory) {
        return mintedIds[_owner];
    }



    function BonusTimeLeft(uint256 personId) public view returns (uint256 _time, uint256 _hour, uint256 _minute, uint256 _second) {
        uint256 log_time = block.timestamp;
        uint256 log_day = (log_time - creatTime[personId]) / DAY;
        uint256 next_bonus_time = creatTime[personId] + log_day * DAY + DAY;

        if (isLog[personId][log_day] == false) {
            return (0, 0, 0, 0);
        } else {
            uint256 timeLeft = next_bonus_time - log_time;
            (uint256 hour, uint256 minute, uint256 second) = toHMS(timeLeft);
            return (timeLeft, hour, minute, second);
        }
    }


    function costForLevelup(uint256 personId) public view returns (uint256) {
        if (level[personId] >= 1 && level[personId] <= 9) {
            if(isRare[personId]==1){
                return lmtcost[level[personId]];
            }else{
                 return lmgcost[level[personId]];
            }
        } else {
            return 0;
        }
    }


    function bonusForLogin(uint256 personId) public view returns (uint256) {
        if (level[personId] != 0) {
            if(isRare[personId]==1){
                return lmtbonus[level[personId]];
            }else{
                 return lmgbonus[level[personId]];
            }
        } else {
            return 0;
        }
    }


    function bonusForLoginNext(uint256 personId) public view returns (uint256) {
        if (level[personId] != 0) {
            if(isRare[personId]==1){
                return lmtbonus[level[personId]+1];
            }else{
                 return lmgbonus[level[personId]+1];
            }
        } else {
            return 0;
        }
    }

    function bonusForLoginAll(address _owner) public view returns (uint256) {
        uint256 bonus_all = 0;
        uint256 log_time = block.timestamp;
        for (uint256 index = 0; index < luckyNFT.balanceOf(_owner); index++) {
            uint256 id = luckyNFT.tokenOfOwnerByIndex(_owner, index);
            uint256 log_day = (log_time - creatTime[id]) / DAY;
            if (!isLog[id][log_day]) {
                bonus_all += bonusForLogin(id);
            }
        }
        return bonus_all;
    }


    function readData() internal {
        for (uint256 l = 1; l <= 10; l++){
            lmgbonus[l] = lu.lmgForLogin(l);
            lmtbonus[l] = lu.lmtForLogin(l);
        }
        for (uint256 l = 1; l <= 9; l++){
            lmgcost[l] = lu.lmgForLevelup(l);
            lmtcost[l] = lu.lmtForLevelup(l);
        }
    }


    function toHMS(uint256 _time) internal pure returns (uint256 _hour, uint256 _minute, uint256 _second) {
        uint256 hour = _time / 3600;
        uint256 minute = (_time - hour * 3600) / 60;
        uint256 second = _time - hour * 3600 - minute * 60;
        return (hour, minute, second);
    }


    function initArray(uint256[] storage _mintIds) internal {
        uint256 len = _mintIds.length;
        for (uint256 i = 0; i < len; i++) {
            _mintIds.pop();
        }
    }


    function _mintPerson() internal {
        address _user = msg.sender;
        uint256 _nextId = nextId;
        luckyNFT.safeMint(_user, _nextId);
        fixPerson(_nextId);
        mintedIds[_user].push(_nextId);
        nextId++;
    }

    function _getRarity(uint256 _personId) internal {
        uint256 _rand = random(RANGE);
        if (_rand == block.timestamp % RANGE && totalRare <= RARE_CONTAINER) {
            isRare[_personId] = 1;
            totalRare++;
            rareSet[msg.sender].push(_personId);
        } else {
            isRare[_personId] = 2;
        }
    }


    function creatPersonNFT(uint256 _ticketId) internal {
        // uint256 _rand = random(RANGE);
        address _user = msg.sender;
        require(_user == luckyTicket.ownerOf(_ticketId), "caller is not owner of ticket");
        luckyTicket.transferFrom(_user, DEAD, _ticketId);
        _mintPerson();
        _getRarity(nextId - 1);
    }


    function batchCreatPersonNFT(uint256[] calldata _ticketIdArray) public {
        uint256 _num = _ticketIdArray.length;
        // uint256 _tokenId = 336699;
        initArray(mintedIds[msg.sender]);
        for (uint256 i = 0; i < _num; i++) {
            creatPersonNFT(_ticketIdArray[i]);

        }
        // emit Test(_tokenId);
        // emit GetMintIds(mintedIds[msg.sender]);
    }

    function showRandom() public view returns (uint256 _index, uint256 _random) {
        return (pointer, randomNum);
    }


    function random(uint256 _range) internal returns (uint256) {
        uint256 time_base = uint256(uint64(block.timestamp));
        uint256 addr_base = uint256(uint64(uint160(msg.sender)));
        uint256 _seed = uint256(uint64(time_base * addr_base));
        uint256[] memory _randomArray = _seed.genSeedsUint64(_range);
        randomNum = _randomArray[pointer % _range];
        pointer++;
        return randomNum;
    }


    function fixPerson(uint256 _personId) public {
        require(!isFixed[_personId], "LF: personId is already fixed.");
        creatTime[_personId] = block.timestamp;
        level[_personId] = 1;
        _getRarity(_personId);
        isFixed[_personId] = true;

    }

    function batchFixPersonOfOwner(address _owner) public {
        uint256[] memory ids = personsOfOwner(_owner);
        for (uint256 i = 0; i < ids.length; i++) {
            if (!isFixed[ids[i]]) {
                fixPerson(ids[i]);
            }
        }
    }

    function updateValue(address new_contract) internal {
        lu = ILuckyUpdatable(new_contract);
        readData();
    }


    function _levelupRare(uint256 _personId) internal {
        updateValue(dataAddress);
        address _user = msg.sender;
        uint256 _level = level[_personId];
        uint256 _lmtCost = lu.lmtForLevelup(_level);
        require(_level <= 9, "level reaches max");
        lmt.approve(address(this), _lmtCost);
        lmt.transferFrom(_user, feeOwner, _lmtCost);
        level[_personId] += 1;
        emit Levelup(_personId, _level, _lmtCost);
    }


    function _levelupNorm(uint256 _personId) internal {
        updateValue(dataAddress);
        address _user = msg.sender;
        uint256 _level = level[_personId];
        uint256 _lmgCost = lu.lmgForLevelup(_level);
        require(_level <= 9, "level reaches max");
        lmg.approve(address(this), _lmgCost);
        lmg.transferFrom(_user, feeOwner, _lmgCost);
        level[_personId] += 1;
        emit Levelup(_personId, _level, _lmgCost);
    }


    function levelup(uint256 _personId) public onlyWallet {
        if (isRare[_personId] == 1) {
            _levelupRare(_personId);
        } else if (isRare[_personId] == 2) {
            _levelupNorm(_personId);
        }
    }


    function bonusForRareId(uint256 personId) internal {
        updateValue(dataAddress);
        require(luckyNFT.ownerOf(personId) == msg.sender, "caller is not owner.");
        uint256 _logTime = block.timestamp;
        require(_logTime > creatTime[personId]);
        uint256 _logDay = (_logTime - creatTime[personId]) / DAY;
        require(!isLog[personId][_logDay], "this id takes bonus today already.");
        uint256 _lmtbonus = lu.lmtForLogin(level[personId]);
        require(lmt.balanceOf(address(this)) > 0, "LMT bonus pool is empty");

        lmt.transfer(msg.sender, _lmtbonus*(100-feeRate)/100);

        uint256 fee = _lmtbonus*feeRate/100;

        lmt.transferFrom(msg.sender,feeOwner,fee);
        isLog[personId][_logDay] = true;
    }


    function bonusForNormId(uint256 personId) internal {
        updateValue(dataAddress);
        require(luckyNFT.ownerOf(personId) == msg.sender, "caller is not owner.");
        uint256 _logTime = block.timestamp;
        require(_logTime > creatTime[personId]);
        uint256 _logDay = (_logTime - creatTime[personId]) / DAY;
        require(!isLog[personId][_logDay], "this id takes bonus today already.");
        uint256 _lmgbonus = lu.lmgForLogin(level[personId]);
        require(lmg.balanceOf(address(this)) > 0, "LMT bonus pool is empty");

        lmg.transfer(msg.sender, _lmgbonus*(100-feeRate)/100);

        uint256 fee = _lmgbonus*feeRate/100;

         lmg.transferFrom(msg.sender,feeOwner,fee);
        isLog[personId][_logDay] = true;
    }


    function bonusForIds(uint256[] memory personArray) public {
        uint256 _len = personArray.length;
        for (uint256 i = 0; i < _len; i++) {
            if (isRare[personArray[i]] == 1) {
                bonusForRareId(personArray[i]);
            } else if (isRare[personArray[i]] == 2) {
                bonusForNormId(personArray[i]);
            }
        }
    }


    function bonusForAllId() public {
        address _user = msg.sender;
        bonusForIds(personsOfOwner(_user));
    }



    function newDateAddress(address _new) external onlyOwner {
        dataAddress = _new;
        updateValue(dataAddress);
    }

    function newLuckyNFT(address _new) external onlyOwner(){
        luckyNFT = ILuckyNFT(_new);
    }

    function newLuckyTicket(address _new) external onlyOwner(){
        luckyTicket = ILuckyTicket(_new);
    }

    function newLuckyMetaGold(address _new) external onlyOwner(){
        lmg = ILuckyGold(_new);
    }

    function newLuckyMetaToken(address _new) external onlyOwner(){
        lmt = ILuckyGold(_new);
    }

    function newfeeOwner(address _feeOwner) external onlyOwner(){
        feeOwner = _feeOwner;
    }

    function newfeeRate(uint256 _feeRate) external onlyOwner(){
        feeRate = _feeRate;
    }
    modifier onlyWallet() {
        require(!msg.sender.isContract(), "LF: contracts are not allowed.");
        _;
    }

     
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

}
