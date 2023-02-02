// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract MockERC20 is ERC20 {
    constructor() ERC20("Mock ERC20", "MOCK") {
        _mint(msg.sender, 100_000_000_000);
    }
}