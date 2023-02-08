// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/**
* @title IIglooFiV1VaultsMultiSignedMessages
*/
interface IIglooFiV1VaultsMultiSignedMessages {
	/**
	* @notice Track signed messages given message
	* @dev [!restriction]
	* @param vaultAddress {adress} Address of vault
	* @param message {bytes} Unsigned message
	*/
	function messageToSignedMessage(address vaultAddress, bytes memory message)
		external
		view
		returns (bytes32)
	;

	/**
	* @notice Total votes of signed messages
	* @dev [!restriction]
	* @param vaultAddress {address} Address of vault
	* @param _messageHash {bytes32} Signed message
	*/
	function signedMessageVotes(address vaultAddress, bytes32 _messageHash)
		external
		view
		returns (uint256)
	;

	/**
	* @notice Sign a Message
	* @dev [!restriction]
	* @param voter {address} Address of voter
	* @param message {bytes} Message to be signed
	*/
	function signMessage(address voter, bytes memory message)
		external
	;
}