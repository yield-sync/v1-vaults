// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import {
	ITransferRequestProtocol,
	IYieldSyncV1TransferRequestProtocol,
	TransferRequest,
	TransferRequestVote,
	YieldSyncV1VaultProperty
} from "./interface/IYieldSyncV1TransferRequestProtocol.sol";
import { IYieldSyncV1VaultAccessControl } from "./interface/IYieldSyncV1VaultAccessControl.sol";


contract YieldSyncV1TransferRequestProtocol is
	ITransferRequestProtocol,
	IYieldSyncV1TransferRequestProtocol
{
	uint256 internal _transferRequestIdTracker;

	address public override immutable YieldSyncV1VaultAccessControl;
	address public override immutable YieldSyncV1VaultFactory;

	mapping (
		address yieldSyncV1Vault => uint256[] openTransferRequestsIds
	) internal _yieldSyncV1Vault_openTransferRequestIds;

	mapping (
		address purposer => YieldSyncV1VaultProperty yieldSyncV1VaultProperty
	) internal _purposer_yieldSyncV1VaultProperty;

	mapping (
		address yieldSyncV1Vault => YieldSyncV1VaultProperty yieldSyncV1VaultProperty
	) internal _yieldSyncV1Vault_yieldSyncV1VaultProperty;

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

	modifier onlyYieldSyncV1VaultFactory()
	{
		require(msg.sender == YieldSyncV1VaultFactory, "!YieldSyncV1VaultFactory");

		_;
	}

	modifier validTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId)
	{
		require(
			_yieldSyncV1Vault_transferRequestId_transferRequest[yieldSyncV1VaultAddress][transferRequestId].amount > 0,
			"No TransferRequest found"
		);

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


	/// @inheritdoc ITransferRequestProtocol
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

	/// @inheritdoc ITransferRequestProtocol
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

		YieldSyncV1VaultProperty memory yieldSyncV1VaultProperty = _yieldSyncV1Vault_yieldSyncV1VaultProperty[
			yieldSyncV1VaultAddress
		];

		if (
			transferRequestVote.forVoteCount >= yieldSyncV1VaultProperty.forVoteRequired ||
			transferRequestVote.againstVoteCount >= yieldSyncV1VaultProperty.againstVoteRequired
		)
		{
			if (
				transferRequestVote.forVoteCount >= yieldSyncV1VaultProperty.forVoteRequired &&
				transferRequestVote.againstVoteCount < yieldSyncV1VaultProperty.againstVoteRequired
			)
			{
				if (
					block.timestamp - transferRequestVote.latestRelevantForVoteTime >= (
						yieldSyncV1VaultProperty.transferDelaySeconds * 1 seconds
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

	/// @inheritdoc ITransferRequestProtocol
	function initializeYieldSyncV1Vault(address purposer, address yieldSyncV1VaultAddress)
		public
		override
		onlyYieldSyncV1VaultFactory()
	{
		_yieldSyncV1Vault_yieldSyncV1VaultProperty[yieldSyncV1VaultAddress] = _purposer_yieldSyncV1VaultProperty[
			purposer
		];
	}


	/// @inheritdoc IYieldSyncV1TransferRequestProtocol
	function yieldSyncV1Vault_idsOfOpenTransferRequests(address yieldSyncV1VaultAddress)
		public
		view
		override
		returns (uint256[] memory)
	{
		return _yieldSyncV1Vault_openTransferRequestIds[yieldSyncV1VaultAddress];
	}

	/// @inheritdoc IYieldSyncV1TransferRequestProtocol
	function purposer_YieldSyncV1VaultProperty(address yieldSyncV1VaultAddress)
		public
		view
		override
		returns (YieldSyncV1VaultProperty memory)
	{
		return _purposer_yieldSyncV1VaultProperty[yieldSyncV1VaultAddress];
	}

	/// @inheritdoc IYieldSyncV1TransferRequestProtocol
	function yieldSyncV1Vault_YieldSyncV1VaultProperty(address yieldSyncV1VaultAddress)
		public
		view
		override
		returns (YieldSyncV1VaultProperty memory)
	{
		return _yieldSyncV1Vault_yieldSyncV1VaultProperty[yieldSyncV1VaultAddress];
	}


	/// @inheritdoc IYieldSyncV1TransferRequestProtocol
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


	/// @inheritdoc IYieldSyncV1TransferRequestProtocol
	function update_purposer_yieldSyncV1VaultProperty(YieldSyncV1VaultProperty memory yieldSyncV1VaultProperty)
		public
		override
	{
		_purposer_yieldSyncV1VaultProperty[msg.sender] = yieldSyncV1VaultProperty;
	}


	/// @inheritdoc IYieldSyncV1TransferRequestProtocol
	function deleteTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId)
		public
		override
		onlyAdmin(yieldSyncV1VaultAddress)
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
	{
		_deleteTransferRequest(yieldSyncV1VaultAddress, transferRequestId);

		emit DeletedTransferRequest(yieldSyncV1VaultAddress, transferRequestId);
	}

	/// @inheritdoc IYieldSyncV1TransferRequestProtocol
	function updateTransferRequest(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId,
		TransferRequest memory transferRequest
	)
		public
		override
		onlyAdmin(yieldSyncV1VaultAddress)
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
	{
		_yieldSyncV1Vault_transferRequestId_transferRequest[yieldSyncV1VaultAddress][
			transferRequestId
		] = transferRequest;

		emit UpdatedTransferRequest(
			yieldSyncV1VaultAddress,
			_yieldSyncV1Vault_transferRequestId_transferRequest[yieldSyncV1VaultAddress][transferRequestId]
		);
	}

	/// @inheritdoc IYieldSyncV1TransferRequestProtocol
	function updateTransferRequestVote(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId,
		TransferRequestVote memory transferRequestVote
	)
		public
		override
		onlyAdmin(yieldSyncV1VaultAddress)
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
	{
		_yieldSyncV1Vault_transferRequestId_transferRequestVote[yieldSyncV1VaultAddress][
			transferRequestId
		] = transferRequestVote;

		emit UpdatedTransferRequestVote(
			yieldSyncV1VaultAddress,
			_yieldSyncV1Vault_transferRequestId_transferRequestVote[yieldSyncV1VaultAddress][transferRequestId]
		);
	}

	/// @inheritdoc IYieldSyncV1TransferRequestProtocol
	function update_yieldSyncV1Vault_yieldSyncV1VaultProperty(
		address yieldSyncV1VaultAddress,
		YieldSyncV1VaultProperty memory yieldSyncV1VaultProperty
	)
		public
		override
		onlyAdmin(yieldSyncV1VaultAddress)
	{
		require(yieldSyncV1VaultProperty.againstVoteRequired > 0, "!_againstVoteRequired");
		require(yieldSyncV1VaultProperty.forVoteRequired > 0, "!_againstVoteRequired");

		_yieldSyncV1Vault_yieldSyncV1VaultProperty[yieldSyncV1VaultAddress] = yieldSyncV1VaultProperty;
	}


	/// @inheritdoc IYieldSyncV1TransferRequestProtocol
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

	/// @inheritdoc IYieldSyncV1TransferRequestProtocol
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

		YieldSyncV1VaultProperty memory yieldSyncV1VaultProperty = _yieldSyncV1Vault_yieldSyncV1VaultProperty[
			yieldSyncV1VaultAddress
		];

		require(
			transferRequestVote.forVoteCount < yieldSyncV1VaultProperty.forVoteRequired &&
			transferRequestVote.againstVoteCount < yieldSyncV1VaultProperty.againstVoteRequired,
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
			transferRequestVote.forVoteCount >= yieldSyncV1VaultProperty.forVoteRequired ||
			transferRequestVote.againstVoteCount >= yieldSyncV1VaultProperty.againstVoteRequired
		)
		{
			emit TransferRequestReadyToBeProcessed(yieldSyncV1VaultAddress, transferRequestId);
		}

		transferRequestVote.votedMembers.push(msg.sender);

		if (transferRequestVote.forVoteCount < yieldSyncV1VaultProperty.forVoteRequired)
		{
			transferRequestVote.latestRelevantForVoteTime = block.timestamp;
		}

		_yieldSyncV1Vault_transferRequestId_transferRequestVote[yieldSyncV1VaultAddress][
			transferRequestId
		] = transferRequestVote;

		emit MemberVoted(yieldSyncV1VaultAddress, transferRequestId, msg.sender, vote);
	}
}
