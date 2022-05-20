// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library OrderLib {
    
    struct Order {
        uint tokenId;
        uint amount;
        address seller;
    }
    
    function add(Order[] storage orders, mapping(uint=>uint) storage orderIndex, uint tokenId, uint amount, address account) internal returns(uint orderId) {
        
        orderId = orders.length;
        
        orders.push(Order({
            tokenId: tokenId,
            amount:  amount,
            seller:  account
        }));
        
        orderIndex[tokenId] = orderId;
    }
    
    function remove(Order[] storage orders, mapping(uint=>uint) storage orderIndex, uint tokenId) internal returns(Order memory order) {
        
        uint orderId = orderIndex[tokenId];
        
        uint lastIndex = orders.length - 1;
        
        order = orders[orderId];
        
        require(order.tokenId == tokenId, "error tokenId");
        
        if(orderId != lastIndex) {
            
            Order memory lastOrder = orders[lastIndex];
            
            orders[orderId] = lastOrder;
            
            orderIndex[lastOrder.tokenId] = orderId;
            
        }
        
        orders.pop();
        
        delete orderIndex[order.tokenId];
    }
}