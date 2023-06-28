// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { IYieldSyncV1Vault, TransferRequest } from "./interface/IYieldSyncV1Vault.sol";
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
	address public override signatureManager;

	bool public override processTransferRequestLocked;

	uint256 public override againstVoteCountRequired;
	uint256 public override forVoteCountRequired;
	uint256 public override transferDelaySeconds;
	uint256 internal _transferRequestIdTracker;
	uint256[] internal _idsOfOpenTransferRequests;

	mapping (
		uint256 transferRequestId => TransferRequest transferRequest
	) internal _transferRequestId_transferRequest;


	constructor (
		address _YieldSyncV1VaultAccessControl,
		address[] memory admins,
		address[] memory members,
		address _signatureManager,
		uint256 _againstVoteCountRequired,
		uint256 _forVoteCountRequired,
		uint256 _transferDelaySeconds
	)
	{
		YieldSyncV1VaultAccessControl = _YieldSyncV1VaultAccessControl;

		require(_forVoteCountRequired > 0, "!_forVoteCountRequired");

		for (uint i = 0; i < admins.length; i++)
		{
			IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).addAdmin(address(this), admins[i]);
		}

		for (uint i = 0; i < members.length; i++)
		{
			IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).addMember(address(this), members[i]);
		}

		signatureManager = _signatureManager;
		processTransferRequestLocked = false;
		againstVoteCountRequired = _againstVoteCountRequired;
		forVoteCountRequired = _forVoteCountRequired;
		transferDelaySeconds = _transferDelaySeconds;

		_transferRequestIdTracker = 0;
	}


	modifier validTransferRequest(uint256 transferRequestId)
	{
		require(_transferRequestId_transferRequest[transferRequestId].amount > 0, "No TransferRequest found");

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


	/**
	* @notice Delete TransferRequest
	* @dev [restriction][internal]
	* @dev [delete] `_transferRequestId_transferRequest` value
	*      [delete] `_idsOfOpenTransferRequests` value
	* @param transferRequestId {uint256}
	* Emits: `DeletedTransferRequest`
	*/
	function _deleteTransferRequest(uint256 transferRequestId)
		internal
	{
		delete _transferRequestId_transferRequest[transferRequestId];

		for (uint256 i = 0; i < _idsOfOpenTransferRequests.length; i++)
		{
			if (_idsOfOpenTransferRequests[i] == transferRequestId)
			{
				_idsOfOpenTransferRequests[i] = _idsOfOpenTransferRequests[_idsOfOpenTransferRequests.length - 1];

				_idsOfOpenTransferRequests.pop();

				break;
			}
		}
	}


	/// @inheritdoc IERC1271
	function isValidSignature(bytes32 _messageHash, bytes memory _signature)
		public
		view
		override
		returns (bytes4 magicValue)
	{
		return IERC1271(signatureManager).isValidSignature(_messageHash, _signature);
	}


	/// @inheritdoc IYieldSyncV1Vault
	function idsOfOpenTransferRequests()
		public
		view
		override
		returns (uint256[] memory)
	{
		return _idsOfOpenTransferRequests;
	}

	/// @inheritdoc IYieldSyncV1Vault
	function transferRequestId_transferRequest(uint256 transferRequestId)
		public
		view
		override
		validTransferRequest(transferRequestId)
		returns (TransferRequest memory)
	{
		return _transferRequestId_transferRequest[transferRequestId];
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
	function deleteTransferRequest(uint256 transferRequestId)
		public
		override
		onlyAdmin()
		validTransferRequest(transferRequestId)
	{
		_deleteTransferRequest(transferRequestId);

		emit DeletedTransferRequest(transferRequestId);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function updateTransferRequest(uint256 transferRequestId, TransferRequest memory __transferRequest)
		public
		override
		onlyAdmin()
		validTransferRequest(transferRequestId)
	{
		_transferRequestId_transferRequest[transferRequestId] = __transferRequest;

		emit UpdatedTransferRequest(__transferRequest);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function updateAgainstVoteCountRequired(uint256 _againstVoteCountRequired)
		public
		override
		onlyAdmin()
	{
		require(_againstVoteCountRequired > 0, "!_againstVoteCountRequired");

		againstVoteCountRequired = _againstVoteCountRequired;

		emit UpdatedAgainstVoteCountRequired(againstVoteCountRequired);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function updateForVoteCountRequired(uint256 _forVoteCountRequired)
		public
		override
		onlyAdmin()
	{
		require(_forVoteCountRequired > 0, "!_forVoteCountRequired");

		forVoteCountRequired = _forVoteCountRequired;

		emit UpdatedForVoteCountRequired(forVoteCountRequired);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function updateSignatureManager(address _signatureManager)
		public
		override
		onlyAdmin()
	{
		signatureManager = _signatureManager;

		emit UpdatedSignatureManger(signatureManager);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function updateTransferDelaySeconds(uint256 _transferDelaySeconds)
		public
		override
		onlyAdmin()
	{
		require(_transferDelaySeconds >= 0, "!_transferDelaySeconds");

		transferDelaySeconds = _transferDelaySeconds;

		emit UpdatedTransferDelaySeconds(transferDelaySeconds);
	}


	/// @inheritdoc IYieldSyncV1Vault
	function createTransferRequest(
		bool forERC20,
		bool forERC721,
		address to,
		address tokenAddress,
		uint256 amount,
		uint256 tokenId
	)
		public
		override
		onlyMember()
	{
		require(amount > 0, "!amount");

		address[] memory initialVotedMembers;

		_transferRequestId_transferRequest[_transferRequestIdTracker] = TransferRequest(
			{
				forERC20: forERC20,
				forERC721: forERC721,
				creator: msg.sender,
				token: tokenAddress,
				tokenId: tokenId,
				amount: amount,
				to: to,
				forVoteCount: 0,
				againstVoteCount: 0,
				latestRelevantForVoteTime: block.timestamp,
				votedMembers: initialVotedMembers
			}
		);

		_idsOfOpenTransferRequests.push(_transferRequestIdTracker);

		_transferRequestIdTracker++;

		emit CreatedTransferRequest(_transferRequestIdTracker - 1);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function voteOnTransferRequest(uint256 transferRequestId, bool vote)
		public
		override
		onlyMember()
		validTransferRequest(transferRequestId)
	{
		require(
			_transferRequestId_transferRequest[transferRequestId].forVoteCount < forVoteCountRequired &&
			_transferRequestId_transferRequest[transferRequestId].againstVoteCount < againstVoteCountRequired,
			"Voting closed"
		);

		for (uint256 i = 0; i < _transferRequestId_transferRequest[transferRequestId].votedMembers.length; i++)
		{
			require(
				_transferRequestId_transferRequest[transferRequestId].votedMembers[i] != msg.sender,
				"Already voted"
			);
		}

		if (vote)
		{
			_transferRequestId_transferRequest[transferRequestId].forVoteCount++;
		}
		else
		{
			_transferRequestId_transferRequest[transferRequestId].againstVoteCount++;
		}

		if (
			_transferRequestId_transferRequest[transferRequestId].forVoteCount >= forVoteCountRequired ||
			_transferRequestId_transferRequest[transferRequestId].againstVoteCount >= againstVoteCountRequired
		)
		{
			emit TransferRequestReadyToBeProcessed(transferRequestId);
		}

		_transferRequestId_transferRequest[transferRequestId].votedMembers.push(msg.sender);

		if (_transferRequestId_transferRequest[transferRequestId].forVoteCount < forVoteCountRequired)
		{
			_transferRequestId_transferRequest[transferRequestId].latestRelevantForVoteTime = block.timestamp;
		}

		emit MemberVoted(transferRequestId, msg.sender, vote);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function processTransferRequest(uint256 transferRequestId)
		public
		override
		onlyMember()
		validTransferRequest(transferRequestId)
	{
		require(!processTransferRequestLocked, "processTransferRequestLocked");
		require(
			_transferRequestId_transferRequest[transferRequestId].forVoteCount >= forVoteCountRequired ||
			_transferRequestId_transferRequest[transferRequestId].againstVoteCount >= againstVoteCountRequired,
			"!forVoteCountRequired && !againstVoteCount"
		);

		processTransferRequestLocked = true;

		if (
			_transferRequestId_transferRequest[transferRequestId].forVoteCount >= forVoteCountRequired &&
			_transferRequestId_transferRequest[transferRequestId].againstVoteCount < againstVoteCountRequired
		)
		{
			require(
				block.timestamp - _transferRequestId_transferRequest[
					transferRequestId
				].latestRelevantForVoteTime >= transferDelaySeconds * 1 seconds,
				"Not enough time has passed"
			);

			if (
				_transferRequestId_transferRequest[transferRequestId].forERC20 &&
				!_transferRequestId_transferRequest[transferRequestId].forERC721
			)
			{
				if (
					IERC20(_transferRequestId_transferRequest[transferRequestId].token).balanceOf(
						address(this)
					) >= _transferRequestId_transferRequest[transferRequestId].amount
				)
				{
					// [ERC20-transfer]
					IERC20(_transferRequestId_transferRequest[transferRequestId].token).transfer(
						_transferRequestId_transferRequest[transferRequestId].to,
						_transferRequestId_transferRequest[transferRequestId].amount
					);
				}
				else
				{
					emit ProcessTransferRequestFailed(transferRequestId);
				}
			}

			if (
				!_transferRequestId_transferRequest[transferRequestId].forERC20 &&
				_transferRequestId_transferRequest[transferRequestId].forERC721
			)
			{
				if (
					IERC721(_transferRequestId_transferRequest[transferRequestId].token).ownerOf(
						_transferRequestId_transferRequest[transferRequestId].tokenId
					) == address(this)
				)
				{
					// [ERC721-transfer]
					IERC721(_transferRequestId_transferRequest[transferRequestId].token).transferFrom(
						address(this),
						_transferRequestId_transferRequest[transferRequestId].to,
						_transferRequestId_transferRequest[transferRequestId].tokenId
					);
				}
				else
				{
					emit ProcessTransferRequestFailed(transferRequestId);
				}
			}

			if (
				!_transferRequestId_transferRequest[transferRequestId].forERC20 &&
				!_transferRequestId_transferRequest[transferRequestId].forERC721
			)
			{
				// [transfer]
				(bool success, ) = _transferRequestId_transferRequest[transferRequestId].to.call{
					value: _transferRequestId_transferRequest[transferRequestId].amount
				}("");

				if (!success)
				{
					emit ProcessTransferRequestFailed(transferRequestId);
				}
			}

			emit TokensTransferred(
				msg.sender,
				_transferRequestId_transferRequest[transferRequestId].to,
				_transferRequestId_transferRequest[transferRequestId].amount
			);
		}

		processTransferRequestLocked = false;

		_deleteTransferRequest(transferRequestId);
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
