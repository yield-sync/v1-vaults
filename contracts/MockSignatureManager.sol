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
	* @notice Verify signature
	* @param _signer {address}
	* @param _message {string}
	* @param _signature {bytes}
	*/
	function verifySignature(address _signer, string memory _message, bytes memory _signature)
		public
		pure
		returns (bool)
	{
		bytes32 messageHash = keccak256(abi.encodePacked(_message));
		bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);

		return ECDSA.recover(ethSignedMessageHash, _signature) == _signer;
	}


	// Returns the address that signed a given string message
    function verifyString(
		string memory message,
		uint8 v,
		bytes32 r,
		bytes32 s
	)
		public
		view
		returns (address signer)
	{
		console.logBytes32(ECDSA.toEthSignedMessageHash(abi.encodePacked(message)));

		return ECDSA.recover(ECDSA.toEthSignedMessageHash(abi.encodePacked(message)), v, r, s);
    }


	// Returns the address that signed a given string message
	function verifyHash(
		bytes32 hash,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public pure returns (address) {
		return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), v, r, s);
	}
	}