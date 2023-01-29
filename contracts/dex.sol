//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import "./wallet.sol";

//Dex inherect from Wallet since there's alot of similarity between so can recycle some function
contract Dex is Wallet{

    using SafeMath for uint256;

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

    uint public nexOrderId = 0; //increment by whenever a order comes in regardless of if its buy/sell

    //double mapping, the 1st mapping points to asset, 2nd mapping points to the action taken and in order book
    mapping(bytes32 => mapping(uint => Order[])) public orderBook;

    function getOrderBook(bytes32 ticker, Side side) view public returns(Order[] memory){
        return orderBook[ticker][uint(side)];
    }

    function createLimitOrder(Side side, bytes32 ticker, uint amount, uint price) public{
        //proceed the buy Limit Order if there's only enough Eth to do so
        if(side == Side.BUY){
            require(balances[msg.sender]["ETH"] >= amount.mul(price));
        }
        //proceed the sell Limit order if there's enough said token to sell
        else if(side == Side.SELL){
            require(balances[msg.sender][ticker] >= amount);
        }

        //remeber, storage, means that the arrary isn't store in memory 
        //(i.e. doesn't cost gas as much if any), but makes a copy via referencing
        Order[] storage orders = orderBook[ticker][uint (side)]; //convert side to unit because array can't take enum
        //pushing the order into the orderbook
        orders.push(
            Order(nexOrderId,msg.sender,side,ticker,amount,price)
        );

        //use bubble sort to sort the orderbooks
        //if orders.length > 0, i = orders.length -1, else i =0
        uint i = orders.length > 0 ? orders.length - 1 : 0;

        //for BUY limit order the smallest offer is at the end of the orderbook
        //then proceed to the largest offer at the start of the orderbook
        //largest buy offer is filled first
        if(side == Side.BUY){
            //continue until we reach the 1st item in the orderbook
            while(i > 0){
                //break if orderbook is already sorted, even if the new order comes in
                if(orders[i - 1].price > orders[i].price){
                    break;
                }

                //actual swap part
                Order memory orderToMove = orders[i - 1]; //save a copy of orders[i-1] to memory called orderToMove 
                orders[i - 1] = orders[i]; //replace value in orders[i-1] by orders[i]
                orders[i] = orderToMove; //replace value in order[i] by orderToMove
                i--; //move to the next pair to compare
            }
        }
        //for SELL limit order the smallest offer is at the start of the orderbook
        //then proceed to the largest offer at the end of the orderbook
        //smallest sell offer filled first
        else if(side == Side.SELL){
            while(i > 0){
                if(orders[i - 1].price < orders[i].price) {
                    break;
                }
                Order memory orderToMove = orders[i - 1];
                orders[i - 1] = orders[i];
                orders[i] = orderToMove;
                i--;
            }
        }

        nexOrderId++;
    }

    function createMarketOrder(Side side, bytes32 ticker, uint amount) public{
        
    }
}