// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "hardhat/console.sol";

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


	function createSignedMessage()//bytes memory message)
		external
		view
	{
		console.log("caller", address(msg.sender));

		//bytes32 _messageHash = ECDSA.toEthSignedMessageHash(message);

		//if (_signedMessagesVoterVoted[msg.sender][_messageHash][msg.sender] == false) {
			// [add] `_signedMessagesVoterVoted` voted address
			//_signedMessagesVoterVoted[_messageHash][msg.sender] = true;

			// [increment] Value in `_signedMessageVotes`
			//_signedMessageVotes[_messageHash]++;
		//}
	}
}