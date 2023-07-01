// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { TransferRequest, IYieldSyncV1VaultTransferRequest } from "./interface/IYieldSyncV1VaultTransferRequest.sol";
import { IYieldSyncV1VaultAccessControl } from "./interface/IYieldSyncV1VaultAccessControl.sol";


contract YieldSyncV1VaultTransferRequest is
	IYieldSyncV1VaultTransferRequest
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

	bool public override processTransferRequestLocked;

	uint256 public override againstVoteCountRequired;
	uint256 public override forVoteCountRequired;
	uint256 public override transferDelaySeconds;
	uint256 internal _transferRequestIdTracker;
	mapping (
		address yieldSyncV1Vault => uint256[] openTransferRequestsIds
	) internal _yieldSyncV1Vault_openTransferRequestIds;

	mapping (
		address yieldSyncV1Vault => mapping (
			uint256 transferRequestId => TransferRequest transferRequest
		)
	) internal _vaultTransferRequestById;


	constructor (
		address _YieldSyncV1VaultAccessControl,
		uint256 _againstVoteCountRequired,
		uint256 _forVoteCountRequired,
		uint256 _transferDelaySeconds
	)
	{
		YieldSyncV1VaultAccessControl = _YieldSyncV1VaultAccessControl;

		require(_forVoteCountRequired > 0, "!_forVoteCountRequired");

		processTransferRequestLocked = false;
		againstVoteCountRequired = _againstVoteCountRequired;
		forVoteCountRequired = _forVoteCountRequired;
		transferDelaySeconds = _transferDelaySeconds;

		_transferRequestIdTracker = 0;
	}


	modifier validTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId)
	{
		require(
			_vaultTransferRequestById[yieldSyncV1VaultAddress][transferRequestId].amount > 0,
			"No TransferRequest found"
		);

		_;
	}

	modifier onlyAdmin(address yieldSyncV1VaultAddress)
	{
		(bool admin,) = IYieldSyncV1VaultAccessControl(
			YieldSyncV1VaultAccessControl
		).participant_yieldSyncV1Vault_access(
			msg.sender,
			yieldSyncV1VaultAddress
		);

		require(admin, "!admin");

		_;
	}

	modifier onlyMember(address yieldSyncV1VaultAddress)
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
	* @dev [delete] `_vaultTransferRequestById[yieldSyncV1VaultAddress]` value
	*      [delete] `_yieldSyncV1VaultAddress_idsOfOpenTransferRequests` value
	* @param yieldSyncV1VaultAddress {address}
	* @param transferRequestId {uint256}
	* Emits: `DeletedTransferRequest`
	*/
	function _deleteTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId)
		internal
	{
		delete _vaultTransferRequestById[yieldSyncV1VaultAddress][transferRequestId];

		for (uint256 i = 0; i < _yieldSyncV1Vault_openTransferRequestIds[yieldSyncV1VaultAddress].length; i++)
		{
			uint256 length = _yieldSyncV1Vault_openTransferRequestIds[yieldSyncV1VaultAddress].length;

			if (_yieldSyncV1Vault_openTransferRequestIds[yieldSyncV1VaultAddress][i] == transferRequestId)
			{
				_yieldSyncV1Vault_openTransferRequestIds[
					yieldSyncV1VaultAddress][i] = _yieldSyncV1Vault_openTransferRequestIds[
					yieldSyncV1VaultAddress
				][
					length - 1
				];

				_yieldSyncV1Vault_openTransferRequestIds[yieldSyncV1VaultAddress].pop();

				break;
			}
		}
	}


	function yieldSyncV1Vault_idsOfOpenTransferRequests(address yieldSyncV1VaultAddress)
		public
		view
		override
		returns (uint256[] memory)
	{
		return _yieldSyncV1Vault_openTransferRequestIds[yieldSyncV1VaultAddress];
	}

	function vaultTransferRequestById(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId
	)
		public
		view
		override
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
		returns (TransferRequest memory)
	{
		return _vaultTransferRequestById[yieldSyncV1VaultAddress][transferRequestId];
	}

	function deleteTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId)
		public
		override
		onlyAdmin(yieldSyncV1VaultAddress)
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
	{
		_deleteTransferRequest(yieldSyncV1VaultAddress, transferRequestId);

		emit DeletedTransferRequest(transferRequestId);
	}

	function updateTransferRequest(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId,
		TransferRequest memory __transferRequest
	)
		public
		override
		onlyAdmin(yieldSyncV1VaultAddress)
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
	{
		_vaultTransferRequestById[yieldSyncV1VaultAddress][transferRequestId] = __transferRequest;

		emit UpdatedTransferRequest(__transferRequest);
	}

	function updateAgainstVoteCountRequired(address yieldSyncV1VaultAddress, uint256 _againstVoteCountRequired)
		public
		override
		onlyAdmin(yieldSyncV1VaultAddress)
	{
		require(_againstVoteCountRequired > 0, "!_againstVoteCountRequired");

		againstVoteCountRequired = _againstVoteCountRequired;

		emit UpdatedAgainstVoteCountRequired(againstVoteCountRequired);
	}

	function updateForVoteCountRequired(address yieldSyncV1VaultAddress, uint256 _forVoteCountRequired)
		public
		override
		onlyAdmin(yieldSyncV1VaultAddress)
	{
		require(_forVoteCountRequired > 0, "!_forVoteCountRequired");

		forVoteCountRequired = _forVoteCountRequired;

		emit UpdatedForVoteCountRequired(forVoteCountRequired);
	}

	function updateTransferDelaySeconds(address yieldSyncV1VaultAddress, uint256 _transferDelaySeconds)
		public
		override
		onlyAdmin(yieldSyncV1VaultAddress)
	{
		require(_transferDelaySeconds >= 0, "!_transferDelaySeconds");

		transferDelaySeconds = _transferDelaySeconds;

		emit UpdatedTransferDelaySeconds(transferDelaySeconds);
	}


	function createTransferRequest(
		address yieldSyncV1VaultAddress,
		bool forERC20,
		bool forERC721,
		address to,
		address tokenAddress,
		uint256 amount,
		uint256 tokenId
	)
		public
		override
		onlyMember(yieldSyncV1VaultAddress)
	{
		require(amount > 0, "!amount");

		address[] memory initialVotedMembers;

		_vaultTransferRequestById[yieldSyncV1VaultAddress][_transferRequestIdTracker] = TransferRequest(
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

		_yieldSyncV1Vault_openTransferRequestIds[yieldSyncV1VaultAddress].push(_transferRequestIdTracker);

		_transferRequestIdTracker++;

		emit CreatedTransferRequest(_transferRequestIdTracker - 1);
	}

	function voteOnTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId, bool vote)
		public
		override
		onlyMember(yieldSyncV1VaultAddress)
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
	{
		TransferRequest storage transferRequest = _vaultTransferRequestById[yieldSyncV1VaultAddress][
			transferRequestId
		];

		require(
			transferRequest.forVoteCount < forVoteCountRequired &&
			transferRequest.againstVoteCount < againstVoteCountRequired,
			"Voting closed"
		);

		for (uint256 i = 0; i < transferRequest.votedMembers.length; i++)
		{
			require(
				transferRequest.votedMembers[i] != msg.sender,
				"Already voted"
			);
		}

		if (vote)
		{
			transferRequest.forVoteCount++;
		}
		else
		{
			transferRequest.againstVoteCount++;
		}

		if (
			transferRequest.forVoteCount >= forVoteCountRequired ||
			transferRequest.againstVoteCount >= againstVoteCountRequired
		)
		{
			emit TransferRequestReadyToBeProcessed(transferRequestId);
		}

		transferRequest.votedMembers.push(msg.sender);

		if (transferRequest.forVoteCount < forVoteCountRequired)
		{
			transferRequest.latestRelevantForVoteTime = block.timestamp;
		}

		_vaultTransferRequestById[yieldSyncV1VaultAddress][transferRequestId] = transferRequest;

		emit MemberVoted(transferRequestId, msg.sender, vote);
	}

	function transferRequestStatus(address yieldSyncV1VaultAddress, uint256 transferRequestId)
		public
		view
		onlyMember(yieldSyncV1VaultAddress)
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
		returns (bool readyToBeProcessed, bool approved, string memory message)
	{
		TransferRequest memory transferRequest = _vaultTransferRequestById[yieldSyncV1VaultAddress][
			transferRequestId
		];

		if (
			transferRequest.forVoteCount >= forVoteCountRequired ||
			transferRequest.againstVoteCount >= againstVoteCountRequired
		)
		{
			if (
				transferRequest.forVoteCount >= forVoteCountRequired &&
				transferRequest.againstVoteCount < againstVoteCountRequired
			)
			{
				if (block.timestamp - transferRequest.latestRelevantForVoteTime >= transferDelaySeconds * 1 seconds)
				{
					return (true, true, "Transfer request ready to be processed");
				}

				return (true, false, "Not enough time has passed");
			}

			return (true, false, "Transfer request denied");
		}

		return (false, false, "Transfer request not ready");
	}
}
