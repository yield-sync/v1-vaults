// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import {
	TransferRequest,
	TransferRequestVote,
	IYieldSyncV1VaultTransferRequest
} from "./interface/IYieldSyncV1VaultTransferRequest.sol";
import { IYieldSyncV1VaultAccessControl } from "./interface/IYieldSyncV1VaultAccessControl.sol";


contract YieldSyncV1VaultTransferRequest is
	IYieldSyncV1VaultTransferRequest
{
	uint256 internal _transferRequestIdTracker;

	address public override immutable YieldSyncV1VaultAccessControl;
	address public override YieldSyncV1VaultFactory;

	mapping (
		address yieldSyncV1Vault => uint256 againstVoteRequired
	) internal _yieldSyncV1Vault_againstVoteRequired;
	mapping (
		address yieldSyncV1Vault => uint256 forVoteRequired
	) internal _yieldSyncV1Vault_forVoteRequired;
	mapping (
		address yieldSyncV1Vault => uint256 transferDelaySeconds
	) internal _yieldSyncV1Vault_transferDelaySeconds;

	mapping (
		address yieldSyncV1Vault => uint256[] openTransferRequestsIds
	) internal _yieldSyncV1Vault_openTransferRequestIds;

	mapping (
		address yieldSyncV1Vault => mapping (
			uint256 transferRequestId => TransferRequest transferRequest
		)
	) internal _yieldSyncV1Vault_transferRequestId_transferRequest;

	mapping (
		address yieldSyncV1Vault => mapping (
			uint256 transferRequestId => TransferRequestVote transferRequestVote
		)
	) internal _yieldSyncV1Vault_transferRequestId_transferRequestVote;


	constructor (address _YieldSyncV1VaultAccessControl, address _YieldSyncV1VaultFactory)
	{
		YieldSyncV1VaultAccessControl = _YieldSyncV1VaultAccessControl;
		YieldSyncV1VaultFactory = _YieldSyncV1VaultFactory;

		_transferRequestIdTracker = 0;
	}


	modifier validTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId)
	{
		require(
			_yieldSyncV1Vault_transferRequestId_transferRequest[yieldSyncV1VaultAddress][transferRequestId].amount > 0,
			"No TransferRequest found"
		);

		_;
	}

	modifier onlyAdminOrYieldSyncV1VaultFactory(address yieldSyncV1VaultAddress)
	{
		(bool admin,) = IYieldSyncV1VaultAccessControl(
			YieldSyncV1VaultAccessControl
		).participant_yieldSyncV1Vault_access(
			msg.sender,
			yieldSyncV1VaultAddress
		);

		require(admin || msg.sender == YieldSyncV1VaultFactory, "!admin && !YieldSyncV1VaultFactory");

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
	* @dev [delete] `_yieldSyncV1Vault_transferRequestId_transferRequest[yieldSyncV1VaultAddress]` value
	* @dev [delete] `_yieldSyncV1Vault_transferRequestId_transferRequestVote[yieldSyncV1VaultAddress]` value
	*      [delete] `_yieldSyncV1VaultAddress_idsOfOpenTransferRequests` value
	* @param yieldSyncV1VaultAddress {address}
	* @param transferRequestId {uint256}
	*/
	function _deleteTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId)
		internal
	{
		delete _yieldSyncV1Vault_transferRequestId_transferRequest[yieldSyncV1VaultAddress][transferRequestId];

		delete _yieldSyncV1Vault_transferRequestId_transferRequestVote[yieldSyncV1VaultAddress][transferRequestId];

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


	function yieldSyncV1Vault_againstVoteRequired(address yieldSyncV1VaultAddress)
		public
		view
		override
		returns (uint256)
	{
		return _yieldSyncV1Vault_againstVoteRequired[yieldSyncV1VaultAddress];
	}

	function yieldSyncV1Vault_forVoteRequired(address yieldSyncV1VaultAddress)
		public
		view
		override
		returns (uint256)
	{
		return _yieldSyncV1Vault_forVoteRequired[yieldSyncV1VaultAddress];
	}

	function yieldSyncV1Vault_transferDelaySeconds(address yieldSyncV1VaultAddress)
		public
		view
		override
		returns (uint256)
	{
		return _yieldSyncV1Vault_againstVoteRequired[yieldSyncV1VaultAddress];
	}


	function yieldSyncV1Vault_idsOfOpenTransferRequests(address yieldSyncV1VaultAddress)
		public
		view
		override
		returns (uint256[] memory)
	{
		return _yieldSyncV1Vault_openTransferRequestIds[yieldSyncV1VaultAddress];
	}

	function yieldSyncV1Vault_transferRequestId_transferRequest(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId
	)
		public
		view
		override
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
		returns (TransferRequest memory)
	{
		return _yieldSyncV1Vault_transferRequestId_transferRequest[yieldSyncV1VaultAddress][transferRequestId];
	}

	function yieldSyncV1Vault_transferRequestId_transferRequestVote(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId
	)
		public
		view
		override
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
		returns (TransferRequestVote memory)
	{
		return _yieldSyncV1Vault_transferRequestId_transferRequestVote[yieldSyncV1VaultAddress][transferRequestId];
	}

	function transferRequestStatus(address yieldSyncV1VaultAddress, uint256 transferRequestId)
		public
		view
		onlyMember(yieldSyncV1VaultAddress)
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
		returns (bool readyToBeProcessed, bool approved, string memory message)
	{
		TransferRequestVote memory transferRequestVote = _yieldSyncV1Vault_transferRequestId_transferRequestVote[
			yieldSyncV1VaultAddress
		][
			transferRequestId
		];

		if (
			transferRequestVote.forVoteCount >= _yieldSyncV1Vault_forVoteRequired[yieldSyncV1VaultAddress] ||
			transferRequestVote.againstVoteCount >= _yieldSyncV1Vault_againstVoteRequired[yieldSyncV1VaultAddress]
		)
		{
			if (
				transferRequestVote.forVoteCount >= _yieldSyncV1Vault_forVoteRequired[yieldSyncV1VaultAddress] &&
				transferRequestVote.againstVoteCount < _yieldSyncV1Vault_againstVoteRequired[yieldSyncV1VaultAddress]
			)
			{
				if (
					block.timestamp - transferRequestVote.latestRelevantForVoteTime >= (
						_yieldSyncV1Vault_transferDelaySeconds[yieldSyncV1VaultAddress] * 1 seconds
					)
				)
				{
					return (true, true, "Transfer request approved");
				}

				return (false, true, "Transfer request approved and waiting delay");
			}

			return (true, false, "Transfer request denied");
		}

		return (false, false, "Transfer request pending");
	}


	function deleteTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId)
		public
		override
		onlyAdminOrYieldSyncV1VaultFactory(yieldSyncV1VaultAddress)
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
	{
		_deleteTransferRequest(yieldSyncV1VaultAddress, transferRequestId);

		emit DeletedTransferRequest(yieldSyncV1VaultAddress, transferRequestId);
	}

	function updateTransferRequest(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId,
		TransferRequest memory transferRequest
	)
		public
		override
		onlyAdminOrYieldSyncV1VaultFactory(yieldSyncV1VaultAddress)
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
	{
		_yieldSyncV1Vault_transferRequestId_transferRequest[yieldSyncV1VaultAddress][
			transferRequestId
		] = transferRequest;

		emit UpdatedTransferRequest(yieldSyncV1VaultAddress, transferRequest);
	}

	function updateAgainstVoteRequired(address yieldSyncV1VaultAddress, uint256 _againstVoteRequired)
		public
		override
		onlyAdminOrYieldSyncV1VaultFactory(yieldSyncV1VaultAddress)
	{
		require(_againstVoteRequired > 0, "!_againstVoteRequired");

		_yieldSyncV1Vault_againstVoteRequired[yieldSyncV1VaultAddress] = _againstVoteRequired;

		emit UpdatedAgainstVoteRequired(yieldSyncV1VaultAddress, _againstVoteRequired);
	}

	function updateForVoteRequired(address yieldSyncV1VaultAddress, uint256 _forVoteRequired)
		public
		override
		onlyAdminOrYieldSyncV1VaultFactory(yieldSyncV1VaultAddress)
	{
		require(_forVoteRequired > 0, "!_forVoteRequired");

		_yieldSyncV1Vault_forVoteRequired[yieldSyncV1VaultAddress] = _forVoteRequired;

		emit UpdatedForVoteRequired(yieldSyncV1VaultAddress, _forVoteRequired);
	}

	function updateTransferDelaySeconds(address yieldSyncV1VaultAddress, uint256 _transferDelaySeconds)
		public
		override
		onlyAdminOrYieldSyncV1VaultFactory(yieldSyncV1VaultAddress)
	{
		require(_transferDelaySeconds >= 0, "!_transferDelaySeconds");

		_yieldSyncV1Vault_transferDelaySeconds[yieldSyncV1VaultAddress] = _transferDelaySeconds;

		emit UpdatedTransferDelaySeconds(yieldSyncV1VaultAddress, _transferDelaySeconds);
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

		_yieldSyncV1Vault_transferRequestId_transferRequest[yieldSyncV1VaultAddress][
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

		_yieldSyncV1Vault_transferRequestId_transferRequestVote[yieldSyncV1VaultAddress][
			_transferRequestIdTracker
		] = TransferRequestVote(
			{
				forVoteCount: 0,
				againstVoteCount: 0,
				latestRelevantForVoteTime: block.timestamp,
				votedMembers: initialVotedMembers
			}
		);

		_yieldSyncV1Vault_openTransferRequestIds[yieldSyncV1VaultAddress].push(_transferRequestIdTracker);

		_transferRequestIdTracker++;

		emit CreatedTransferRequest(yieldSyncV1VaultAddress, _transferRequestIdTracker - 1);
	}

	function voteOnTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId, bool vote)
		public
		override
		onlyMember(yieldSyncV1VaultAddress)
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
	{
		TransferRequestVote storage transferRequestVote = _yieldSyncV1Vault_transferRequestId_transferRequestVote[
			yieldSyncV1VaultAddress
		][
			transferRequestId
		];

		require(
			transferRequestVote.forVoteCount < _yieldSyncV1Vault_forVoteRequired[yieldSyncV1VaultAddress] &&
			transferRequestVote.againstVoteCount < _yieldSyncV1Vault_againstVoteRequired[yieldSyncV1VaultAddress],
			"Voting closed"
		);

		for (uint256 i = 0; i < transferRequestVote.votedMembers.length; i++)
		{
			require(
				transferRequestVote.votedMembers[i] != msg.sender,
				"Already voted"
			);
		}

		if (vote)
		{
			transferRequestVote.forVoteCount++;
		}
		else
		{
			transferRequestVote.againstVoteCount++;
		}

		if (
			transferRequestVote.forVoteCount >= _yieldSyncV1Vault_forVoteRequired[yieldSyncV1VaultAddress] ||
			transferRequestVote.againstVoteCount >= _yieldSyncV1Vault_againstVoteRequired[yieldSyncV1VaultAddress]
		)
		{
			emit TransferRequestReadyToBeProcessed(yieldSyncV1VaultAddress, transferRequestId);
		}

		transferRequestVote.votedMembers.push(msg.sender);

		if (transferRequestVote.forVoteCount < _yieldSyncV1Vault_forVoteRequired[yieldSyncV1VaultAddress])
		{
			transferRequestVote.latestRelevantForVoteTime = block.timestamp;
		}

		_yieldSyncV1Vault_transferRequestId_transferRequestVote[yieldSyncV1VaultAddress][
			transferRequestId
		] = transferRequestVote;

		emit MemberVoted(yieldSyncV1VaultAddress, transferRequestId, msg.sender, vote);
	}
}
