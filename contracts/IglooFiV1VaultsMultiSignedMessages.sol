// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interface/IIglooFiV1VaultsMultiSignedMessages.sol";


/**
 * This is where the message signature record should live. This should keep record of who
 * has voted and who has not 
*/
contract IglooFiV1VaultsMultiSignedMessages is
	IIglooFiV1VaultsMultiSignedMessages
{
	// [mapping][internal]
	// Message => votes
	mapping (address => mapping (bytes32 => uint256)) internal _signedMessageVotes;
	mapping (address => mapping (bytes32 => mapping (address => bool))) internal _signedMessagesVoterVoted;


	function signedMessageVotes(address vaultAddress, bytes32 _messageHash)
		public
		view
		returns (uint256)
	{
		return _signedMessageVotes[vaultAddress][_messageHash];
	}


	function createSignedMessage(address voter, bytes memory message)
		external
	{
		bytes32 _messageHash = ECDSA.toEthSignedMessageHash(message);

		if (_signedMessagesVoterVoted[msg.sender][_messageHash][voter] == false) {
			// [add] `_signedMessagesVoterVoted` voted address
			_signedMessagesVoterVoted[msg.sender][_messageHash][voter] = true;

			// [increment] Value in `_signedMessageVotes`
			_signedMessageVotes[msg.sender][_messageHash]++;
		}
	}
}