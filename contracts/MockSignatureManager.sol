// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "hardhat/console.sol";


contract MockSignatureManager is
	IERC1271
{
	bytes4 public constant ERC1271_MAGIC_VALUE = 0x1626ba7e;


	/// @inheritdoc IERC1271
	function isValidSignature(bytes32 _messageHash, bytes memory _signature)
		public
		view
		override
		returns (bytes4 magicValue)
	{	
		if (true)
		{
			return ERC1271_MAGIC_VALUE;
		}
		else
		{
			console.logBytes(_signature);
			console.logBytes32(_messageHash);
			return bytes4(0);
		}
	}
}