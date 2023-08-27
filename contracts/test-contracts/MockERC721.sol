// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract MockERC721 is ERC721
{
	constructor ()
		ERC721("MockERC721", "MOCKERC721")
	{
		for (uint256 i = 0; i < 15; i++) {
			_safeMint(msg.sender, i);
		}
	}

	function safeMint(uint256 tokenId)
		public
	{
		_safeMint(msg.sender, tokenId);
	}
}
