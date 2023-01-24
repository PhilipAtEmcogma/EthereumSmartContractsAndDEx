//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

//a mock token contract that emulates chainlink (LINK)
contract Link is ERC20 {
    constructor() ERC20("Chainlink", "LINK") public{
        _mint(msg.sender, 1000); //mint 1000 mock LINK token
    }
}