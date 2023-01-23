//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Wallet{
    //struct for storing token ticker and address
    struct Token{
        bytes32 ticker;
        address tokenAddress;
    }

    mapping(bytes32 => Token) public tokenMapping;
    //array to store all token ticker
    bytes32[] public tokenList;

    //use double mapping to store balances of token
    //second mapping on the right use to store token ticker, can use string or bytes32
    //this mapping is used to store balances for all users
    mapping(address => mapping(bytes32 => uint256)) public balances;

    function addToken(bytes32 ticker, address tokenAddress) external{
        tokenMapping[ticker] = Token(ticker, tokenAddress);
        tokenList.push(ticker);
    }
}