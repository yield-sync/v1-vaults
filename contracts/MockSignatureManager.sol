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
	* @notice Signs the given hash and returns it
	* @param _message {string} to be hashed
	*/
	function ECDSA_toEthSignedMessageHash(bytes memory _message)
		public
		pure
		returns (bytes32)
	{
		return ECDSA.toEthSignedMessageHash(_message);
	}

	/**
	 * @notice Get hash of TypedData
	 * @param _domainSeparator {bytes32}
	 * @param _structHash {bytes32}
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

	/**
	* @notice Verify signature
	* @param _signer {address}
	* @param _message {string}
	* @param _signature {bytes}
	*/
	function verifySignature(address _signer, string memory _message, bytes memory _signature)
		public
		view
		returns (bool)
	{
		bytes32 messageHash = keccak256(abi.encodePacked(_message));
		bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);

		console.logBytes32(ethSignedMessageHash);

		return ECDSA.recover(ethSignedMessageHash, _signature) == _signer;
	}
}