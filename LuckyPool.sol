// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IUniswapV2Factory.sol";


contract LuckyPool is Ownable, ERC20 {

    using SafeMath for  uint256;
    using SafeERC20 for IERC20;

    constructor(
        IERC20 _token
        //, uint256 _tokenPerBlock
    ) public  ERC20 ("LuckyMeta Value","LMV"){
        token = _token;
        tokenPerBlock = 0.868055556 *10* 1e18 ;
        startBlock = block.number;
        lastUpdateBlock = block.number;
        initRate();
    }

    struct DepositInfo {
        uint256 amountlp;
        uint256 withdrawTerm;
    }

    struct User {
        uint256 rewardPerTokenPaid;
        mapping(uint=>DepositInfo) deposits;
    }

    struct Pool {
        IERC20 tokenLp;
        bool status;
        uint256 weight;
        uint256 totalAmount;
        uint256 withdrawTerm;
    }

    // The block number when mining starts.

    uint256 public startBlock;

    uint256 public THRESHOLD = 2000000 * 1e18 ;

    uint256 constant public blocksPerHour = 1200 * 3;
    uint256 constant public blocksPerDay = blocksPerHour * 24 ;
    uint256 constant public blocksPerMonth = blocksPerHour * 24 * 30;
    // uint256 public REDUCE_PERIOD = blocksPerMonth * 3;
    uint256 public REDUCE_PERIOD = 86400;



    uint256 internal DIVISOR = 100;
    uint256 internal BASE_INIT = 1000000;
    uint256 internal BASE_RATE = 5;



    uint256 public lastUpdateBlock;
    uint256 public rewardPerTokenStored;


    // 区块奖励
    uint256 public tokenPerBlock;

    uint256 public feeRate = 5;
    address public feeAddress =0x000000000000000000000000000000000000dEaD;


    IERC20  public token;



    Pool[] public pools;
    mapping( uint => uint) public yinit;            //

    mapping(address => uint256) public rewards;
    mapping(address => User) public users;

    event Deposit(address indexed,uint pid, uint amountT);
    event Withdraw(address indexed,uint,uint);
    event WithdrawReward(address index, uint );
    event UpdateReward(address index,uint);

    //初始化rale(计算每年的通缩率)
    function initRate() internal {

        uint curRate = BASE_INIT;       // 1000000
        uint base = 100**11;            // 1e22   =  10000 * 1e18
        for(uint i = 0; i<50; i++) {
            yinit[i] = curRate;
            uint _yrate = yrate(i);
            uint _yLast = curRate.mul(_yrate**11)/base;
            curRate = _yLast.mul(yrate(i+1))/100;
        }
    }


    function yrate(uint _year) public view returns(uint256) {
        uint rate;
        if(_year>=BASE_RATE) {
            rate = 1;
        }else{
            rate = BASE_RATE-_year;
        }
        return 100 - rate;
    }

    function mrate(uint _month) public view returns (uint) {
        uint _year = _month/12;
        uint _yinitRate = yinit[_year];
        uint _yrate = yrate(_year);
        uint _mi = _month%12;
        return _yinitRate.mul(_yrate**_mi)/(100**_mi);
    }


    function qrate(uint _quarter) public view returns (uint) {
        uint _year = _quarter/4;
        uint _yinitRate = yinit[_year];
        uint _yrate = yrate(_year);
        uint _mi = _quarter%4;
        return _yinitRate.mul(_yrate**_mi)/(100**_mi);
    }

    function mint(address _to, uint256 _amount) external {
        _mint(_to,_amount);
    }

    function burn(address _to,uint _amount) public  {
        _burn(_to,_amount);
    }


    function setFeeRate(uint256 _feeRate) public onlyOwner{
        feeRate = _feeRate;
    }

    function setFeeAddress(address _feeAddress) public onlyOwner{
        feeAddress = _feeAddress;
    }


    function setThreshold(uint256 _THRESHOLD) public onlyOwner{
        THRESHOLD = _THRESHOLD;
    }



    function setTokenPerBlock(uint _tokenPerBlock) public onlyOwner {
        updateReward(address(0));
        tokenPerBlock = _tokenPerBlock;
    }

     function add(IERC20 _tokenLp,uint256 _weight,uint256 _withdrawTerm) public onlyOwner {
        pools.push(
            Pool({
                tokenLp: _tokenLp
                ,status: true
                ,totalAmount: 0
                ,weight: _weight
                ,withdrawTerm:_withdrawTerm
            })
        );
    }

     function set( uint256 _pid, bool _status, uint256 _weight ) public onlyOwner {
        pools[_pid].status = _status;
        pools[_pid].weight = _weight;
    }

    function updateAndMint() internal view returns( uint tokenIncr, uint tokenActul ) {
        (uint256 multiplier,uint256 curHash) = getMultiplier(lastUpdateBlock,block.number);
        tokenIncr = multiplier.mul(tokenPerBlock).div(BASE_INIT);

        tokenActul = tokenIncr.mul(curHash).div(THRESHOLD);

    }

    function updateReward(address account) public  {
        require(block.number>startBlock,"not start");
        ( , uint tokenActul ) = updateAndMint();
        rewardPerTokenStored = rewardPerToken(tokenActul);
        lastUpdateBlock = block.number;
        if (account != address(0)) {
            rewards[account] =
                balanceOf(account)
                .mul(
                    rewardPerTokenStored.sub(users[account].rewardPerTokenPaid)
                )
                .div(1e18)
                .add(rewards[account]);

            users[account].rewardPerTokenPaid = rewardPerTokenStored;
        }
        emit UpdateReward(account, rewards[account]);
    }

    function rewardPerToken(uint tokenActul) public view returns(uint256) {
        if (totalSupply() == 0) {
            return 0;
        }
        return  tokenActul.mul(1e18).div(totalSupply());
    }

    function earned(address account) public view returns (uint256) {
        (uint256 multiplier,uint256 curHash) = getMultiplier(lastUpdateBlock,block.number);
        uint tokenActul = multiplier.mul(tokenPerBlock).mul(curHash).div(THRESHOLD).div(BASE_INIT);
        return
            balanceOf(account)
                .mul(
                    rewardPerToken(tokenActul).sub(users[account].rewardPerTokenPaid)
                )
                .div(1e18)
                .add(rewards[account]);
    }


    function poolEarned(address account, uint _pid) public view returns (uint256) {

        (uint256 multiplier,uint256 curHash) = getMultiplier(lastUpdateBlock,block.number);
        uint tokenActul = multiplier.mul(tokenPerBlock).mul(curHash).div(THRESHOLD).div(BASE_INIT);
        uint _balance = users[account].deposits[_pid].amountlp;
        return
            _balance
                .mul(
                    rewardPerToken(tokenActul).sub(users[account].rewardPerTokenPaid)
                )
                .div(1e18);
    }


    function APR(uint _pid) public view returns(uint yopt, uint cic) {
        (uint unitToken,uint256 priceToken) = (1,1);
        Pool storage pool = pools[_pid];
        (uint256 multiplier,) = getMultiplier(block.number,block.number+1);
        yopt = (28800*365*multiplier.mul(tokenPerBlock))*priceToken*pool.weight/100/unitToken/BASE_INIT;
        cic = pool.totalAmount;
        uint _totalSupply = totalSupply();
        yopt = _totalSupply==0?0:yopt*cic/_totalSupply;
    }

    function APRpid(uint _pid) public view returns(uint256 yopt,uint256 multiplier,uint256 curHash) {

        Pool storage pool = pools[_pid];

         ( multiplier, curHash) = getMultiplier(block.number,block.number+1);
        uint _totalSupply = totalSupply();

        uint256 yearblocks = 28800*365;
        uint256  tokenPer  = multiplier*tokenPerBlock*pool.weight/100;

        uint256 cic= pool.totalAmount;
        uint256 oenlp      =  cic==0?0:tokenPer*yearblocks/cic;
        yopt       = _totalSupply==0?0:oenlp.mul(cic).div(_totalSupply)/BASE_INIT;
        if(curHash>THRESHOLD){
            yopt = yopt.mul(curHash).div(THRESHOLD);
        }

    }



    function sqrt(uint256 x) public pure returns(uint256) {
        uint z = (x + 1 ) / 2;
        uint y = x;
        while(z < y){
            y = z;
            z = ( x / z + z ) / 2;
        }
        return y;
    }




    function deposit(uint256 _pid, uint256 _amountT) public  {
        Pool storage pool = pools[_pid];

        updateReward(msg.sender);

        users[msg.sender].deposits[_pid].amountlp = users[msg.sender].deposits[_pid].amountlp.add(_amountT);

        pool.totalAmount = pool.totalAmount.add(_amountT);
        pool.tokenLp.safeTransferFrom(msg.sender, address(this), _amountT);
        _mint(msg.sender,_amountT.mul(pool.weight).div(100));
        emit Deposit(msg.sender, _pid, _amountT);

    }



    function withdraw(uint256 _pid) public  {
        withdrawReward();
        User storage user = users[msg.sender];
        uint256 amountT = user.deposits[_pid].amountlp;

        user.deposits[_pid].amountlp = 0;
        Pool storage pool = pools[_pid];

           pool.tokenLp.safeTransfer(msg.sender, amountT);
           pool.totalAmount = pool.totalAmount.sub(amountT);

        // pool.tokenLp.safeTransfer(msg.sender, amountT.sub(fee));
        // pool.tokenLp.safeTransfer(feeAddress, fee);

        _burn(msg.sender, amountT);

        emit Withdraw(msg.sender,_pid,amountT);
    }




    function withdrawReward() public  {
        updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            uint256 fee = reward.mul(feeRate).div(100);
            safeTokenTransfer(msg.sender,reward.sub(fee));
            safeTokenTransfer(feeAddress, fee);

        }
        emit WithdrawReward(msg.sender,reward);
    }


    function emergencyWithdraw(uint256 _pid) public  {
        User storage user = users[msg.sender];
        uint256 amountT = user.deposits[_pid].amountlp;

        user.deposits[_pid].amountlp = 0;

        Pool storage pool = pools[_pid];
        pool.totalAmount = pool.totalAmount>amountT?pool.totalAmount-amountT:0;


        pool.tokenLp.safeTransfer(msg.sender, amountT);


        _burn(msg.sender, amountT);
         rewards[msg.sender] = 0;
    }

    // Return reward multiplier over the given _from to _to block.

    function getMultiplier(uint256 _from, uint256 _to)
        public  view returns (uint256 multiplier,uint256 curHash) {

        uint fromPeriod = period(_from);
        uint toPeriod   = period(_to);
        uint _startBlock = _from;

        for(;fromPeriod<=toPeriod;fromPeriod++){
            uint _endBlock = bonusEndBlock(fromPeriod);
            if(_to<_endBlock) _endBlock = _to;
            multiplier = multiplier.add(
                _endBlock.sub(_startBlock).mul(mrate(fromPeriod))
            );
            _startBlock = _endBlock;
        }

        curHash = totalSupply();
        if(curHash>THRESHOLD){
            curHash = THRESHOLD;
        }
    }



    function getDeposit(address account,uint pid) public view returns(DepositInfo memory depositInfo) {
        return users[account].deposits[pid];
    }

    function getMinWeight(uint _pid) public view returns(uint256) {
        return pools[_pid].weight;
    }

    function getBalanceOfHash(address account) public view returns(uint poolHash,uint teamHash) {
        for(uint i = 0;i<pools.length;i++) {
            poolHash = poolHash.add(users[account].deposits[i].amountlp);
        }
        teamHash = balanceOf(account).sub(poolHash);
    }


    function bonusEndBlock(uint256 _period) public view returns (uint) {
        return startBlock.add((_period+1).mul(REDUCE_PERIOD));
    }

     
    function period(uint256 blockNumber) public view returns (uint _period) {
        if(blockNumber>startBlock) {
            _period = (blockNumber-startBlock)/REDUCE_PERIOD;
        }
    }



    function poolLength() public view returns (uint256) {
        return pools.length;
    }

    // Safe DOM transfer function, just in case if rounding error causes pool to not have enough DOMS.
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = token.balanceOf(address(this));
        if (_amount > tokenBal) {
            token.transfer(_to, tokenBal);
        } else {
            token.transfer(_to, _amount);
        }
    }


}
