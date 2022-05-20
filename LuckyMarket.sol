// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./LuckyFee.sol";
import "./library/OrderLib.sol";
import "./interfaces/ILucky.sol";

contract LuckyMarket is IERC721Receiver, LuckyFee {

    using OrderLib for OrderLib.Order[];

    OrderLib.Order[] public orders;

    mapping(address=>uint) public orderCount;

    mapping(uint=>uint) public orderIndex;

    ILucky public lucky;

    event OrderCreate(uint indexed tokenId, address indexed _seller, uint _price);
    event OrderCancel(uint indexed tokenId);
    event OrderBid(uint indexed tokenId, address indexed _buyer);
   
    constructor(IERC20 _TOKEN,uint _feeRate,address _feeOwner, ILucky _lucky) LuckyFee(_TOKEN,_feeRate,_feeOwner) {
        lucky = _lucky;
    }


    function onERC721Received(
        address ,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public virtual override returns (bytes4) {

        require(address(lucky) == msg.sender,"token is not in whiteList");

        uint price = abi.decode(data,(uint));
        createOrder(from,tokenId,price);
        return this.onERC721Received.selector;
    }


    function createOrder(address account, uint tokenId,uint price) private {
        require(price>0,"invalid price");
        orders.add(orderIndex,tokenId,price,account);
        orderCount[account]++;
        emit OrderCreate(tokenId,account,price);
    }

    function cancelOrder(uint tokenId) public {

        OrderLib.Order memory order = orders.remove(orderIndex,tokenId);

        orderCount[order.seller]--;

        require(msg.sender==order.seller,"not good");

        lucky.safeTransferFrom(address(this),msg.sender,order.tokenId);

        emit OrderCancel(tokenId);
    }

    function bidOrder(uint tokenId) public {

        OrderLib.Order memory order = orders.remove(orderIndex,tokenId);

        orderCount[order.seller]--;

        chargeFee(msg.sender, order.seller, order.amount);

        lucky.safeTransferFrom(address(this),msg.sender,order.tokenId);

        emit OrderBid(order.tokenId, msg.sender);
    }

    function getOrderLength() public view returns(uint) {
        return orders.length;
    }

    function getOrders() public view returns(OrderLib.Order[] memory) {
        return orders;
    }

    function getOrders(address account) public view returns (OrderLib.Order[] memory _orders) {

        _orders = new OrderLib.Order[](orderCount[account]);

        uint count;

        for(uint i; i<orders.length; i++) {
            if(orders[i].seller == account) {
                _orders[count] = orders[i];
                count++;
            }
        }

    }

}
