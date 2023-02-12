// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "hardhat/console.sol";


/**
 * @title MockSignatureManager
*/
contract MockSignatureManager is
	IERC1271
{
	using ECDSA for bytes32;


	bytes4 public constant ERC1271_MAGIC_VALUE = 0x1626ba7e;


	// [mapping][internal]
	mapping (address => mapping (bytes => bytes32)) internal _messageToSignedMessage;
	mapping (address => mapping (bytes32 => uint256)) internal _signedMessageVotes;
	mapping (address => mapping (bytes32 => mapping (address => bool))) internal _signedMessagesVoterVoted;


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


	/**
	* @notice Total Signs
	* @dev [view-uint256]
	* @dev [!restriction]
	* @param vaultAddress {address}
	* @param signedMessage {bytes32}
	*/
	function signedMessageVotes(address vaultAddress, bytes32 signedMessage)
		public
		view
		returns (uint256)
	{
		return _signedMessageVotes[vaultAddress][signedMessage];
	}


	/**
	* @notice Hashs a given _message
	* @param _message {string} to be hashed
	*/
	function getMessageHash(string memory _message)
		public
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked(_message));
	}

	/**
	* @notice Signs the given hash and returns it
	* @param _messageHash {string} to be hashed
	*/
	function ECDSA_toEthSignedMessageHash(bytes32 _messageHash)
		public
		pure
		returns (bytes32)
	{
		return ECDSA.toEthSignedMessageHash(_messageHash);
	}

	/**
	*/
	function ECDSA_toTypedDataHash(bytes32 _domainSeparator, bytes32 _structHash)
		public
		pure
		returns (bytes32)
	{
		return ECDSA.toTypedDataHash(_domainSeparator, _structHash);
	}

	/**
	* @notice Recovers the signer from a signed message hash
	* @param _ethSignedMessageHash {bytes32}
	* @param _signature {bytes}
	*/
	function ECDSA_recover(bytes32 _ethSignedMessageHash, bytes memory _signature)
		public
		pure
		returns (address)
	{
		return ECDSA.recover(_ethSignedMessageHash, _signature);
	}

	///
	function verify(address _signer, string memory _message, bytes memory _signature)
		public
		pure
		returns (bool)
	{
		bytes32 messageHash = keccak256(abi.encodePacked(_message));
		bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);

		return ECDSA.recover(ethSignedMessageHash, _signature) == _signer;
	}


	///
	function messageToSignedMessage(address vaultAddress, bytes memory message)
		public
		view
		returns (bytes32)
	{
		return _messageToSignedMessage[vaultAddress][message];
	}


	///
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
}