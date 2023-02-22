// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


import { IIglooFiV1Vault } from "@igloo-fi/v1-sdk/contracts/interface/IIglooFiV1Vault.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "hardhat/console.sol";


struct MessageHashData {
	bytes signature;
	address signer;
	address[] signedVoters;
	uint256 signatureCount;
}


/**
 * @title MockSignatureManager
*/
contract MockSignatureManager is
	IERC1271
{
	bytes32 public constant VOTER = keccak256("VOTER");
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
		address recovered = ECDSA.recover(ECDSA.toEthSignedMessageHash(_messageHash), _signature);

		console.log(recovered);

		MessageHashData memory messageHashData = vaultMessageHashData[msg.sender][_messageHash];

		if (
			recovered != messageHashData.signer &&
			messageHashData.signatureCount >= IIglooFiV1Vault(msg.sender).requiredVoteCount()
		)
		{
			return ERC1271_MAGIC_VALUE;
		}
		else
		{
			//return bytes4(0);
			return ERC1271_MAGIC_VALUE;
		}
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


	function signMessageHash(address iglooFiV1Vault, bytes32 _messageHash, bytes memory _signature)
		public
		returns (bool)
	{
		require(IIglooFiV1Vault(iglooFiV1Vault).hasRole(VOTER, msg.sender), "!auth");

		MessageHashData memory m = vaultMessageHashData[iglooFiV1Vault][_messageHash];

		for (uint i = 0; i < m.signedVoters.length; i++) {
			require(m.signedVoters[i] != msg.sender, "Already signed");
		}

		if (m.signer == address(0)) {
			address[] memory initialsignedVoters;

			address recovered = ECDSA.recover(ECDSA.toEthSignedMessageHash(_messageHash), _signature);

			require(IIglooFiV1Vault(iglooFiV1Vault).hasRole(VOTER, recovered), "!auth");

			vaultMessageHashData[iglooFiV1Vault][_messageHash] = MessageHashData({
				signature: _signature,
				signer: recovered,
				signedVoters: initialsignedVoters,
				signatureCount: 0
			});
		}

		vaultMessageHashData[iglooFiV1Vault][_messageHash].signedVoters.push(msg.sender);
		vaultMessageHashData[iglooFiV1Vault][_messageHash].signatureCount++;

		return true;
	}
}