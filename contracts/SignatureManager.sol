// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


import { IIglooFiV1Vault } from "@igloo-fi/v1-sdk/contracts/interface/IIglooFiV1Vault.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";

import { ISignatureManager, MessageHashData } from "./interface/ISignatureManager.sol";


/**
 * @title SignatureManager
*/
contract SignatureManager is
	IERC1271,
	ISignatureManager
{
	bytes32 public constant VOTER = keccak256("VOTER");
	bytes4 public constant ERC1271_MAGIC_VALUE = 0x1626ba7e;


	// [mapping][internal]
	mapping (address => bytes32[]) internal _vaultMessageHashes;
	mapping (address => mapping (bytes32 => MessageHashData)) internal _vaultMessageHashData;


	/// @inheritdoc IERC1271
	function isValidSignature(bytes32 _messageHash, bytes memory _signature)
		public
		view
		override
		returns (bytes4 magicValue)
	{
		address recovered = ECDSA.recover(ECDSA.toEthSignedMessageHash(_messageHash), _signature);


		MessageHashData memory messageHashData = _vaultMessageHashData[msg.sender][_messageHash];

		return (
			recovered == messageHashData.signer &&
			messageHashData.signatureCount >= IIglooFiV1Vault(msg.sender).requiredVoteCount()
		) ? ERC1271_MAGIC_VALUE : bytes4(0);
	}


	
	/// @inheritdoc ISignatureManager
	function recoverSigner(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
		public
		pure
		returns (address)
	{
		return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), v, r, s);
	}

	
	/// @inheritdoc ISignatureManager
	function vaultMessageHashes(address _iglooFiV1Vault)
		public
		view
		returns (bytes32[] memory)
	{
		return _vaultMessageHashes[_iglooFiV1Vault];
	}

	
	/// @inheritdoc ISignatureManager
	function vaultMessageHashData(address _iglooFiV1Vault, bytes32 _messageHash)
		public
		view
		returns (MessageHashData memory)
	{
		return _vaultMessageHashData[_iglooFiV1Vault][_messageHash];
	}

	
	/// @inheritdoc ISignatureManager
	function signMessageHash(address _iglooFiV1Vault, bytes32 _messageHash, bytes memory _signature)
		public
	{
		require(IIglooFiV1Vault(_iglooFiV1Vault).hasRole(VOTER, msg.sender), "!auth");

		MessageHashData memory m = _vaultMessageHashData[_iglooFiV1Vault][_messageHash];

		for (uint i = 0; i < m.signedVoters.length; i++) {
			require(m.signedVoters[i] != msg.sender, "Already signed");
		}

		if (m.signer == address(0)) {
			address[] memory initialsignedVoters;

			address recovered = ECDSA.recover(ECDSA.toEthSignedMessageHash(_messageHash), _signature);

			require(IIglooFiV1Vault(_iglooFiV1Vault).hasRole(VOTER, recovered), "!auth");

			_vaultMessageHashData[_iglooFiV1Vault][_messageHash] = MessageHashData({
				signature: _signature,
				signer: recovered,
				signedVoters: initialsignedVoters,
				signatureCount: 0
			});

			_vaultMessageHashes[_iglooFiV1Vault].push(_messageHash);
		}

		_vaultMessageHashData[_iglooFiV1Vault][_messageHash].signedVoters.push(msg.sender);
		_vaultMessageHashData[_iglooFiV1Vault][_messageHash].signatureCount++;
	}
}