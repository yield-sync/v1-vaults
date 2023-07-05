// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IAccessControlEnumerable } from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IYieldSyncV1Vault } from "@yield-sync/v1-sdk/contracts/interface/IYieldSyncV1Vault.sol";

import { ISignatureProtocol, MessageHashData } from "./interface/ISignatureProtocol.sol";
import { IYieldSyncV1SignatureProtocol, MessageHashVote } from "./interface/IYieldSyncV1SignatureProtocol.sol";
import { IYieldSyncV1VaultAccessControl } from "./interface/IYieldSyncV1VaultAccessControl.sol";


contract YieldSyncV1SignatureProtocol is
	Pausable,
	ISignatureProtocol,
	IYieldSyncV1SignatureProtocol
{
	address public override immutable YieldSyncGovernance;
	address public override immutable YieldSyncV1VaultAccessControl;

	bytes4 public constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

	mapping (address yieldSyncV1VaultAddress => bytes32[] messageHash) internal _vaultMessageHashes;

	mapping (address purposer => uint256 signaturesRequired) internal _purposer_signaturesRequired;

	mapping (
		address yieldSyncV1VaultAddress => uint256 signaturesRequired
	) internal _yieldSyncV1VaultAddress_signaturesRequired;

	mapping (
		address yieldSyncV1VaultAddress => mapping (bytes32 messageHash => MessageHashData messageHashData)
	) internal _yieldSyncV1VaultAddress_messageHash_messageHashData;

	mapping (
		address yieldSyncV1VaultAddress => mapping (bytes32 messageHash => MessageHashVote messageHashVote)
	) internal _yieldSyncV1VaultAddress_messageHash_messageHashVote;

	constructor (address _YieldSyncGovernance, address _YieldSyncV1VaultAccessControl)
	{
		_pause();

		YieldSyncGovernance = _YieldSyncGovernance;
		YieldSyncV1VaultAccessControl = _YieldSyncV1VaultAccessControl;
	}


	modifier contract_YieldSyncGovernance(bytes32 role)
	{
		require(IAccessControlEnumerable(YieldSyncGovernance).hasRole(role, msg.sender), "!auth");

		_;
	}


	/// @inheritdoc ISignatureProtocol
	function isValidSignature(bytes32 _messageHash, bytes memory _signature)
		public
		view
		override
		returns (bytes4 magicValue)
	{
		address recovered = ECDSA.recover(ECDSA.toEthSignedMessageHash(_messageHash), _signature);

		MessageHashData memory messageHashData = _yieldSyncV1VaultAddress_messageHash_messageHashData[msg.sender][
			_messageHash
		];

		MessageHashVote memory messageHashVote = _yieldSyncV1VaultAddress_messageHash_messageHashVote[msg.sender][
			_messageHash
		];

		return (
			_vaultMessageHashes[msg.sender][_vaultMessageHashes[msg.sender].length -1] == _messageHash &&
			messageHashData.signer == recovered &&
			messageHashVote.signatureCount >= _yieldSyncV1VaultAddress_signaturesRequired[msg.sender]
		) ? ERC1271_MAGIC_VALUE : bytes4(0);
	}


	/// @inheritdoc ISignatureProtocol
	function initializeYieldSyncV1Vault(address purposer, address yieldSyncV1VaultAddress)
		public
		override
	{
		_yieldSyncV1VaultAddress_signaturesRequired[yieldSyncV1VaultAddress] = _purposer_signaturesRequired[
			purposer
		];
	}


	/// @inheritdoc IYieldSyncV1SignatureProtocol
	function vaultMessageHashes(address yieldSyncV1VaultAddress)
		public
		view
		override
		returns (bytes32[] memory)
	{
		return _vaultMessageHashes[yieldSyncV1VaultAddress];
	}

	/// @inheritdoc IYieldSyncV1SignatureProtocol
	function purposer_signaturesRequired(address purposer)
		public
		view
		override
		returns (uint256)
	{
		return _purposer_signaturesRequired[purposer];
	}

	/// @inheritdoc IYieldSyncV1SignatureProtocol
	function yieldSyncV1VaultAddress_messageHash_messageHashData(address yieldSyncV1VaultAddress, bytes32 messageHash)
		public
		view
		override
		returns (MessageHashData memory)
	{
		return _yieldSyncV1VaultAddress_messageHash_messageHashData[yieldSyncV1VaultAddress][messageHash];
	}

	/// @inheritdoc IYieldSyncV1SignatureProtocol
	function yieldSyncV1VaultAddress_messageHash_messageHashVote(address yieldSyncV1VaultAddress, bytes32 messageHash)
		public
		view
		override
		returns (MessageHashVote memory)
	{
		return _yieldSyncV1VaultAddress_messageHash_messageHashVote[yieldSyncV1VaultAddress][messageHash];
	}


	/// @inheritdoc IYieldSyncV1SignatureProtocol
	function update_purposer_signaturesRequired(uint256 signatureRequired)
		public
		override
	{
		_purposer_signaturesRequired[msg.sender] = signatureRequired;
	}

	/// @inheritdoc IYieldSyncV1SignatureProtocol
	function signMessageHash(address yieldSyncV1VaultAddress, bytes32 messageHash, bytes memory signature)
		public
		override
		whenNotPaused()
	{
		(, bool member) = IYieldSyncV1VaultAccessControl(
			YieldSyncV1VaultAccessControl
		).yieldSyncV1Vault_participant_access(
			yieldSyncV1VaultAddress,
			msg.sender
		);

		require(member, "!member");

		MessageHashData memory messageHashData = _yieldSyncV1VaultAddress_messageHash_messageHashData[
			yieldSyncV1VaultAddress
		][
			messageHash
		];

		MessageHashVote memory messageHashVote = _yieldSyncV1VaultAddress_messageHash_messageHashVote[
			yieldSyncV1VaultAddress
		][
			messageHash
		];

		for (uint i = 0; i < messageHashVote.signedMembers.length; i++)
		{
			require(messageHashVote.signedMembers[i] != msg.sender, "Already signed");
		}

		if (messageHashData.signer == address(0))
		{
			address[] memory initialsignedMembers;

			address recovered = ECDSA.recover(ECDSA.toEthSignedMessageHash(messageHash), signature);

			(
				,
				bool recoveredIsMember
			) = IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).yieldSyncV1Vault_participant_access(
				yieldSyncV1VaultAddress,
				recovered
			);

			require(recoveredIsMember, "!member");

			_yieldSyncV1VaultAddress_messageHash_messageHashData[yieldSyncV1VaultAddress][
				messageHash
			] = MessageHashData({
				signature: signature,
				signer: recovered
			});

			_yieldSyncV1VaultAddress_messageHash_messageHashVote[yieldSyncV1VaultAddress][
				messageHash
			] = MessageHashVote({
				signedMembers: initialsignedMembers,
				signatureCount: 0
			});

			_vaultMessageHashes[yieldSyncV1VaultAddress].push(messageHash);
		}

		_yieldSyncV1VaultAddress_messageHash_messageHashVote[yieldSyncV1VaultAddress][messageHash].signedMembers.push(
			msg.sender
		);

		_yieldSyncV1VaultAddress_messageHash_messageHashVote[yieldSyncV1VaultAddress][messageHash].signatureCount++;
	}


	/// @inheritdoc IYieldSyncV1SignatureProtocol
	function updatePause(bool pause)
		public
		override
		contract_YieldSyncGovernance(bytes32(0))
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
