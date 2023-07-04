// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";


struct MessageHashData
{
	bytes signature;
	address signer;
}


interface ISignatureProtocol is
	IERC1271
{
	/// @inheritdoc IERC1271
	function isValidSignature(bytes32 _messageHash, bytes memory _signature)
		external
		view
		override
		returns (bytes4 magicValue)
	;


	/**
	* @param purposer {address}
	* @param yieldSyncV1VaultAddress {address}
	*/
	function initializeYieldSyncV1Vault(address purposer, address yieldSyncV1VaultAddress)
		external
	;
}
