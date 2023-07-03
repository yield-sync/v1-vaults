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
		address[] memory admins,
		address[] memory members,
		address _transferRequestProtocol,
		address _signatureProtocol
	)
	{
		YieldSyncV1VaultAccessControl = _YieldSyncV1VaultAccessControl;

		for (uint i = 0; i < admins.length; i++)
		{
			IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).addAdmin(address(this), admins[i]);
		}

		for (uint i = 0; i < members.length; i++)
		{
			IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).addMember(address(this), members[i]);
		}

		signatureProtocol = _signatureProtocol;
		transferRequestProtocol = _transferRequestProtocol;

		processTransferRequestLocked = false;
	}


	modifier validTransferRequest(uint256 transferRequestId)
	{
		TransferRequest memory transferRequest = ITransferRequestProtocol(
			transferRequestProtocol
		).yieldSyncV1Vault_transferRequestId_transferRequest(address(this), transferRequestId);

		require(transferRequest.amount > 0, "No TransferRequest found");

		_;
	}

	modifier onlyAdmin()
	{
		(bool admin,) = IYieldSyncV1VaultAccessControl(
			YieldSyncV1VaultAccessControl
		).participant_yieldSyncV1Vault_access(
			msg.sender,
			address(this)
		);

		require(admin, "!admin");

		_;
	}

	modifier onlyMember()
	{
		(, bool member) = IYieldSyncV1VaultAccessControl(
			YieldSyncV1VaultAccessControl
		).participant_yieldSyncV1Vault_access(
			msg.sender,
			address(this)
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
	function addAdmin(address targetAddress)
		public
		override
		onlyAdmin()
	{
		IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).addAdmin(address(this), targetAddress);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function removeAdmin(address admin)
		public
		override
		onlyAdmin()
	{
		IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).removeAdmin(address(this), admin);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function addMember(address targetAddress)
		public
		override
		onlyAdmin()
	{
		IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).addMember(address(this), targetAddress);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function removeMember(address member)
		public
		override
		onlyAdmin()
	{
		IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).removeMember(address(this), member);
	}


	/// @inheritdoc IYieldSyncV1Vault
	function updateSignatureProtocol(address _signatureProtocol)
		public
		override
		onlyAdmin()
	{
		signatureProtocol = _signatureProtocol;

		emit UpdatedSignatureProtocol(signatureProtocol);
	}


	/// @inheritdoc IYieldSyncV1Vault
	function processTransferRequest(uint256 transferRequestId)
		public
		override
		onlyMember()
		validTransferRequest(transferRequestId)
	{
		(
			bool readyToBeProcessed,
			bool approved,
			string memory message
		) = ITransferRequestProtocol(transferRequestProtocol).transferRequestStatus(
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

		processTransferRequestLocked = false;
	}

	/// @inheritdoc IYieldSyncV1Vault
	function renounceMembership()
		public
		override
		onlyMember()
	{
		IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).removeMember(address(this), msg.sender);
	}
}
