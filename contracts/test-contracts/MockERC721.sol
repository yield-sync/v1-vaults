// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract MockERC721 is ERC721 {
	constructor() ERC721("MockERC721", "MOCKERC721") {
		_safeMint(msg.sender, 1);
		_safeMint(msg.sender, 2);
		_safeMint(msg.sender, 3);
		_safeMint(msg.sender, 4);
		_safeMint(msg.sender, 5);
	}
}
