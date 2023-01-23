//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Wallet{

    struct Token{
        bytes32 ticker;
        address tokenAddress;
    }

    //use double mapping to store balances of token
    //second mapping on the right use to store token ticker, can use string or bytes32
    mapping(address => mapping(bytes32 => uint256)) public balances;
}