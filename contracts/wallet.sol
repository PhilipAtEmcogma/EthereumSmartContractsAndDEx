//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Wallet{
    using SafeMath for uint256;

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

    function deposit(uint amount, bytes32 ticker) external{

    }

    function withdraw(uint amount, bytes32 ticker) external{
        //check if the token actually exist before processing the withdraw process
        //!= address(0), because is uninitialise token address (0x000000000000000), 
        require(tokenMapping[ticker].tokenAddress != address(0));        
        
        //use require to make sure sender have enough amount of token to proceed withdraw
        //if insufficient, throw error message.  else proceed to the next step
        require(balances[msg.sender][ticker] >= amount, "Insufficient Balance");



        //.sub() is a Safe Math funrtion from openzepplin library (SafeMath.sol)
        //use to prevent possible overflow and underflow from occuring.
        balances[msg.sender][ticker] = balances[msg.sender][ticker].sub(amount);
        //transfer token from DEx to owner
        IERC20(tokenMapping[ticker].tokenAddress).transfer(msg.sender, amount);
    }
}