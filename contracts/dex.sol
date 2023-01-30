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
        uint filled;
    }

    uint public nextOrderId = 0; //increment by whenever a order comes in regardless of if its buy/sell

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
            Order(nextOrderId, msg.sender, side, ticker, amount, price, 0)
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

        nextOrderId++;
    }

    function createMarketOrder(Side side, bytes32 ticker, uint amount) public{
        //check to see if seller has enough token balance to sell
        if(side == Side.SELL){
            require(balances[msg.sender][ticker] >= amount, "Insuffient Balance");  
        }

        //iterate until orderbook is filled or empty
        //making sure buy order and sell order matches
        uint orderBookSide;
        if(side == Side.BUY){
            //set orderBookSide to 1 (SELL) because we want BULL and SELL order to be balance
            orderBookSide = 1;  
        }
        else{
            //again set side to 0 (BUY) to balance out SELL order
            orderBookSide = 0;
        }

        Order[] storage orders = orderBook[ticker][orderBookSide];
        uint totalFilled;

        //loop until either gone through the order list or orderbook is totally filled
        for(uint256 i = 0; i < orders.length && totalFilled < amount; i++){
            uint leftToFill = amount.sub(totalFilled);
            uint availableToFill = orders[i].amount.sub(orders[i].filled); //order.amount - order.filled
            uint filled = 0;

            //use leftToFill or availableToFill to check how much 
            //can be filled from order[i], thus either partial fill or fully filled
            if(availableToFill > leftToFill){
                filled = leftToFill; //filled the entire market order
            }
            else{
                filled = availableToFill; //fill as much as is availble in order[i]
            }

            totalFilled = totalFilled.add(filled);
            //update the filled orders
            orders[i].filled = orders[i].filled.add(filled);
            uint cost = filled.mul(orders[i].price);

            if(side == Side.BUY){
                //Verify buyer has enough Eth to cover the purchase (require)
                require(balances[msg.sender]["ETH"] >= filled.mul(orders[i].price));
                //msg.sender is the buyer
                //Take ETH from Buyer, and add Token to Buyer
                balances[msg.sender][ticker] = balances[msg.sender][ticker].add(filled);
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].sub(cost); 

                //Take Token from Seller, and add ETH to Seller
                balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].sub(filled);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].add(filled);


            }
            else if(side == Side.SELL){
                //msg.seller is the seller
                //take tokens from seller, and add ETH
                balances[msg.sender][ticker] = balances[msg.sender][ticker].sub(filled);
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].add(cost);

                //takes ETH from buyer, and add token
                balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].sub(filled);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].add(filled);
            }
        }

        //remove 100% filled orders from orderbook,
        //doing this is to try to keep orderbook as short as possible, and thus
        //reducing the gas to store and read it

        while(orders.length > 0 && orders[0].filled == orders[0].amount){
            //remove the top element in the orders array by overwritting every element
            //with the next element in the order list
            for(uint256 i = 0; i < orders.length - 1; i++){
                orders[i] = orders[i +1];
            }

            orders.pop();
        }

    }
}