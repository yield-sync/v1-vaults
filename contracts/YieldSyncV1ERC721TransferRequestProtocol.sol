// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {
	ITransferRequestProtocol,
	IYieldSyncV1ERC721TransferRequestProtocol,
	IYieldSyncV1VaultRegistry,
	TransferRequest,
	TransferRequestPoll,
	YieldSyncV1VaultProperty
} from "./interface/IYieldSyncV1ERC721TransferRequestProtocol.sol";


contract YieldSyncV1ERC721TransferRequestProtocol is
	ReentrancyGuard,
	ITransferRequestProtocol,
	IYieldSyncV1ERC721TransferRequestProtocol
{
	uint256 internal _transferRequestIdTracker;

	IYieldSyncV1VaultRegistry public immutable YieldSyncV1VaultRegistry;

	mapping (address yieldSyncV1Vault => uint256[] openTransferRequestsIds) internal _yieldSyncV1Vault_openTransferRequestIds;

	mapping (
		address yieldSyncV1Vault => YieldSyncV1VaultProperty yieldSyncV1VaultProperty
	) internal _yieldSyncV1Vault_yieldSyncV1VaultProperty;

	mapping (
		address yieldSyncV1Vault => mapping (uint256 _transferRequestId => TransferRequest transferRequest)
	) internal _yieldSyncV1Vault_transferRequestId_transferRequest;

	mapping (
		address yieldSyncV1Vault => mapping (uint256 _transferRequestId => TransferRequestPoll transferRequestPoll)
	) internal _yieldSyncV1Vault_transferRequestId_transferRequestPoll;


	constructor (address _YieldSyncV1VaultRegistry)
	{
		YieldSyncV1VaultRegistry = IYieldSyncV1VaultRegistry(_YieldSyncV1VaultRegistry);

		_transferRequestIdTracker = 0;
	}


	modifier accessAdmin(address _yieldSyncV1Vault)
	{
		(bool admin,) = YieldSyncV1VaultRegistry.yieldSyncV1Vault_participant_access(_yieldSyncV1Vault, msg.sender);

		require(admin || msg.sender == _yieldSyncV1Vault, "!admin && msg.sender != _yieldSyncV1Vault");

		_;
	}

	modifier contractYieldSyncV1Vault(address _yieldSyncV1Vault)
	{
		require(msg.sender == _yieldSyncV1Vault, "!_yieldSyncV1Vault");

		_;
	}

	modifier validTransferRequest(address _yieldSyncV1Vault, uint256 _transferRequestId)
	{
		require(
			_yieldSyncV1Vault_transferRequestId_transferRequest[_yieldSyncV1Vault][_transferRequestId].amount > 0,
			"No TransferRequest found"
		);

		_;
	}


	/**
	* @notice Delete TransferRequest
	* @dev [restriction][internal]
	* @dev [delete] `_yieldSyncV1Vault_transferRequestId_transferRequest[_yieldSyncV1Vault]` value
	* @dev [delete] `_yieldSyncV1Vault_transferRequestId_transferRequestPoll[_yieldSyncV1Vault]` value
	*      [delete] `_yieldSyncV1Vault_openTransferRequestIds` value
	* @param _yieldSyncV1Vault {address}
	* @param _transferRequestId {uint256}
	*/
	function _yieldSyncV1Vault_transferRequestId_transferRequestDelete(
		address _yieldSyncV1Vault,
		uint256 _transferRequestId
	)
		internal
	{
		delete _yieldSyncV1Vault_transferRequestId_transferRequest[_yieldSyncV1Vault][_transferRequestId];

		delete _yieldSyncV1Vault_transferRequestId_transferRequestPoll[_yieldSyncV1Vault][_transferRequestId];

		for (uint256 i = 0; i < _yieldSyncV1Vault_openTransferRequestIds[_yieldSyncV1Vault].length; i++)
		{
			if (_yieldSyncV1Vault_openTransferRequestIds[_yieldSyncV1Vault][i] == _transferRequestId)
			{
				_yieldSyncV1Vault_openTransferRequestIds[_yieldSyncV1Vault][i] = _yieldSyncV1Vault_openTransferRequestIds[
					_yieldSyncV1Vault
				][
					_yieldSyncV1Vault_openTransferRequestIds[_yieldSyncV1Vault].length - 1
				];

				_yieldSyncV1Vault_openTransferRequestIds[_yieldSyncV1Vault].pop();

				break;
			}
		}
	}


	/// @inheritdoc ITransferRequestProtocol
	function yieldSyncV1Vault_transferRequestId_transferRequest(address _yieldSyncV1Vault, uint256 _transferRequestId)
		public
		view
		returns (TransferRequest memory transferRequest_)
	{
		return _yieldSyncV1Vault_transferRequestId_transferRequest[_yieldSyncV1Vault][_transferRequestId];
	}

	/// @inheritdoc ITransferRequestProtocol
	function yieldSyncV1Vault_transferRequestId_transferRequestStatus(
		address _yieldSyncV1Vault,
		uint256 _transferRequestId
	)
		public
		view
		returns (bool readyToBeProcessed_, bool approved_, string memory message_)
	{
		TransferRequestPoll memory transferRequestPoll = _yieldSyncV1Vault_transferRequestId_transferRequestPoll[
			_yieldSyncV1Vault
		][
			_transferRequestId
		];

		YieldSyncV1VaultProperty memory yieldSyncV1VaultProperty = _yieldSyncV1Vault_yieldSyncV1VaultProperty[
			_yieldSyncV1Vault
		];

		if (
			transferRequestPoll.voteAgainstErc721TokenId.length < yieldSyncV1VaultProperty.voteAgainstRequired &&
			transferRequestPoll.voteForErc721TokenId.length < yieldSyncV1VaultProperty.voteForRequired
		)
		{
			return (false, false, "TransferRequest pending");
		}

		if (transferRequestPoll.voteAgainstErc721TokenId.length >= yieldSyncV1VaultProperty.voteAgainstRequired)
		{
			return (true, false, "TransferRequest denied");
		}

		return (true, true, "TransferRequest approved");
	}

	/// @inheritdoc ITransferRequestProtocol
	function yieldSyncV1Vault_transferRequestId_transferRequestProcess(
		address _yieldSyncV1Vault,
		uint256 _transferRequestId
	)
		public
		override
		contractYieldSyncV1Vault(_yieldSyncV1Vault)
		validTransferRequest(_yieldSyncV1Vault, _transferRequestId)
	{
		_yieldSyncV1Vault_transferRequestId_transferRequestDelete(_yieldSyncV1Vault, _transferRequestId);

		emit DeletedTransferRequest(_yieldSyncV1Vault, _transferRequestId);
	}


	/// @inheritdoc ITransferRequestProtocol
	function yieldSyncV1VaultInitialize(address _initiator, address _yieldSyncV1Vault)
		public
		//override
		contractYieldSyncV1Vault(_yieldSyncV1Vault)
	{
		require(
			_yieldSyncV1Vault_yieldSyncV1VaultProperty[_initiator].erc721Token != address(0),
			"!_yieldSyncV1Vault_yieldSyncV1VaultProperty[_initiator].erc721Token"
		);

		require(
			_yieldSyncV1Vault_yieldSyncV1VaultProperty[_initiator].voteAgainstRequired > 0,
			"!_yieldSyncV1Vault_yieldSyncV1VaultProperty[_initiator].voteAgainstRequired"
		);

		require(
			_yieldSyncV1Vault_yieldSyncV1VaultProperty[_initiator].voteForRequired > 0,
			"!_yieldSyncV1Vault_yieldSyncV1VaultProperty[_initiator].voteForRequired"
		);

		_yieldSyncV1Vault_yieldSyncV1VaultProperty[_yieldSyncV1Vault] = _yieldSyncV1Vault_yieldSyncV1VaultProperty[_initiator];
	}

	///
	function yieldSyncV1Vault_openTransferRequestIds(address _yieldSyncV1Vault)
		public
		view
		//override
		returns (uint256[] memory)
	{
		return _yieldSyncV1Vault_openTransferRequestIds[_yieldSyncV1Vault];
	}

	///
	function yieldSyncV1Vault_yieldSyncV1VaultProperty(address _yieldSyncV1Vault)
		public
		view
		//override
		returns (YieldSyncV1VaultProperty memory)
	{
		return _yieldSyncV1Vault_yieldSyncV1VaultProperty[_yieldSyncV1Vault];
	}

	///
	function yieldSyncV1Vault_transferRequestId_transferRequestPoll(
		address _yieldSyncV1Vault,
		uint256 _transferRequestId
	)
		public
		view
		//override
		validTransferRequest(_yieldSyncV1Vault, _transferRequestId)
		returns (TransferRequestPoll memory)
	{
		return _yieldSyncV1Vault_transferRequestId_transferRequestPoll[_yieldSyncV1Vault][_transferRequestId];
	}


	///
	function yieldSyncV1Vault_transferRequestId_transferRequestAdminDelete(
		address _yieldSyncV1Vault,
		uint256 _transferRequestId
	)
		public
		//override
		accessAdmin(_yieldSyncV1Vault)
		validTransferRequest(_yieldSyncV1Vault, _transferRequestId)
	{
		_yieldSyncV1Vault_transferRequestId_transferRequestDelete(_yieldSyncV1Vault, _transferRequestId);

		emit DeletedTransferRequest(_yieldSyncV1Vault, _transferRequestId);
	}

	///
	function yieldSyncV1Vault_transferRequestId_transferRequestAdminUpdate(
		address _yieldSyncV1Vault,
		uint256 _transferRequestId,
		TransferRequest memory transferRequest
	)
		public
		//override
		accessAdmin(_yieldSyncV1Vault)
		validTransferRequest(_yieldSyncV1Vault, _transferRequestId)
	{
		require(transferRequest.amount > 0, "!_transferRequest.amount");

		require(
			!(transferRequest.forERC20 && transferRequest.forERC721),
			"_transferRequest.forERC20 && _transferRequest.forERC721"
		);

		_yieldSyncV1Vault_transferRequestId_transferRequest[_yieldSyncV1Vault][_transferRequestId] = transferRequest;

		emit UpdateTransferRequest(
			_yieldSyncV1Vault,
			_yieldSyncV1Vault_transferRequestId_transferRequest[_yieldSyncV1Vault][_transferRequestId]
		);
	}

	///
	function yieldSyncV1Vault_transferRequestId_transferRequestCreate(
		address _yieldSyncV1Vault,
		bool _forERC20,
		bool _forERC721,
		address _to,
		address _token,
		uint256 _amount,
		uint256 _tokenId
	)
		public
		//override
	{
		require(_amount > 0, "!_amount");

		require(!(_forERC20 && _forERC721), "_forERC20 && _forERC721");

		uint256[] memory emptyArray;

		_yieldSyncV1Vault_transferRequestId_transferRequest[_yieldSyncV1Vault][_transferRequestIdTracker] = TransferRequest(
			{
				forERC20: _forERC20,
				forERC721: _forERC721,
				creator: msg.sender,
				to: _to,
				token: _token,
				amount: _amount,
				created: block.timestamp,
				tokenId: _tokenId
			}
		);

		_yieldSyncV1Vault_transferRequestId_transferRequestPoll[_yieldSyncV1Vault][
			_transferRequestIdTracker
		] = TransferRequestPoll(
			{
				voteAgainstErc721TokenId: emptyArray,
				voteForErc721TokenId: emptyArray
			}
		);

		_yieldSyncV1Vault_openTransferRequestIds[_yieldSyncV1Vault].push(_transferRequestIdTracker);

		_transferRequestIdTracker++;

		emit CreatedTransferRequest(_yieldSyncV1Vault, _transferRequestIdTracker - 1);
	}

	///
	function yieldSyncV1Vault_transferRequestId_transferRequestDelete(
		address _yieldSyncV1Vault,
		uint256 _transferRequestId
	)
		public
		//override
		accessAdmin(_yieldSyncV1Vault)
		validTransferRequest(_yieldSyncV1Vault, _transferRequestId)
	{
		require(
			_yieldSyncV1Vault_transferRequestId_transferRequest[_yieldSyncV1Vault][_transferRequestId].creator == msg.sender,
			"_yieldSyncV1Vault_transferRequestId_transferRequest[_yieldSyncV1Vault][_transferRequestId].creator != msg.sender"
		);

		_yieldSyncV1Vault_transferRequestId_transferRequestDelete(_yieldSyncV1Vault, _transferRequestId);

		emit DeletedTransferRequest(_yieldSyncV1Vault, _transferRequestId);
	}

	///
	function yieldSyncV1Vault_transferRequestId_transferRequestPollAdminUpdate(
		address _yieldSyncV1Vault,
		uint256 _transferRequestId,
		TransferRequestPoll memory transferRequestPoll
	)
		public
		//override
		validTransferRequest(_yieldSyncV1Vault, _transferRequestId)
	{
		_yieldSyncV1Vault_transferRequestId_transferRequestPoll[_yieldSyncV1Vault][_transferRequestId] = transferRequestPoll;

		emit UpdateTransferRequestPoll(
			_yieldSyncV1Vault,
			_yieldSyncV1Vault_transferRequestId_transferRequestPoll[_yieldSyncV1Vault][_transferRequestId]
		);
	}

	///
	function yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
		address _yieldSyncV1Vault,
		uint256 _transferRequestId,
		bool _vote,
		uint256[] memory tokenIds
	)
		public
		//override
		nonReentrant()
		validTransferRequest(_yieldSyncV1Vault, _transferRequestId)
	{
		TransferRequestPoll storage transferRequestPoll = _yieldSyncV1Vault_transferRequestId_transferRequestPoll[
			_yieldSyncV1Vault
		][
			_transferRequestId
		];

		YieldSyncV1VaultProperty memory yieldSyncV1VaultProperty = _yieldSyncV1Vault_yieldSyncV1VaultProperty[
			_yieldSyncV1Vault
		];

		require(
			transferRequestPoll.voteAgainstErc721TokenId.length < yieldSyncV1VaultProperty.voteAgainstRequired &&
			transferRequestPoll.voteForErc721TokenId.length < yieldSyncV1VaultProperty.voteForRequired,
			"Voting closed"
		);

		for (uint256 i = 0; i < tokenIds.length; i++)
		{
			require(
				IERC721(yieldSyncV1VaultProperty.erc721Token).ownerOf(tokenIds[i]) == msg.sender,
				"IERC721(yieldSyncV1VaultProperty.erc721Token).ownerOf(tokenIds[i]) != msg.sender"
			);

			for (uint256 ii = 0; ii < transferRequestPoll.voteAgainstErc721TokenId.length; ii++)
			{
				require(tokenIds[i] != transferRequestPoll.voteAgainstErc721TokenId[ii], "Already voted");
			}

			for (uint256 ii = 0; ii < transferRequestPoll.voteForErc721TokenId.length; ii++)
			{
				require(tokenIds[i] != transferRequestPoll.voteForErc721TokenId[ii], "Already voted");
			}

			if (_vote)
			{
				transferRequestPoll.voteForErc721TokenId.push(tokenIds[i]);
			}
			else
			{
				transferRequestPoll.voteAgainstErc721TokenId.push(tokenIds[i]);
			}
		}

		if (
			transferRequestPoll.voteAgainstErc721TokenId.length >= yieldSyncV1VaultProperty.voteAgainstRequired ||
			transferRequestPoll.voteForErc721TokenId.length >= yieldSyncV1VaultProperty.voteForRequired
		)
		{
			emit TransferRequestReadyToBeProcessed(_yieldSyncV1Vault, _transferRequestId);
		}

		_yieldSyncV1Vault_transferRequestId_transferRequestPoll[_yieldSyncV1Vault][_transferRequestId] = transferRequestPoll;

		emit MemberVoted(_yieldSyncV1Vault, _transferRequestId, msg.sender, _vote);
	}

	///
	function yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
		address _yieldSyncV1Vault,
		YieldSyncV1VaultProperty memory yieldSyncV1VaultProperty
	)
		public
		//override
		accessAdmin(_yieldSyncV1Vault)
	{
		require(yieldSyncV1VaultProperty.erc721Token != address(0), "!_yieldSyncV1VaultProperty.erc721Token");

		require(yieldSyncV1VaultProperty.voteAgainstRequired > 0, "!_yieldSyncV1VaultProperty.voteAgainstRequired");

		require(yieldSyncV1VaultProperty.voteForRequired > 0, "!_yieldSyncV1VaultProperty.voteForRequired");

		_yieldSyncV1Vault_yieldSyncV1VaultProperty[_yieldSyncV1Vault] = yieldSyncV1VaultProperty;
	}
}
