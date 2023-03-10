// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IIglooFiGovernance } from "@igloo-fi/v1-sdk/contracts/interface/IIglooFiGovernance.sol";
import { IIglooFiV1Vault } from "@igloo-fi/v1-sdk/contracts/interface/IIglooFiV1Vault.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { ISignatureManager, MessageHashData } from "./interface/ISignatureManager.sol";
import { IIglooFiV1VaultRecord } from "./interface/IIglooFiV1VaultRecord.sol";


/**
* @title SignatureManager
*/
contract SignatureManager is
	IERC1271,
	Pausable,
	ISignatureManager
{
	// [address]
	address public override iglooFiGovernance;
	address public iglooFiV1VaultRecord;
	
	// [bytes4]
	bytes4 public constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

	// [mapping]
	mapping (address iglooFiV1VaultAddress => bytes32[] messageHash) internal _vaultMessageHashes;
	mapping (
		address iglooFiV1VaultAddress => mapping (bytes32 messageHash => MessageHashData messageHashData)
	) internal _vaultMessageHashData;


	constructor (address _iglooFiGovernance, address _iglooFiV1VaultRecord)
	{
		_pause();

		iglooFiGovernance = _iglooFiGovernance;
		iglooFiV1VaultRecord = _iglooFiV1VaultRecord;
	}


	modifier onlyIglooFiGovernanceAdmin() {
		require(
			IIglooFiGovernance(iglooFiGovernance).hasRole(
				IIglooFiGovernance(iglooFiGovernance).governanceRoles("DEFAULT_ADMIN_ROLE"),
				msg.sender
			),
			"!auth"
		);

		_;
	}


	/// @inheritdoc IERC1271
	function isValidSignature(bytes32 _messageHash, bytes memory _signature)
		public
		view
		override
		returns (bytes4 magicValue)
	{
		address recovered = ECDSA.recover(ECDSA.toEthSignedMessageHash(_messageHash), _signature);

		MessageHashData memory vMHD = _vaultMessageHashData[msg.sender][_messageHash];

		return (
			_vaultMessageHashes[msg.sender][_vaultMessageHashes[msg.sender].length -1] == _messageHash &&
			vMHD.signer == recovered &&
			vMHD.signatureCount >= IIglooFiV1Vault(payable(msg.sender)).forVoteCountRequired()
		) ? ERC1271_MAGIC_VALUE : bytes4(0);
	}


	/// @inheritdoc ISignatureManager
	function vaultMessageHashes(address iglooFiV1VaultAddress)
		public
		view
		override
		returns (bytes32[] memory)
	{
		return _vaultMessageHashes[iglooFiV1VaultAddress];
	}
	
	/// @inheritdoc ISignatureManager
	function vaultMessageHashData(address iglooFiV1VaultAddress, bytes32 messageHash)
		public
		view
		override
		returns (MessageHashData memory)
	{
		return _vaultMessageHashData[iglooFiV1VaultAddress][messageHash];
	}

	
	/// @inheritdoc ISignatureManager
	function signMessageHash(address iglooFiV1VaultAddress, bytes32 messageHash, bytes memory signature)
		public
		override
		whenNotPaused()
	{
		(, bool msgSenderIsMember) = IIglooFiV1VaultRecord(iglooFiV1VaultRecord).participant_iglooFiV1Vault_access(
			msg.sender,
			iglooFiV1VaultAddress
		);

		require(msgSenderIsMember, "!member");

		MessageHashData memory vMHD = _vaultMessageHashData[iglooFiV1VaultAddress][messageHash];

		for (uint i = 0; i < vMHD.signedVoters.length; i++) {
			require(vMHD.signedVoters[i] != msg.sender, "Already signed");
		}

		if (vMHD.signer == address(0)) {
			address[] memory initialsignedVoters;

			address recovered = ECDSA.recover(ECDSA.toEthSignedMessageHash(messageHash), signature);

			(, bool recoveredIsMember) = IIglooFiV1VaultRecord(iglooFiV1VaultRecord).participant_iglooFiV1Vault_access(
				recovered,
				iglooFiV1VaultAddress
			);

			require(recoveredIsMember, "!member");

			_vaultMessageHashData[iglooFiV1VaultAddress][messageHash] = MessageHashData({
				signature: signature,
				signer: recovered,
				signedVoters: initialsignedVoters,
				signatureCount: 0
			});

			_vaultMessageHashes[iglooFiV1VaultAddress].push(messageHash);
		}

		_vaultMessageHashData[iglooFiV1VaultAddress][messageHash].signedVoters.push(msg.sender);
		_vaultMessageHashData[iglooFiV1VaultAddress][messageHash].signatureCount++;
	}


	/// @inheritdoc ISignatureManager
	function updatePause(bool pause)
		public
		override
		onlyIglooFiGovernanceAdmin()
	{
		if (pause)
		{
			_pause();
		}
		else
		{
			_unpause();
		}
	}
}