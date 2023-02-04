// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/**
* @title IIglooFiV1VaultsMultiSignedMessages
*/
interface IIglooFiV1VaultsMultiSignedMessages {
	function signedMessageVotes(address vaultAddress, bytes32 _messageHash)
		external
		view
		returns (uint256)
	;

	function createSignedMessage(address voter, bytes memory message) external;
}