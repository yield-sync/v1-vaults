// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interface/IIglooFiV1VaultsMultiSignedMessages.sol";

// temp
import "hardhat/console.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title IglooFiV1VaultsMultiSignedMessages
*/
contract IglooFiV1VaultsMultiSignedMessages is
	IIglooFiV1VaultsMultiSignedMessages
{
<<<<<<< HEAD
	// temp
=======
>>>>>>> 8b5b20a61f1368c051dbcb1b3de18aa3f3b15912
	using ECDSA for bytes32;


	// [mapping][internal]
	mapping (address => mapping (bytes => bytes32)) internal _messageToSignedMessage;
	mapping (address => mapping (bytes32 => uint256)) internal _signedMessageVotes;
	mapping (address => mapping (bytes32 => mapping (address => bool))) internal _signedMessagesVoterVoted;


	/// @inheritdoc IIglooFiV1VaultsMultiSignedMessages
	function messageToSignedMessage(address vaultAddress, bytes memory message)
		public
		view
		returns (bytes32)
	{
		return _messageToSignedMessage[vaultAddress][message];
	}
	
	/// @inheritdoc IIglooFiV1VaultsMultiSignedMessages
	function signedMessageVotes(address vaultAddress, bytes32 signedMessage)
		public
		view
		returns (uint256)
	{
		return _signedMessageVotes[vaultAddress][signedMessage];
	}


	/// @inheritdoc IIglooFiV1VaultsMultiSignedMessages
	function signMessage(address voter, bytes memory message)
		external
	{
		// Sign message
		bytes32 signedMessage = ECDSA.toEthSignedMessageHash(message);

		if (_messageToSignedMessage[msg.sender][message] == 0)
		{
			// [add] `_messageToSignedMessage` signed message
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


	function randomHash() public view returns(bytes32) {
        return keccak256(abi.encodePacked(block.number));
    }

	function getSignedMessage(bytes memory _message)
		public
		pure
		returns (bytes32)
	{
		return ECDSA.toEthSignedMessageHash(_message);
	}


	function recoverSigner(bytes32 _messageHash, bytes memory _signature)
		public
		view
		returns (address)
	{
		address signer = ECDSA.recover(_messageHash, _signature);

		console.log(signer, msg.sender);

		return signer;
	}
}