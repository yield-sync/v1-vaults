// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IAccessControlEnumerable } from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IYieldSyncV1Vault } from "@yield-sync/v1-sdk/contracts/interface/IYieldSyncV1Vault.sol";

import {
	ISignatureProtocol,
	IYieldSyncV1ASignatureProtocol,
	IYieldSyncV1VaultRegistry,
	MessageHashData,
	MessageHashVote
} from "./interface/IYieldSyncV1ASignatureProtocol.sol";


contract YieldSyncV1ASignatureProtocol is
	Pausable,
	ISignatureProtocol,
	IYieldSyncV1ASignatureProtocol
{
	address public immutable override YieldSyncGovernance;

	bytes4 public constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

	IYieldSyncV1VaultRegistry public immutable override YieldSyncV1VaultRegistry;

	mapping (address yieldSyncV1Vault => bytes32[] messageHash) internal _vaultMessageHashes;

	mapping (address yieldSyncV1Vault => uint256 signaturesRequired) internal _yieldSyncV1Vault_signaturesRequired;

	mapping (
		address yieldSyncV1Vault => mapping (bytes32 messageHash => MessageHashData messageHashData)
	) internal _yieldSyncV1Vault_messageHash_messageHashData;

	mapping (
		address yieldSyncV1Vault => mapping (bytes32 messageHash => MessageHashVote messageHashVote)
	) internal _yieldSyncV1Vault_messageHash_messageHashVote;


	modifier contractYieldSyncGovernance(bytes32 _role)
	{
		require(IAccessControlEnumerable(YieldSyncGovernance).hasRole(_role, msg.sender), "!auth");

		_;
	}

	modifier contractYieldSyncV1Vault(address _yieldSyncV1Vault)
	{
		require(msg.sender == _yieldSyncV1Vault, "!_yieldSyncV1Vault");

		_;
	}


	constructor (address _YieldSyncGovernance, address _YieldSyncV1VaultRegistry)
	{
		YieldSyncGovernance = _YieldSyncGovernance;

		YieldSyncV1VaultRegistry = IYieldSyncV1VaultRegistry(_YieldSyncV1VaultRegistry);

		_pause();
	}


	/// @inheritdoc ISignatureProtocol
	function isValidSignature(bytes32 _messageHash, bytes memory _signature)
		public
		view
		override
		returns (bytes4 magicValue)
	{
		address recovered = ECDSA.recover(ECDSA.toEthSignedMessageHash(_messageHash), _signature);

		MessageHashData memory messageHashData = _yieldSyncV1Vault_messageHash_messageHashData[msg.sender][_messageHash];

		MessageHashVote memory messageHashVote = _yieldSyncV1Vault_messageHash_messageHashVote[msg.sender][_messageHash];

		return (
			_vaultMessageHashes[msg.sender][_vaultMessageHashes[msg.sender].length -1] == _messageHash &&
			messageHashData.signer == recovered &&
			messageHashVote.signatureCount >= _yieldSyncV1Vault_signaturesRequired[msg.sender]
		) ? ERC1271_MAGIC_VALUE : bytes4(0);
	}


	/// @inheritdoc ISignatureProtocol
	function yieldSyncV1VaultInitialize(address _initiator, address _yieldSyncV1Vault)
		public
		override
		contractYieldSyncV1Vault(_yieldSyncV1Vault)
	{
		require(
			_yieldSyncV1Vault_signaturesRequired[_initiator] > 0,
			"!_yieldSyncV1Vault_signaturesRequired[_initiator]"
		);

		_yieldSyncV1Vault_signaturesRequired[_yieldSyncV1Vault] = _yieldSyncV1Vault_signaturesRequired[_initiator];
	}


	/// @inheritdoc IYieldSyncV1ASignatureProtocol
	function vaultMessageHashes(address _yieldSyncV1Vault)
		public
		view
		override
		returns (bytes32[] memory vaultMessageHashes_)
	{
		return _vaultMessageHashes[_yieldSyncV1Vault];
	}

	/// @inheritdoc IYieldSyncV1ASignatureProtocol
	function yieldSyncV1Vault_signaturesRequired(address _purposer)
		public
		view
		override
		returns (uint256 signaturesRequired_)
	{
		return _yieldSyncV1Vault_signaturesRequired[_purposer];
	}

	/// @inheritdoc IYieldSyncV1ASignatureProtocol
	function yieldSyncV1Vault_messageHash_messageHashData(address _yieldSyncV1Vault, bytes32 _messageHash)
		public
		view
		override
		returns (MessageHashData memory messageHashData_)
	{
		return _yieldSyncV1Vault_messageHash_messageHashData[_yieldSyncV1Vault][_messageHash];
	}

	/// @inheritdoc IYieldSyncV1ASignatureProtocol
	function yieldSyncV1Vault_messageHash_messageHashVote(address _yieldSyncV1Vault, bytes32 _messageHash)
		public
		view
		override
		returns (MessageHashVote memory messageHashVote_)
	{
		return _yieldSyncV1Vault_messageHash_messageHashVote[_yieldSyncV1Vault][_messageHash];
	}


	/// @inheritdoc IYieldSyncV1ASignatureProtocol
	function yieldSyncV1Vault_signaturesRequiredUpdate(uint256 _signatureRequired)
		public
		override
	{
		_yieldSyncV1Vault_signaturesRequired[msg.sender] = _signatureRequired;
	}

	/// @inheritdoc IYieldSyncV1ASignatureProtocol
	function signMessageHash(address _yieldSyncV1Vault, bytes32 _messageHash, bytes memory _signature)
		public
		override
		whenNotPaused()
	{
		(, bool member) = YieldSyncV1VaultRegistry.yieldSyncV1Vault_participant_access(_yieldSyncV1Vault, msg.sender);

		require(member, "!member");

		MessageHashData memory messageHashData = _yieldSyncV1Vault_messageHash_messageHashData[_yieldSyncV1Vault][
			_messageHash
		];

		MessageHashVote memory messageHashVote = _yieldSyncV1Vault_messageHash_messageHashVote[_yieldSyncV1Vault][
			_messageHash
		];

		for (uint i = 0; i < messageHashVote.signedMembers.length; i++)
		{
			require(messageHashVote.signedMembers[i] != msg.sender, "Already signed");
		}

		if (messageHashData.signer == address(0))
		{
			address[] memory initialsignedMembers;

			address recovered = ECDSA.recover(ECDSA.toEthSignedMessageHash(_messageHash), _signature);

			(, bool recoveredIsMember) = YieldSyncV1VaultRegistry.yieldSyncV1Vault_participant_access(
				_yieldSyncV1Vault,
				recovered
			);

			require(recoveredIsMember, "!member");

			_yieldSyncV1Vault_messageHash_messageHashData[_yieldSyncV1Vault][_messageHash] = MessageHashData({
				signature: _signature,
				signer: recovered
			});

			_yieldSyncV1Vault_messageHash_messageHashVote[_yieldSyncV1Vault][_messageHash] = MessageHashVote({
				signedMembers: initialsignedMembers,
				signatureCount: 0
			});

			_vaultMessageHashes[_yieldSyncV1Vault].push(_messageHash);
		}

		_yieldSyncV1Vault_messageHash_messageHashVote[_yieldSyncV1Vault][_messageHash].signedMembers.push(msg.sender);

		_yieldSyncV1Vault_messageHash_messageHashVote[_yieldSyncV1Vault][_messageHash].signatureCount++;
	}


	/// @inheritdoc IYieldSyncV1ASignatureProtocol
	function updatePause(bool _pause)
		public
		override
		contractYieldSyncGovernance(bytes32(0))
	{
		if (_pause)
		{
			super._pause();
		}
		else
		{
			super._unpause();
		}
	}
}
