// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import {
	ITransferRequestProtocol,
	IYieldSyncV1ATransferRequestProtocol,
	IYieldSyncV1VaultAccessControl,
	TransferRequest,
	TransferRequestPoll,
	YieldSyncV1VaultProperty
} from "./interface/IYieldSyncV1ATransferRequestProtocol.sol";


contract YieldSyncV1ATransferRequestProtocol is
	ITransferRequestProtocol,
	IYieldSyncV1ATransferRequestProtocol
{
	uint256 internal _transferRequestIdTracker;

	IYieldSyncV1VaultAccessControl public immutable override YieldSyncV1VaultAccessControl;

	mapping (
		address yieldSyncV1VaultAddress => uint256[] openTransferRequestsIds
	) internal _yieldSyncV1VaultAddress_openTransferRequestIds;

	mapping (
		address yieldSyncV1VaultAddress => YieldSyncV1VaultProperty yieldSyncV1VaultProperty
	) internal _yieldSyncV1VaultAddress_yieldSyncV1VaultProperty;

	mapping (
		address yieldSyncV1VaultAddress => mapping (uint256 transferRequestId => TransferRequest transferRequest)
	) internal _yieldSyncV1VaultAddress_transferRequestId_transferRequest;

	mapping (
		address yieldSyncV1VaultAddress => mapping (
			uint256 transferRequestId => TransferRequestPoll transferRequestPoll
		)
	) internal _yieldSyncV1VaultAddress_transferRequestId_transferRequestPoll;


	constructor (address _YieldSyncV1VaultAccessControl)
	{
		YieldSyncV1VaultAccessControl = IYieldSyncV1VaultAccessControl(_YieldSyncV1VaultAccessControl);

		_transferRequestIdTracker = 0;
	}


	modifier accessAdmin(address yieldSyncV1VaultAddress)
	{
		(bool admin,) = YieldSyncV1VaultAccessControl.yieldSyncV1VaultAddress_participant_access(
			yieldSyncV1VaultAddress,
			msg.sender
		);

		require(admin || msg.sender == yieldSyncV1VaultAddress, "!admin && msg.sender != yieldSyncV1VaultAddress");

		_;
	}

	modifier accessMember(address yieldSyncV1VaultAddress)
	{
		(, bool member) = YieldSyncV1VaultAccessControl.yieldSyncV1VaultAddress_participant_access(
			yieldSyncV1VaultAddress,
			msg.sender
		);

		require(member || msg.sender == yieldSyncV1VaultAddress, "!member && msg.sender != yieldSyncV1VaultAddress");

		_;
	}

	modifier contractYieldSyncV1Vault(address yieldSyncV1VaultAddress)
	{
		require(msg.sender == yieldSyncV1VaultAddress, "!yieldSyncV1VaultAddress");

		_;
	}

	modifier validTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId)
	{
		require(
			_yieldSyncV1VaultAddress_transferRequestId_transferRequest[yieldSyncV1VaultAddress][
				transferRequestId
			].amount > 0,
			"No TransferRequest found"
		);

		_;
	}


	/**
	* @notice Delete TransferRequest
	* @dev [restriction][internal]
	* @dev [delete] `_yieldSyncV1VaultAddress_transferRequestId_transferRequest[yieldSyncV1VaultAddress]` value
	* @dev [delete] `_yieldSyncV1VaultAddress_transferRequestId_transferRequestPoll[yieldSyncV1VaultAddress]` value
	*      [delete] `_yieldSyncV1VaultAddress_idsOfOpenTransferRequests` value
	* @param yieldSyncV1VaultAddress {address}
	* @param transferRequestId {uint256}
	*/
	function _yieldSyncV1VaultAddress_transferRequestId_transferRequestDelete(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId
	)
		internal
	{
		delete _yieldSyncV1VaultAddress_transferRequestId_transferRequest[yieldSyncV1VaultAddress][transferRequestId];

		delete _yieldSyncV1VaultAddress_transferRequestId_transferRequestPoll[yieldSyncV1VaultAddress][
			transferRequestId
		];

		for (uint256 i = 0; i < _yieldSyncV1VaultAddress_openTransferRequestIds[yieldSyncV1VaultAddress].length; i++)
		{
			if (_yieldSyncV1VaultAddress_openTransferRequestIds[yieldSyncV1VaultAddress][i] == transferRequestId)
			{
				_yieldSyncV1VaultAddress_openTransferRequestIds[yieldSyncV1VaultAddress][
					i
				] = _yieldSyncV1VaultAddress_openTransferRequestIds[
					yieldSyncV1VaultAddress
				][
					_yieldSyncV1VaultAddress_openTransferRequestIds[yieldSyncV1VaultAddress].length - 1
				];

				_yieldSyncV1VaultAddress_openTransferRequestIds[yieldSyncV1VaultAddress].pop();

				break;
			}
		}
	}


	/// @inheritdoc ITransferRequestProtocol
	function yieldSyncV1VaultAddress_transferRequestId_transferRequest(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId
	)
		public
		view
		override
		returns (TransferRequest memory)
	{
		return _yieldSyncV1VaultAddress_transferRequestId_transferRequest[yieldSyncV1VaultAddress][transferRequestId];
	}

	/// @inheritdoc ITransferRequestProtocol
	function yieldSyncV1VaultAddress_transferRequestId_transferRequestStatus(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId
	)
		public
		view
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
		returns (bool readyToBeProcessed, bool approved, string memory message)
	{
		TransferRequestPoll memory transferRequestPoll = _yieldSyncV1VaultAddress_transferRequestId_transferRequestPoll[
			yieldSyncV1VaultAddress
		][
			transferRequestId
		];

		YieldSyncV1VaultProperty memory yieldSyncV1VaultProperty = _yieldSyncV1VaultAddress_yieldSyncV1VaultProperty[
			yieldSyncV1VaultAddress
		];

		if (
			transferRequestPoll.forVoteCount < yieldSyncV1VaultProperty.forVoteRequired &&
			transferRequestPoll.againstVoteCount < yieldSyncV1VaultProperty.againstVoteRequired
		)
		{
			return (false, false, "Transfer request pending");
		}

		if (transferRequestPoll.againstVoteCount >= yieldSyncV1VaultProperty.againstVoteRequired)
		{
			return (true, false, "Transfer request denied");
		}

		if (block.timestamp - transferRequestPoll.latestForVoteTime < yieldSyncV1VaultProperty.transferDelaySeconds)
		{
			return (false, true, "Transfer request approved and waiting delay");
		}

		return (true, true, "Transfer request approved");
	}

	/// @inheritdoc ITransferRequestProtocol
	function yieldSyncV1VaultAddress_transferRequestId_transferRequestProcess(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId
	)
		public
		override
		contractYieldSyncV1Vault(yieldSyncV1VaultAddress)
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
	{
		_yieldSyncV1VaultAddress_transferRequestId_transferRequestDelete(yieldSyncV1VaultAddress, transferRequestId);

		emit DeletedTransferRequest(yieldSyncV1VaultAddress, transferRequestId);
	}

	/// @inheritdoc ITransferRequestProtocol
	function yieldSyncV1VaultInitialize(address initiator, address yieldSyncV1VaultAddress)
		public
		override
		contractYieldSyncV1Vault(yieldSyncV1VaultAddress)
	{
		require(
			_yieldSyncV1VaultAddress_yieldSyncV1VaultProperty[initiator].againstVoteRequired > 0,
			"!_againstVoteRequired"
		);
		require(
			_yieldSyncV1VaultAddress_yieldSyncV1VaultProperty[initiator].forVoteRequired > 0,
			"!forVoteRequired"
		);

		_yieldSyncV1VaultAddress_yieldSyncV1VaultProperty[
			yieldSyncV1VaultAddress
		] = _yieldSyncV1VaultAddress_yieldSyncV1VaultProperty[
			initiator
		];
	}


	/// @inheritdoc IYieldSyncV1ATransferRequestProtocol
	function yieldSyncV1VaultAddress_openTransferRequestIds(address yieldSyncV1VaultAddress)
		public
		view
		override
		returns (uint256[] memory)
	{
		return _yieldSyncV1VaultAddress_openTransferRequestIds[yieldSyncV1VaultAddress];
	}

	/// @inheritdoc IYieldSyncV1ATransferRequestProtocol
	function yieldSyncV1VaultAddress_yieldSyncV1VaultProperty(address yieldSyncV1VaultAddress)
		public
		view
		override
		returns (YieldSyncV1VaultProperty memory)
	{
		return _yieldSyncV1VaultAddress_yieldSyncV1VaultProperty[yieldSyncV1VaultAddress];
	}


	/// @inheritdoc IYieldSyncV1ATransferRequestProtocol
	function yieldSyncV1VaultAddress_transferRequestId_transferRequestPoll(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId
	)
		public
		view
		override
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
		returns (TransferRequestPoll memory)
	{
		return _yieldSyncV1VaultAddress_transferRequestId_transferRequestPoll[yieldSyncV1VaultAddress][
			transferRequestId
		];
	}


	/// @inheritdoc IYieldSyncV1ATransferRequestProtocol
	function yieldSyncV1VaultAddress_transferRequestId_transferRequestCreate(
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
		accessMember(yieldSyncV1VaultAddress)
	{
		require(amount > 0, "!amount");

		require(!(forERC20 && forERC721), "forERC20 && forERC721");

		address[] memory initialVotedMembers;

		_yieldSyncV1VaultAddress_transferRequestId_transferRequest[yieldSyncV1VaultAddress][
			_transferRequestIdTracker
		] = TransferRequest(
			{
				forERC20: forERC20,
				forERC721: forERC721,
				creator: msg.sender,
				token: tokenAddress,
				tokenId: tokenId,
				amount: amount,
				to: to
			}
		);

		_yieldSyncV1VaultAddress_transferRequestId_transferRequestPoll[yieldSyncV1VaultAddress][
			_transferRequestIdTracker
		] = TransferRequestPoll(
			{
				againstVoteCount: 0,
				forVoteCount: 0,
				latestForVoteTime: block.timestamp,
				votedMembers: initialVotedMembers
			}
		);

		_yieldSyncV1VaultAddress_openTransferRequestIds[yieldSyncV1VaultAddress].push(_transferRequestIdTracker);

		_transferRequestIdTracker++;

		emit CreatedTransferRequest(yieldSyncV1VaultAddress, _transferRequestIdTracker - 1);
	}

	/// @inheritdoc IYieldSyncV1ATransferRequestProtocol
	function yieldSyncV1VaultAddress_transferRequestId_transferRequestDelete(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId
	)
		public
		override
		accessAdmin(yieldSyncV1VaultAddress)
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
	{
		_yieldSyncV1VaultAddress_transferRequestId_transferRequestDelete(yieldSyncV1VaultAddress, transferRequestId);

		emit DeletedTransferRequest(yieldSyncV1VaultAddress, transferRequestId);
	}

	/// @inheritdoc IYieldSyncV1ATransferRequestProtocol
	function yieldSyncV1VaultAddress_transferRequestId_transferRequestUpdate(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId,
		TransferRequest memory transferRequest
	)
		public
		override
		accessAdmin(yieldSyncV1VaultAddress)
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
	{
		require(transferRequest.amount > 0, "!transferRequest.amount");

		require(
			!(transferRequest.forERC20 && transferRequest.forERC721),
			"transferRequest.forERC20 && transferRequest.forERC721"
		);

		_yieldSyncV1VaultAddress_transferRequestId_transferRequest[yieldSyncV1VaultAddress][
			transferRequestId
		] = transferRequest;

		emit UpdatedTransferRequest(
			yieldSyncV1VaultAddress,
			_yieldSyncV1VaultAddress_transferRequestId_transferRequest[yieldSyncV1VaultAddress][transferRequestId]
		);
	}

	/// @inheritdoc IYieldSyncV1ATransferRequestProtocol
	function yieldSyncV1VaultAddress_transferRequestId_transferRequestPollVote(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId,
		bool vote
	)
		public
		override
		accessMember(yieldSyncV1VaultAddress)
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
	{
		TransferRequestPoll storage transferRequestPoll = _yieldSyncV1VaultAddress_transferRequestId_transferRequestPoll[
			yieldSyncV1VaultAddress
		][
			transferRequestId
		];

		YieldSyncV1VaultProperty memory yieldSyncV1VaultProperty = _yieldSyncV1VaultAddress_yieldSyncV1VaultProperty[
			yieldSyncV1VaultAddress
		];

		require(
			transferRequestPoll.forVoteCount < yieldSyncV1VaultProperty.forVoteRequired &&
			transferRequestPoll.againstVoteCount < yieldSyncV1VaultProperty.againstVoteRequired,
			"Voting closed"
		);

		for (uint256 i = 0; i < transferRequestPoll.votedMembers.length; i++)
		{
			require(transferRequestPoll.votedMembers[i] != msg.sender, "Already voted");
		}

		if (vote)
		{
			transferRequestPoll.forVoteCount++;

			transferRequestPoll.latestForVoteTime = block.timestamp;
		}
		else
		{
			transferRequestPoll.againstVoteCount++;
		}

		if (
			transferRequestPoll.forVoteCount >= yieldSyncV1VaultProperty.forVoteRequired ||
			transferRequestPoll.againstVoteCount >= yieldSyncV1VaultProperty.againstVoteRequired
		)
		{
			emit TransferRequestReadyToBeProcessed(yieldSyncV1VaultAddress, transferRequestId);
		}

		transferRequestPoll.votedMembers.push(msg.sender);

		_yieldSyncV1VaultAddress_transferRequestId_transferRequestPoll[yieldSyncV1VaultAddress][
			transferRequestId
		] = transferRequestPoll;

		emit MemberVoted(yieldSyncV1VaultAddress, transferRequestId, msg.sender, vote);
	}

	/// @inheritdoc IYieldSyncV1ATransferRequestProtocol
	function yieldSyncV1VaultAddress_transferRequestId_transferRequestPollUpdate(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId,
		TransferRequestPoll memory transferRequestPoll
	)
		public
		override
		accessAdmin(yieldSyncV1VaultAddress)
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
	{
		_yieldSyncV1VaultAddress_transferRequestId_transferRequestPoll[yieldSyncV1VaultAddress][
			transferRequestId
		] = transferRequestPoll;

		emit UpdatedTransferRequestPoll(
			yieldSyncV1VaultAddress,
			_yieldSyncV1VaultAddress_transferRequestId_transferRequestPoll[yieldSyncV1VaultAddress][transferRequestId]
		);
	}

	/// @inheritdoc IYieldSyncV1ATransferRequestProtocol
	function yieldSyncV1VaultAddress_yieldSyncV1VaultPropertyUpdate(
		address yieldSyncV1VaultAddress,
		YieldSyncV1VaultProperty memory yieldSyncV1VaultProperty
	)
		public
		override
		accessAdmin(yieldSyncV1VaultAddress)
	{
		require(yieldSyncV1VaultProperty.againstVoteRequired > 0, "!_againstVoteRequired");
		require(yieldSyncV1VaultProperty.forVoteRequired > 0, "!_againstVoteRequired");

		_yieldSyncV1VaultAddress_yieldSyncV1VaultProperty[yieldSyncV1VaultAddress] = yieldSyncV1VaultProperty;
	}
}
