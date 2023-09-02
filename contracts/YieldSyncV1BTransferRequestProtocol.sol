// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {
	ITransferRequestProtocol,
	IYieldSyncV1BTransferRequestProtocol,
	IYieldSyncV1VaultRegistry,
	TransferRequest,
	TransferRequestPoll,
	YieldSyncV1VaultProperty
} from "./interface/IYieldSyncV1BTransferRequestProtocol.sol";


contract YieldSyncV1BTransferRequestProtocol is
	ReentrancyGuard,
	ITransferRequestProtocol,
	IYieldSyncV1BTransferRequestProtocol
{
	uint256 internal _transferRequestIdTracker;

	IYieldSyncV1VaultRegistry public immutable override YieldSyncV1VaultRegistry;

	mapping (
		address yieldSyncV1Vault => uint256[] openTransferRequestsIds
	) internal _yieldSyncV1Vault_openTransferRequestIds;

	mapping (
		address yieldSyncV1Vault => YieldSyncV1VaultProperty yieldSyncV1VaultProperty
	) internal _yieldSyncV1Vault_yieldSyncV1VaultProperty;

	mapping (
		address yieldSyncV1Vault => mapping (uint256 transferRequestId => TransferRequest transferRequest)
	) internal _yieldSyncV1Vault_transferRequestId_transferRequest;

	mapping (
		address yieldSyncV1Vault => mapping (uint256 transferRequestId => TransferRequestPoll transferRequestPoll)
	) internal _yieldSyncV1Vault_transferRequestId_transferRequestPoll;


	constructor (address _YieldSyncV1VaultRegistry)
	{
		YieldSyncV1VaultRegistry = IYieldSyncV1VaultRegistry(_YieldSyncV1VaultRegistry);

		_transferRequestIdTracker = 0;
	}


	modifier accessAdmin(address yieldSyncV1Vault)
	{
		(bool admin,) = YieldSyncV1VaultRegistry.yieldSyncV1Vault_participant_access(yieldSyncV1Vault, msg.sender);

		require(admin || msg.sender == yieldSyncV1Vault, "!admin && msg.sender != yieldSyncV1Vault");

		_;
	}

	modifier accessMember(address yieldSyncV1Vault)
	{
		(, bool member) = YieldSyncV1VaultRegistry.yieldSyncV1Vault_participant_access(
			yieldSyncV1Vault,
			msg.sender
		);

		require(member || msg.sender == yieldSyncV1Vault, "!member && msg.sender != yieldSyncV1Vault");

		_;
	}

	modifier contractYieldSyncV1Vault(address yieldSyncV1Vault)
	{
		require(msg.sender == yieldSyncV1Vault, "!yieldSyncV1Vault");

		_;
	}

	modifier validTransferRequest(address yieldSyncV1Vault, uint256 transferRequestId)
	{
		require(
			_yieldSyncV1Vault_transferRequestId_transferRequest[yieldSyncV1Vault][transferRequestId].amount > 0,
			"No TransferRequest found"
		);

		_;
	}


	/**
	* @notice Delete TransferRequest
	* @dev [restriction][internal]
	* @dev [delete] `_yieldSyncV1Vault_transferRequestId_transferRequest[yieldSyncV1Vault]` value
	* @dev [delete] `_yieldSyncV1Vault_transferRequestId_transferRequestPoll[yieldSyncV1Vault]` value
	*      [delete] `_yieldSyncV1Vault_openTransferRequestIds` value
	* @param yieldSyncV1Vault {address}
	* @param transferRequestId {uint256}
	*/
	function _yieldSyncV1Vault_transferRequestId_transferRequestDelete(
		address yieldSyncV1Vault,
		uint256 transferRequestId
	)
		internal
	{
		delete _yieldSyncV1Vault_transferRequestId_transferRequest[yieldSyncV1Vault][transferRequestId];

		delete _yieldSyncV1Vault_transferRequestId_transferRequestPoll[yieldSyncV1Vault][transferRequestId];

		for (uint256 i = 0; i < _yieldSyncV1Vault_openTransferRequestIds[yieldSyncV1Vault].length; i++)
		{
			if (_yieldSyncV1Vault_openTransferRequestIds[yieldSyncV1Vault][i] == transferRequestId)
			{
				_yieldSyncV1Vault_openTransferRequestIds[yieldSyncV1Vault][i] = _yieldSyncV1Vault_openTransferRequestIds[
					yieldSyncV1Vault
				][
					_yieldSyncV1Vault_openTransferRequestIds[yieldSyncV1Vault].length - 1
				];

				_yieldSyncV1Vault_openTransferRequestIds[yieldSyncV1Vault].pop();

				break;
			}
		}
	}


	/// @inheritdoc ITransferRequestProtocol
	function yieldSyncV1Vault_transferRequestId_transferRequest(address yieldSyncV1Vault, uint256 transferRequestId)
		public
		view
		override
		returns (TransferRequest memory)
	{
		return _yieldSyncV1Vault_transferRequestId_transferRequest[yieldSyncV1Vault][transferRequestId];
	}

	/// @inheritdoc ITransferRequestProtocol
	function yieldSyncV1Vault_transferRequestId_transferRequestStatus(
		address yieldSyncV1Vault,
		uint256 transferRequestId
	)
		public
		view
		validTransferRequest(yieldSyncV1Vault, transferRequestId)
		returns (bool readyToBeProcessed, bool approved, string memory message)
	{
		TransferRequestPoll memory transferRequestPoll = _yieldSyncV1Vault_transferRequestId_transferRequestPoll[
			yieldSyncV1Vault
		][
			transferRequestId
		];

		YieldSyncV1VaultProperty memory yieldSyncV1VaultProperty = _yieldSyncV1Vault_yieldSyncV1VaultProperty[
			yieldSyncV1Vault
		];

		if (block.timestamp < transferRequestPoll.voteCloseTimestamp)
		{
			return (false, true, "Voting not closed");
		}

		if (transferRequestPoll.voteAgainstMembers.length >= yieldSyncV1VaultProperty.voteAgainstRequired)
		{
			return (true, false, "TransferRequest denied");
		}

		if (
			transferRequestPoll.voteForMembers.length < yieldSyncV1VaultProperty.voteForRequired &&
			transferRequestPoll.voteAgainstMembers.length < yieldSyncV1VaultProperty.voteAgainstRequired
		)
		{
			return (true, false, "TransferRequest denied from insufficient vote count");
		}

		return (true, true, "TransferRequest approved");
	}

	/// @inheritdoc ITransferRequestProtocol
	function yieldSyncV1Vault_transferRequestId_transferRequestProcess(
		address yieldSyncV1Vault,
		uint256 transferRequestId
	)
		public
		override
		contractYieldSyncV1Vault(yieldSyncV1Vault)
		validTransferRequest(yieldSyncV1Vault, transferRequestId)
	{
		_yieldSyncV1Vault_transferRequestId_transferRequestDelete(yieldSyncV1Vault, transferRequestId);

		emit DeletedTransferRequest(yieldSyncV1Vault, transferRequestId);
	}

	/// @inheritdoc ITransferRequestProtocol
	function yieldSyncV1VaultInitialize(address initiator, address yieldSyncV1Vault)
		public
		override
		contractYieldSyncV1Vault(yieldSyncV1Vault)
	{
		require(
			_yieldSyncV1Vault_yieldSyncV1VaultProperty[initiator].voteAgainstRequired > 0,
			"!_yieldSyncV1Vault_yieldSyncV1VaultProperty[initiator].voteAgainstRequired"
		);

		require(
			_yieldSyncV1Vault_yieldSyncV1VaultProperty[initiator].voteForRequired > 0,
			"!_yieldSyncV1Vault_yieldSyncV1VaultProperty[initiator].voteForRequired"
		);

		_yieldSyncV1Vault_yieldSyncV1VaultProperty[yieldSyncV1Vault] = _yieldSyncV1Vault_yieldSyncV1VaultProperty[
			initiator
		];
	}


	/// @inheritdoc IYieldSyncV1BTransferRequestProtocol
	function yieldSyncV1Vault_openTransferRequestIds(address yieldSyncV1Vault)
		public
		view
		override
		returns (uint256[] memory)
	{
		return _yieldSyncV1Vault_openTransferRequestIds[yieldSyncV1Vault];
	}

	/// @inheritdoc IYieldSyncV1BTransferRequestProtocol
	function yieldSyncV1Vault_yieldSyncV1VaultProperty(address yieldSyncV1Vault)
		public
		view
		override
		returns (YieldSyncV1VaultProperty memory)
	{
		return _yieldSyncV1Vault_yieldSyncV1VaultProperty[yieldSyncV1Vault];
	}


	/// @inheritdoc IYieldSyncV1BTransferRequestProtocol
	function yieldSyncV1Vault_transferRequestId_transferRequestPoll(
		address yieldSyncV1Vault,
		uint256 transferRequestId
	)
		public
		view
		override
		validTransferRequest(yieldSyncV1Vault, transferRequestId)
		returns (TransferRequestPoll memory)
	{
		return _yieldSyncV1Vault_transferRequestId_transferRequestPoll[yieldSyncV1Vault][transferRequestId];
	}


	/// @inheritdoc IYieldSyncV1BTransferRequestProtocol
	function yieldSyncV1Vault_transferRequestId_transferRequestCreate(
		address yieldSyncV1Vault,
		bool forERC20,
		bool forERC721,
		address to,
		address token,
		uint256 amount,
		uint256 tokenId,
		uint256 voteCloseTimestamp
	)
		public
		override
		accessMember(yieldSyncV1Vault)
	{
		require(amount > 0, "!amount");

		require(!(forERC20 && forERC721), "forERC20 && forERC721");

		address[] memory emptyArray;

		_yieldSyncV1Vault_transferRequestId_transferRequest[yieldSyncV1Vault][_transferRequestIdTracker] = TransferRequest(
			{
				forERC20: forERC20,
				forERC721: forERC721,
				creator: msg.sender,
				to: to,
				token: token,
				amount: amount,
				created: block.timestamp,
				tokenId: tokenId
			}
		);

		_yieldSyncV1Vault_transferRequestId_transferRequestPoll[yieldSyncV1Vault][
			_transferRequestIdTracker
		] = TransferRequestPoll(
			{
				voteCloseTimestamp: voteCloseTimestamp,
				voteAgainstMembers: emptyArray,
				voteForMembers: emptyArray
			}
		);

		_yieldSyncV1Vault_openTransferRequestIds[yieldSyncV1Vault].push(_transferRequestIdTracker);

		_transferRequestIdTracker++;

		emit CreatedTransferRequest(yieldSyncV1Vault, _transferRequestIdTracker - 1);
	}

	/// @inheritdoc IYieldSyncV1BTransferRequestProtocol
	function yieldSyncV1Vault_transferRequestId_transferRequestDelete(
		address yieldSyncV1Vault,
		uint256 transferRequestId
	)
		public
		override
		accessAdmin(yieldSyncV1Vault)
		validTransferRequest(yieldSyncV1Vault, transferRequestId)
	{
		_yieldSyncV1Vault_transferRequestId_transferRequestDelete(yieldSyncV1Vault, transferRequestId);

		emit DeletedTransferRequest(yieldSyncV1Vault, transferRequestId);
	}

	/// @inheritdoc IYieldSyncV1BTransferRequestProtocol
	function yieldSyncV1Vault_transferRequestId_transferRequestUpdate(
		address yieldSyncV1Vault,
		uint256 transferRequestId,
		TransferRequest memory transferRequest
	)
		public
		override
		accessAdmin(yieldSyncV1Vault)
		validTransferRequest(yieldSyncV1Vault, transferRequestId)
	{
		require(transferRequest.amount > 0, "!transferRequest.amount");

		require(
			!(transferRequest.forERC20 && transferRequest.forERC721),
			"transferRequest.forERC20 && transferRequest.forERC721"
		);

		_yieldSyncV1Vault_transferRequestId_transferRequest[yieldSyncV1Vault][transferRequestId] = transferRequest;

		emit UpdateTransferRequest(
			yieldSyncV1Vault,
			_yieldSyncV1Vault_transferRequestId_transferRequest[yieldSyncV1Vault][transferRequestId]
		);
	}

	/// @inheritdoc IYieldSyncV1BTransferRequestProtocol
	function yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
		address yieldSyncV1Vault,
		uint256 transferRequestId,
		bool vote
	)
		public
		override
		nonReentrant()
		accessMember(yieldSyncV1Vault)
		validTransferRequest(yieldSyncV1Vault, transferRequestId)
	{
		require(
			block.timestamp < _yieldSyncV1Vault_transferRequestId_transferRequestPoll[yieldSyncV1Vault][
				transferRequestId
			].voteCloseTimestamp,
			"Voting closed"
		);

		bool votedForPreviously = false;
		bool votedAgainstPreviously = false;

		uint256 votedAgainstMembersIndex;
		uint256 votedForMembersIndex;

		TransferRequestPoll storage transferRequestPoll = _yieldSyncV1Vault_transferRequestId_transferRequestPoll[
			yieldSyncV1Vault
		][
			transferRequestId
		];

		for (uint256 i = 0; i < transferRequestPoll.voteAgainstMembers.length; i++)
		{
			if (transferRequestPoll.voteAgainstMembers[i] == msg.sender)
			{
				votedAgainstPreviously = true;

				votedAgainstMembersIndex = i;
			}
		}

		for (uint256 i = 0; i < transferRequestPoll.voteForMembers.length; i++)
		{
			if (transferRequestPoll.voteForMembers[i] == msg.sender)
			{
				votedForPreviously = true;

				votedForMembersIndex = i;
			}
		}

		if (vote)
		{
			require(!votedForPreviously, "votedForPreviously");

			transferRequestPoll.voteForMembers.push(msg.sender);

			if (votedAgainstPreviously)
			{
				for (uint256 i = votedAgainstMembersIndex; i < transferRequestPoll.voteAgainstMembers.length - 1; i++)
				{
					transferRequestPoll.voteAgainstMembers[i] = transferRequestPoll.voteAgainstMembers[i + 1];
				}

				transferRequestPoll.voteAgainstMembers.pop();
			}
		}
		else
		{
			require(!votedAgainstPreviously, "votedAgainstPreviously");

			transferRequestPoll.voteAgainstMembers.push(msg.sender);

			if (votedForPreviously)
			{
				for (uint256 i = votedForMembersIndex; i < transferRequestPoll.voteForMembers.length - 1; i++)
				{
					transferRequestPoll.voteForMembers[i] = transferRequestPoll.voteForMembers[i + 1];
				}

				transferRequestPoll.voteForMembers.pop();
			}
		}

		_yieldSyncV1Vault_transferRequestId_transferRequestPoll[yieldSyncV1Vault][transferRequestId] = transferRequestPoll;

		emit MemberVoted(yieldSyncV1Vault, transferRequestId, msg.sender, vote);
	}

	/// @inheritdoc IYieldSyncV1BTransferRequestProtocol
	function yieldSyncV1Vault_transferRequestId_transferRequestPollUpdate(
		address yieldSyncV1Vault,
		uint256 transferRequestId,
		TransferRequestPoll memory transferRequestPoll
	)
		public
		override
		accessAdmin(yieldSyncV1Vault)
		validTransferRequest(yieldSyncV1Vault, transferRequestId)
	{
		_yieldSyncV1Vault_transferRequestId_transferRequestPoll[yieldSyncV1Vault][transferRequestId] = transferRequestPoll;

		emit UpdateTransferRequestPoll(
			yieldSyncV1Vault,
			_yieldSyncV1Vault_transferRequestId_transferRequestPoll[yieldSyncV1Vault][transferRequestId]
		);
	}

	/// @inheritdoc IYieldSyncV1BTransferRequestProtocol
	function yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate(
		address yieldSyncV1Vault,
		YieldSyncV1VaultProperty memory yieldSyncV1VaultProperty
	)
		public
		override
		accessAdmin(yieldSyncV1Vault)
	{
		require(yieldSyncV1VaultProperty.voteAgainstRequired > 0, "!yieldSyncV1VaultProperty.voteAgainstRequired");

		require(yieldSyncV1VaultProperty.voteForRequired > 0, "!yieldSyncV1VaultProperty.voteForRequired");

		_yieldSyncV1Vault_yieldSyncV1VaultProperty[yieldSyncV1Vault] = yieldSyncV1VaultProperty;
	}
}
