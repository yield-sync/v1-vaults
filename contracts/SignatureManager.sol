// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IYieldSyncV1Vault } from "@yield-sync/v1-sdk/contracts/interface/IYieldSyncV1Vault.sol";
import { IAccessControlEnumerable } from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { ISignatureManager, MessageHashData } from "./interface/ISignatureManager.sol";
import { IYieldSyncV1VaultAccessControl } from "./interface/IYieldSyncV1VaultAccessControl.sol";


contract SignatureManager is
	IERC1271,
	Pausable,
	ISignatureManager
{
	address public override immutable YieldSyncGovernance;
	address public override immutable YieldSyncV1VaultAccessControl;

	bytes4 public constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

	mapping (address yieldSyncV1VaultAddress => bytes32[] messageHash) internal _vaultMessageHashes;
	mapping (
		address yieldSyncV1VaultAddress => mapping (bytes32 messageHash => MessageHashData messageHashData)
	) internal _vaultMessageHashData;


	constructor (address _YieldSyncGovernance, address _YieldSyncV1VaultAccessControl)
	{
		_pause();

		YieldSyncGovernance = _YieldSyncGovernance;
		YieldSyncV1VaultAccessControl = _YieldSyncV1VaultAccessControl;
	}


	modifier only_YieldSyncGovernance_DEFAULT_ADMIN_ROLE()
	{
		require(IAccessControlEnumerable(YieldSyncGovernance).hasRole(bytes32(0), msg.sender), "!auth");

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
			vMHD.signatureCount >= IYieldSyncV1Vault(payable(msg.sender)).forVoteCountRequired()
		) ? ERC1271_MAGIC_VALUE : bytes4(0);
	}


	/// @inheritdoc ISignatureManager
	function vaultMessageHashes(address yieldSyncV1VaultAddress)
		public
		view
		override
		returns (bytes32[] memory)
	{
		return _vaultMessageHashes[yieldSyncV1VaultAddress];
	}

	/// @inheritdoc ISignatureManager
	function vaultMessageHashData(address yieldSyncV1VaultAddress, bytes32 messageHash)
		public
		view
		override
		returns (MessageHashData memory)
	{
		return _vaultMessageHashData[yieldSyncV1VaultAddress][messageHash];
	}


	/// @inheritdoc ISignatureManager
	function signMessageHash(address yieldSyncV1VaultAddress, bytes32 messageHash, bytes memory signature)
		public
		override
		whenNotPaused()
	{
		(
			,
			bool msgSenderIsMember
		) = IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).participant_yieldSyncV1Vault_access(
			msg.sender,
			yieldSyncV1VaultAddress
		);

		require(msgSenderIsMember, "!member");

		MessageHashData memory vMHD = _vaultMessageHashData[yieldSyncV1VaultAddress][messageHash];

		for (uint i = 0; i < vMHD.signedMembers.length; i++)
		{
			require(vMHD.signedMembers[i] != msg.sender, "Already signed");
		}

		if (vMHD.signer == address(0))
		{
			address[] memory initialsignedMembers;

			address recovered = ECDSA.recover(ECDSA.toEthSignedMessageHash(messageHash), signature);

			(
				,
				bool recoveredIsMember
			) = IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).participant_yieldSyncV1Vault_access(
				recovered,
				yieldSyncV1VaultAddress
			);

			require(recoveredIsMember, "!member");

			_vaultMessageHashData[yieldSyncV1VaultAddress][messageHash] = MessageHashData({
				signature: signature,
				signer: recovered,
				signedMembers: initialsignedMembers,
				signatureCount: 0
			});

			_vaultMessageHashes[yieldSyncV1VaultAddress].push(messageHash);
		}

		_vaultMessageHashData[yieldSyncV1VaultAddress][messageHash].signedMembers.push(msg.sender);
		_vaultMessageHashData[yieldSyncV1VaultAddress][messageHash].signatureCount++;
	}


	/// @inheritdoc ISignatureManager
	function updatePause(bool pause)
		public
		override
		only_YieldSyncGovernance_DEFAULT_ADMIN_ROLE()
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
