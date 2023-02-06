// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "hardhat/console.sol";

import "./interface/IIglooFiV1VaultsMultiSignedMessages.sol";


/**
 * @title IglooFiV1VaultsMultiSignedMessages
*/
contract IglooFiV1VaultsMultiSignedMessages is
	IIglooFiV1VaultsMultiSignedMessages
{
	// [mapping][internal]
	mapping (address => mapping (bytes => bytes32)) internal _messageToSignedMessage;

	mapping (address => mapping (bytes32 => uint256)) internal _signedMessageVotes;
	
	mapping (address => mapping (bytes32 => mapping (address => bool))) internal _signedMessagesVoterVoted;


	function messageToSignedMessage(address vaultAddress, bytes memory message)
		public
		view
		returns (bytes32)
	{
		return _messageToSignedMessage[vaultAddress][message];
	}
	
	function signedMessageVotes(address vaultAddress, bytes32 signedMessage)
		public
		view
		returns (uint256)
	{
		return _signedMessageVotes[vaultAddress][signedMessage];
	}


	function signMessage(address voter, bytes memory message)
		external
	{
		bytes32 signedMessage = ECDSA.toEthSignedMessageHash(message);

		if (_messageToSignedMessage[msg.sender][message] == 0)
		{
			_messageToSignedMessage[msg.sender][message] = signedMessage;
		}

		if (_signedMessagesVoterVoted[msg.sender][signedMessage][voter] == false)
		{
			// [add] `_signedMessagesVoterVoted` voted address
			_signedMessagesVoterVoted[msg.sender][signedMessage][voter] = true;

			// [increment] Value in `_signedMessageVotes`
			_signedMessageVotes[msg.sender][signedMessage] += 1;
		}
	}
}