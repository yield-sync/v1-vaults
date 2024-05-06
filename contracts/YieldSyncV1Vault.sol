// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { ISignatureProtocol } from "./interface/ISignatureProtocol.sol";
import { ITransferRequestProtocol, TransferRequest } from "./interface/ITransferRequestProtocol.sol";
import { IYieldSyncV1Vault, IYieldSyncV1VaultRegistry } from "./interface/IYieldSyncV1Vault.sol";


contract YieldSyncV1Vault is
	IERC1271,
	ReentrancyGuard,
	IYieldSyncV1Vault
{
	receive ()
		external
		payable
		override
	{}


	fallback ()
		external
		payable
		override
	{}


	address public override signatureProtocol;
	address public override transferRequestProtocol;

	IYieldSyncV1VaultRegistry public immutable override YieldSyncV1VaultRegistry;

	mapping (uint256 transferRequestId => TransferRequest transferRequest) internal _transferRequestId_transferRequest;


	constructor (
		address _deployer,
		address _signatureProtocol,
		address _transferRequestProtocol,
		address _YieldSyncV1VaultRegistry,
		address[] memory _admins,
		address[] memory _members
	)
	{
		signatureProtocol = _signatureProtocol;
		transferRequestProtocol = _transferRequestProtocol;

		YieldSyncV1VaultRegistry = IYieldSyncV1VaultRegistry(_YieldSyncV1VaultRegistry);

		if (signatureProtocol != address(0))
		{
			ISignatureProtocol(signatureProtocol).yieldSyncV1VaultInitialize(_deployer, address(this));
		}

		if (transferRequestProtocol != address(0))
		{
			ITransferRequestProtocol(transferRequestProtocol).yieldSyncV1VaultInitialize(_deployer, address(this));
		}

		for (uint i = 0; i < _admins.length; i++)
		{
			YieldSyncV1VaultRegistry.adminAdd(address(this), _admins[i]);
		}

		for (uint i = 0; i < _members.length; i++)
		{
			YieldSyncV1VaultRegistry.memberAdd(address(this), _members[i]);
		}
	}


	modifier validYieldSyncV1Vault_transferRequestId_transferRequest(uint256 _transferRequestId)
	{
		TransferRequest memory transferRequest = ITransferRequestProtocol(
			transferRequestProtocol
		).yieldSyncV1Vault_transferRequestId_transferRequest(
			address(this),
			_transferRequestId
		);

		require(transferRequest.amount > 0, "No TransferRequest found");

		_;
	}

	modifier accessAdmin()
	{
		(bool admin,) = YieldSyncV1VaultRegistry.yieldSyncV1Vault_participant_access(address(this), msg.sender);

		require(admin, "!_admin");

		_;
	}

	modifier accessMember()
	{
		(, bool member) = YieldSyncV1VaultRegistry.yieldSyncV1Vault_participant_access(address(this), msg.sender);

		require(member, "!member");

		_;
	}


	/// @inheritdoc IERC1271
	function isValidSignature(bytes32 _messageHash, bytes memory _signature)
		public
		view
		override
		returns (bytes4 magicValue)
	{
		return IERC1271(signatureProtocol).isValidSignature(_messageHash, _signature);
	}


	/// @inheritdoc IYieldSyncV1Vault
	function adminAdd(address _target)
		public
		override
		accessAdmin()
	{
		YieldSyncV1VaultRegistry.adminAdd(address(this), _target);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function adminRemove(address _admin)
		public
		override
		accessAdmin()
	{
		YieldSyncV1VaultRegistry.adminRemove(address(this), _admin);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function memberAdd(address _target)
		public
		override
		accessAdmin()
	{
		YieldSyncV1VaultRegistry.memberAdd(address(this), _target);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function memberRemove(address _member)
		public
		override
		accessAdmin()
	{
		YieldSyncV1VaultRegistry.memberRemove(address(this), _member);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function signatureProtocolUpdate(address _signatureProtocol)
		public
		override
		accessAdmin()
	{
		ISignatureProtocol(_signatureProtocol).yieldSyncV1VaultInitialize(msg.sender, address(this));

		signatureProtocol = _signatureProtocol;

		emit UpdatedSignatureProtocol(signatureProtocol);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function transferRequestProtocolUpdate(address _transferRequestProtocol)
		public
		override
		accessAdmin()
	{
		ITransferRequestProtocol(_transferRequestProtocol).yieldSyncV1VaultInitialize(msg.sender, address(this));

		transferRequestProtocol = _transferRequestProtocol;

		emit UpdatedSignatureProtocol(transferRequestProtocol);
	}


	/// @inheritdoc IYieldSyncV1Vault
	function renounceMembership()
		public
		override
		accessMember()
	{
		YieldSyncV1VaultRegistry.memberRemove(address(this), msg.sender);
	}


	/// @inheritdoc IYieldSyncV1Vault
	function yieldSyncV1Vault_transferRequestId_transferRequestProcess(uint256 _transferRequestId)
		public
		override
		nonReentrant()
		validYieldSyncV1Vault_transferRequestId_transferRequest(_transferRequestId)
	{
		(bool readyToBeProcessed, bool approved, string memory message) = ITransferRequestProtocol(
			transferRequestProtocol
		).yieldSyncV1Vault_transferRequestId_transferRequestStatus(
			address(this),
			_transferRequestId
		);

		require(readyToBeProcessed, message);

		if (approved)
		{
			TransferRequest memory transferRequest = ITransferRequestProtocol(
				transferRequestProtocol
			).yieldSyncV1Vault_transferRequestId_transferRequest(
				address(this),
				_transferRequestId
			);

			if (transferRequest.forERC20 && !transferRequest.forERC721)
			{
				if (IERC20(transferRequest.token).balanceOf(address(this)) >= transferRequest.amount)
				{
					IERC20(transferRequest.token).transfer(transferRequest.to, transferRequest.amount);
				}
				else
				{
					emit ProcessTransferRequestFailed(_transferRequestId);
				}
			}

			if (!transferRequest.forERC20 && transferRequest.forERC721)
			{
				if (IERC721(transferRequest.token).ownerOf(transferRequest.tokenId) == address(this))
				{
					IERC721(transferRequest.token).transferFrom(address(this), transferRequest.to, transferRequest.tokenId);
				}
				else
				{
					emit ProcessTransferRequestFailed(_transferRequestId);
				}
			}

			if (!transferRequest.forERC20 && !transferRequest.forERC721)
			{
				(bool success, ) = transferRequest.to.call{ value: transferRequest.amount }("");

				if (!success)
				{
					emit ProcessTransferRequestFailed(_transferRequestId);
				}
			}

			emit TokensTransferred(msg.sender, transferRequest.to, transferRequest.amount);
		}

		ITransferRequestProtocol(transferRequestProtocol).yieldSyncV1Vault_transferRequestId_transferRequestProcess(
			address(this),
			_transferRequestId
		);
	}
}
