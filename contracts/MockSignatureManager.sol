// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


import "@igloo-fi/v1-sdk/contracts/interface/IIglooFiV1Vault.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "hardhat/console.sol";


struct MessageHashData {
	address signer;
	address[] votedVoters;
	uint256 votes;
}


/**
 * @title MockSignatureManager
*/
contract MockSignatureManager is
	IERC1271
{
	bytes4 public constant ERC1271_MAGIC_VALUE = 0x1626ba7e;


	// [mapping][internal]
	mapping (address => bytes32[]) public vaultMessageHashes;
	mapping (address => mapping (bytes32 => MessageHashData)) public vaultMessageHashData;


	/// @inheritdoc IERC1271
	function isValidSignature(bytes32 _messageHash, bytes memory _signature)
		public
		view
		override
		returns (bytes4 magicValue)
	{
		MessageHashData memory messageHashData = vaultMessageHashData[msg.sender][_messageHash];

		address recovered = ECDSA.recover(ECDSA.toEthSignedMessageHash(_messageHash), _signature);

		require(recovered != messageHashData.signer, "!recovered");

		require(
			messageHashData.votes >= IIglooFiV1Vault(msg.sender).requiredVoteCount(),
			"!messageHashData.votes"
		);

		return ERC1271_MAGIC_VALUE;
	}


	function verifyStringSignature(
		string memory message,
		uint8 v,
		bytes32 r,
		bytes32 s
	)
		public
		pure
		returns (address)
	{
		return ECDSA.recover(ECDSA.toEthSignedMessageHash(abi.encodePacked(message)), v, r, s);
	}


	function verifyHashSignature(
		bytes32 hash,
		uint8 v,
		bytes32 r,
		bytes32 s
	)
		public
		pure
		returns (address)
	{
		return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), v, r, s);
	}


	function signMessageHash(address iglooFiV1Vault, bytes32 messageHash)
		public
	{}
}