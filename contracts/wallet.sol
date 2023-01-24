//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract Wallet is Ownable{
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

    modifier tokenExist(bytes32 ticker){
        //using require to check if ticker exist before proceeding with the deposit
        //!= address(0), because is uninitialise token address (0x000000000000000), 
        require(tokenMapping[ticker].tokenAddress != address(0), "Token Does Not Exist!");
        _;
    }

    //onlyOwner is from Ownable.sol library, signifying only owner of wallet can addToken
    function addToken(bytes32 ticker, address tokenAddress) onlyOwner external{
        tokenMapping[ticker] = Token(ticker, tokenAddress);
        tokenList.push(ticker);
    }

    //tokenExist is a custom modifier used to check if a token exist
    function deposit(uint amount, bytes32 ticker) tokenExist(ticker) external{
        //transferFrom function is used to transfer from msg.sender to address(this)
        IERC20(tokenMapping[ticker].tokenAddress).transferFrom(msg.sender, address(this), amount);

        balances[msg.sender][ticker] = balances[msg.sender][ticker].add(amount);
    }

    function withdraw(uint amount, bytes32 ticker) tokenExist(ticker) external{        
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