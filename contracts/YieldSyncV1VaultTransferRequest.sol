// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


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


	uint256 internal _transferRequestIdTracker;

	address public override immutable YieldSyncV1VaultAccessControl;

	mapping (
		address yieldSyncV1Vault => uint256 againstVoteCountRequired
	) internal _yieldSyncV1Vault_againstVoteCountRequired;
	mapping (
		address yieldSyncV1Vault => uint256 forVoteCountRequired
	) internal _yieldSyncV1Vault_forVoteCountRequired;
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


	constructor (address _YieldSyncV1VaultAccessControl)
	{
		YieldSyncV1VaultAccessControl = _YieldSyncV1VaultAccessControl;

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
	* @dev [delete] `_yieldSyncV1Vault_transferRequestId_transferRequest[yieldSyncV1VaultAddress]` value
	*      [delete] `_yieldSyncV1VaultAddress_idsOfOpenTransferRequests` value
	* @param yieldSyncV1VaultAddress {address}
	* @param transferRequestId {uint256}
	*/
	function _deleteTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId)
		internal
	{
		delete _yieldSyncV1Vault_transferRequestId_transferRequest[yieldSyncV1VaultAddress][transferRequestId];

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


	function yieldSyncV1Vault_againstVoteCountRequired(address yieldSyncV1VaultAddress)
		public
		view
		override
		returns (uint256)
	{
		return _yieldSyncV1Vault_againstVoteCountRequired[yieldSyncV1VaultAddress];
	}

	function yieldSyncV1Vault_forVoteCountRequired(address yieldSyncV1VaultAddress)
		public
		view
		override
		returns (uint256)
	{
		return _yieldSyncV1Vault_forVoteCountRequired[yieldSyncV1VaultAddress];
	}

	function yieldSyncV1Vault_transferDelaySeconds(address yieldSyncV1VaultAddress)
		public
		view
		override
		returns (uint256)
	{
		return _yieldSyncV1Vault_againstVoteCountRequired[yieldSyncV1VaultAddress];
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

	function transferRequestStatus(address yieldSyncV1VaultAddress, uint256 transferRequestId)
		public
		view
		onlyMember(yieldSyncV1VaultAddress)
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
		returns (bool readyToBeProcessed, bool approved, string memory message)
	{
		TransferRequest memory transferRequest = _yieldSyncV1Vault_transferRequestId_transferRequest[
			yieldSyncV1VaultAddress
		][
			transferRequestId
		];

		if (
			transferRequest.forVoteCount >= _yieldSyncV1Vault_forVoteCountRequired[yieldSyncV1VaultAddress] ||
			transferRequest.againstVoteCount >= _yieldSyncV1Vault_againstVoteCountRequired[yieldSyncV1VaultAddress]
		)
		{
			if (
				transferRequest.forVoteCount >= _yieldSyncV1Vault_forVoteCountRequired[yieldSyncV1VaultAddress] &&
				transferRequest.againstVoteCount < _yieldSyncV1Vault_againstVoteCountRequired[yieldSyncV1VaultAddress]
			)
			{
				if (
					block.timestamp - transferRequest.latestRelevantForVoteTime >= (
						_yieldSyncV1Vault_transferDelaySeconds[yieldSyncV1VaultAddress] * 1 seconds
					)
				)
				{
					return (true, true, "Transfer request approved");
				}

				return (true, false, "Transfer request approved and waiting delay");
			}

			return (true, false, "Transfer request denied");
		}

		return (false, false, "Transfer request pending");
	}


	function deleteTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId)
		public
		override
		onlyAdmin(yieldSyncV1VaultAddress)
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
		onlyAdmin(yieldSyncV1VaultAddress)
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
	{
		_yieldSyncV1Vault_transferRequestId_transferRequest[yieldSyncV1VaultAddress][
			transferRequestId
		] = transferRequest;

		emit UpdatedTransferRequest(yieldSyncV1VaultAddress, transferRequest);
	}

	function updateAgainstVoteCountRequired(address yieldSyncV1VaultAddress, uint256 _againstVoteCountRequired)
		public
		override
		onlyAdmin(yieldSyncV1VaultAddress)
	{
		require(_againstVoteCountRequired > 0, "!_againstVoteCountRequired");

		_yieldSyncV1Vault_againstVoteCountRequired[yieldSyncV1VaultAddress] = _againstVoteCountRequired;

		emit UpdatedAgainstVoteCountRequired(yieldSyncV1VaultAddress, _againstVoteCountRequired);
	}

	function updateForVoteCountRequired(address yieldSyncV1VaultAddress, uint256 _forVoteCountRequired)
		public
		override
		onlyAdmin(yieldSyncV1VaultAddress)
	{
		require(_forVoteCountRequired > 0, "!_forVoteCountRequired");

		_yieldSyncV1Vault_forVoteCountRequired[yieldSyncV1VaultAddress] = _forVoteCountRequired;

		emit UpdatedForVoteCountRequired(yieldSyncV1VaultAddress, _forVoteCountRequired);
	}

	function updateTransferDelaySeconds(address yieldSyncV1VaultAddress, uint256 _transferDelaySeconds)
		public
		override
		onlyAdmin(yieldSyncV1VaultAddress)
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
				to: to,
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
		TransferRequest storage transferRequest = _yieldSyncV1Vault_transferRequestId_transferRequest[
			yieldSyncV1VaultAddress
		][
			transferRequestId
		];

		require(
			transferRequest.forVoteCount < _yieldSyncV1Vault_forVoteCountRequired[yieldSyncV1VaultAddress] &&
			transferRequest.againstVoteCount < _yieldSyncV1Vault_againstVoteCountRequired[yieldSyncV1VaultAddress],
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
			transferRequest.forVoteCount >= _yieldSyncV1Vault_forVoteCountRequired[yieldSyncV1VaultAddress] ||
			transferRequest.againstVoteCount >= _yieldSyncV1Vault_againstVoteCountRequired[yieldSyncV1VaultAddress]
		)
		{
			emit TransferRequestReadyToBeProcessed(yieldSyncV1VaultAddress, transferRequestId);
		}

		transferRequest.votedMembers.push(msg.sender);

		if (transferRequest.forVoteCount < _yieldSyncV1Vault_forVoteCountRequired[yieldSyncV1VaultAddress])
		{
			transferRequest.latestRelevantForVoteTime = block.timestamp;
		}

		_yieldSyncV1Vault_transferRequestId_transferRequest[yieldSyncV1VaultAddress][
			transferRequestId
		] = transferRequest;

		emit MemberVoted(yieldSyncV1VaultAddress, transferRequestId, msg.sender, vote);
	}
}
