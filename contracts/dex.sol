//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

//Dex inherect from Wallet since there's alot of similarity between so can recycle some function
contract Dex is Wallet{

    enum Side{
        BUY,
        SELL
    }

    struct Order{
        uint id;
        address trader;
        Side side;
        bytes32 ticker;
        uint amount;
        uint price;
    }

    //1 order book for buy, 1 order book for sell.  use mapping to store
    //the 1st mapping points to asset, 2nd mapping points to the action taken and in order book
    mapping(bytes32 => mapping(uint => Order[]));

    function getOrderBook(bytes32 tocker, Side side) view public returns(Order[] memory){
        return orderBook[ticker][uint(side)];
    }

    function createLimitOrder(){
        
    }
}