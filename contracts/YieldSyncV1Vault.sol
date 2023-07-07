// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { IYieldSyncV1Vault, ITransferRequestProtocol, TransferRequest } from "./interface/IYieldSyncV1Vault.sol";
import { IYieldSyncV1VaultAccessControl } from "./interface/IYieldSyncV1VaultAccessControl.sol";


contract YieldSyncV1Vault is
	IERC1271,
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


	address public override immutable YieldSyncV1VaultAccessControl;

	address public override signatureProtocol;
	address public override transferRequestProtocol;

	bool public override processTransferRequestLocked;

	mapping (
		uint256 transferRequestId => TransferRequest transferRequest
	) internal _transferRequestId_transferRequest;


	constructor (
		address _YieldSyncV1VaultAccessControl,
		address _transferRequestProtocol,
		address _signatureProtocol,
		address[] memory admins,
		address[] memory members
	)
	{
		YieldSyncV1VaultAccessControl = _YieldSyncV1VaultAccessControl;

		signatureProtocol = _signatureProtocol;
		transferRequestProtocol = _transferRequestProtocol;

		for (uint i = 0; i < admins.length; i++)
		{
			IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).adminAdd(address(this), admins[i]);
		}

		for (uint i = 0; i < members.length; i++)
		{
			IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).memberAdd(address(this), members[i]);
		}

		processTransferRequestLocked = false;
	}


	modifier validYieldSyncV1Vault_transferRequestId_transferRequest(uint256 transferRequestId)
	{
		TransferRequest memory transferRequest = ITransferRequestProtocol(
			transferRequestProtocol
		).yieldSyncV1Vault_transferRequestId_transferRequest(address(this), transferRequestId);

		require(transferRequest.amount > 0, "No TransferRequest found");

		_;
	}

	modifier accessAdmin()
	{
		(bool admin,) = IYieldSyncV1VaultAccessControl(
			YieldSyncV1VaultAccessControl
		).yieldSyncV1Vault_participant_access(
			address(this),
			msg.sender
		);

		require(admin, "!admin");

		_;
	}

	modifier accessMember()
	{
		(, bool member) = IYieldSyncV1VaultAccessControl(
			YieldSyncV1VaultAccessControl
		).yieldSyncV1Vault_participant_access(
			address(this),
			msg.sender
		);

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
	function adminAdd(address targetAddress)
		public
		override
		accessAdmin()
	{
		IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).adminAdd(address(this), targetAddress);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function adminRemove(address admin)
		public
		override
		accessAdmin()
	{
		IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).adminRemove(address(this), admin);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function memberAdd(address targetAddress)
		public
		override
		accessAdmin()
	{
		IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).memberAdd(address(this), targetAddress);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function memberRemove(address member)
		public
		override
		accessAdmin()
	{
		IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).memberRemove(address(this), member);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function signatureProtocol__update(address _signatureProtocol)
		public
		override
		accessAdmin()
	{
		signatureProtocol = _signatureProtocol;

		emit UpdatedSignatureProtocol(signatureProtocol);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function transferRequestProtocol__update(address _transferRequestProtocol)
		public
		override
		accessAdmin()
	{
		transferRequestProtocol = _transferRequestProtocol;

		emit UpdatedSignatureProtocol(transferRequestProtocol);
	}


	/// @inheritdoc IYieldSyncV1Vault
	function yieldSyncV1Vault_transferRequestId_transferRequestProcess(uint256 transferRequestId)
		public
		override
		accessMember()
		validYieldSyncV1Vault_transferRequestId_transferRequest(transferRequestId)
	{
		(bool readyToBeProcessed, bool approved, string memory message) = ITransferRequestProtocol(
			transferRequestProtocol
		).yieldSyncV1Vault_transferRequestId_transferRequestStatus(
			address(this),
			transferRequestId
		);

		require(readyToBeProcessed, message);

		processTransferRequestLocked = true;

		if (approved)
		{
			TransferRequest memory transferRequest = ITransferRequestProtocol(
				transferRequestProtocol
			).yieldSyncV1Vault_transferRequestId_transferRequest(address(this), transferRequestId);

			if (transferRequest.forERC20 && !transferRequest.forERC721)
			{
				if (IERC20(transferRequest.token).balanceOf(address(this)) >= transferRequest.amount)
				{
					// [ERC20-transfer]
					IERC20(transferRequest.token).transfer(transferRequest.to, transferRequest.amount);
				}
				else
				{
					emit ProcessTransferRequestFailed(transferRequestId);
				}
			}

			if (!transferRequest.forERC20 && transferRequest.forERC721)
			{
				if (IERC721(transferRequest.token).ownerOf(transferRequest.tokenId) == address(this))
				{
					// [ERC721-transfer]
					IERC721(transferRequest.token).transferFrom(
						address(this),
						transferRequest.to,
						transferRequest.tokenId
					);
				}
				else
				{
					emit ProcessTransferRequestFailed(transferRequestId);
				}
			}

			if (!transferRequest.forERC20 && !transferRequest.forERC721)
			{
				// [transfer]
				(bool success, ) = transferRequest.to.call{
					value: transferRequest.amount
				}("");

				if (!success)
				{
					emit ProcessTransferRequestFailed(transferRequestId);
				}
			}

			emit TokensTransferred(msg.sender, transferRequest.to, transferRequest.amount);
		}

		ITransferRequestProtocol(transferRequestProtocol).yieldSyncV1Vault_transferRequestId_transferRequestProcess(
			address(this),
			transferRequestId
		);

		processTransferRequestLocked = false;
	}

	/// @inheritdoc IYieldSyncV1Vault
	function renounceMembership()
		public
		override
		accessMember()
	{
		IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).memberRemove(address(this), msg.sender);
	}
}
