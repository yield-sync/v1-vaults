// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract MockERC20 is ERC20 {
	constructor() ERC20("MockERC20", "MOCKERC20") {
		_mint(msg.sender, 100_000_000_000);
	}
}
