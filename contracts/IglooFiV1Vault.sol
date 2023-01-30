// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "hardhat/console.sol";

import { IIglooFiV1Vault, WithdrawalRequest } from "./interface/IIglooFiV1Vault.sol";


/**
* @title IglooFiV1Vault
*/
contract IglooFiV1Vault is
	AccessControlEnumerable,
	IERC1271,
	IIglooFiV1Vault
{
	using ECDSA for bytes32;

	// [bytes4][public]
	bytes4 public constant override INVALID_SIGNATURE = 0xffffffff;
	bytes4 public constant override MAGICVALUE = 0x1626ba7e;

	// [byte32][public]
	bytes32 public constant override VOTER = keccak256("VOTER");

	// [uint256][internal]
	uint256 internal _withdrawalRequestIdTracker;
	uint256[] internal _activeWithdrawalRequestIds;

	// [uint256][public]
	uint256 public override requiredVoteCount;
	uint256 public override withdrawalDelaySeconds;

	// [mapping][internal]
	// Message => votes
	mapping (bytes32 => uint256) internal _messageSignatures;
	// WithdrawalRequestId => WithdrawalRequest
	mapping (uint256 => WithdrawalRequest) internal _withdrawalRequest;


	constructor (
		address admin,
		uint256 _requiredVoteCount,
		uint256 _withdrawalDelaySeconds
	)
	{
		require(_requiredVoteCount > 0, "!_requiredVoteCount");

		_setupRole(DEFAULT_ADMIN_ROLE, admin);

		requiredVoteCount = _requiredVoteCount;
		withdrawalDelaySeconds = _withdrawalDelaySeconds;
		
		_withdrawalRequestIdTracker = 0;
	}


	receive ()
		external
		payable
	{
		emit EtherRecieved(msg.sender, msg.value);
	}


	fallback ()
		external
		payable
	{}


	modifier validWithdrawalRequest(uint256 withdrawalRequestId)
	{
		// [require] WithdrawalRequest exists
		require(
			_withdrawalRequest[withdrawalRequestId].creator != address(0),
			"No WithdrawalRequest found"
		);
		
		_;
	}


	/**
	* @notice Delete WithdrawalRequest
	* @dev [restriction][internal]
	* @dev [delete] `_withdrawalRequest` value
	*      [delete] `_activeWithdrawalRequestIds` value
	* @param withdrawalRequestId {uint256}
	* Emits: `DeletedWithdrawalRequest`
	*/
	function _deleteWithdrawalRequest(uint256 withdrawalRequestId)
		internal
	{
		// [delete] `_withdrawalRequest` value
		delete _withdrawalRequest[withdrawalRequestId];

		for (
			uint256 i = 0;
			i < _activeWithdrawalRequestIds.length;
			i++
		)
		{
			if (
				_activeWithdrawalRequestIds[i] == withdrawalRequestId
			)
			{
				// [delete] `_activeWithdrawalRequestIds` value
				delete _activeWithdrawalRequestIds[i];

				break;
			}
		}

		// [emit]
		emit DeletedWithdrawalRequest(withdrawalRequestId);
	}


	/// @inheritdoc IERC1271
	function isValidSignature(bytes32 _messageHash, bytes memory _signature)
		public
		view
		override
		returns (bytes4 magicValue)
	{
		address signer = _messageHash.recover(_signature);

		if (
			hasRole(VOTER, signer) &&
			_messageSignatures[_messageHash] >= requiredVoteCount
		)
		{
			return MAGICVALUE;
		}
		else
		{
			return INVALID_SIGNATURE;
		}
	}


	/// @inheritdoc IIglooFiV1Vault
	function activeWithdrawalRequestIds()
		public
		view
		returns (uint256[] memory)
	{
		return _activeWithdrawalRequestIds;
	}

	/// @inheritdoc IIglooFiV1Vault
	function messageSignatures(bytes32 message)
		view
		public
		override
		returns (uint256)
	{
		return _messageSignatures[message];
	}

	/// @inheritdoc IIglooFiV1Vault
	function withdrawalRequest(uint256 withdrawalRequestId)
		view
		public
		override
		returns (WithdrawalRequest memory)
	{
		return _withdrawalRequest[withdrawalRequestId];
	}

	/// @inheritdoc IIglooFiV1Vault
	function sign(bytes32 _messageHash, bytes memory _signature)
		public
	{
		address signer = _messageHash.recover(_signature);

		if (hasRole(VOTER, signer))
		{
			// [increment] Value in `_messageSignatures`
			_messageSignatures[_messageHash]++;
		}
	}


	/// @inheritdoc IIglooFiV1Vault
	function createWithdrawalRequest(
		bool forERC20,
		bool forERC721,
		address to,
		address tokenAddress,
		uint256 amount,
		uint256 tokenId
	)
		public
		override
		onlyRole(VOTER)
		returns (uint256)
	{
		require(to != address(0), "!to");
		require(amount > 0, "!amount");

		address[] memory votedVoters;

		// [add] `_withdrawalRequest` value
		_withdrawalRequest[_withdrawalRequestIdTracker] = WithdrawalRequest(
			{
				forERC20: forERC20,
				forERC721: forERC721,
				creator: msg.sender,
				to: to,
				token: tokenAddress,
				amount: amount,
				tokenId: tokenId,
				voteCount: 0,
				latestRelevantApproveVoteTime: block.timestamp,
				votedVoters: votedVoters
			}
		);

		// [push-into] `_activeWithdrawalRequestIds`
		_activeWithdrawalRequestIds.push(_withdrawalRequestIdTracker);

		// [emit]
		emit CreatedWithdrawalRequest(_withdrawalRequest[_withdrawalRequestIdTracker]);

		// [increment] `_withdrawalRequestIdTracker`
		_withdrawalRequestIdTracker++;
		
		return _withdrawalRequestIdTracker - 1;
	}

	/// @inheritdoc IIglooFiV1Vault
	function voteOnWithdrawalRequest(uint256 withdrawalRequestId, bool vote)
		public
		override
		onlyRole(VOTER)
		validWithdrawalRequest(withdrawalRequestId)
		returns (uint256, uint256)
	{
		// [init]
		bool voted = false;

		// [for] each voter within WithdrawalRequest
		for (
			uint256 i = 0;
			i < _withdrawalRequest[withdrawalRequestId].votedVoters.length;
			i++
		)
		{
			if (_withdrawalRequest[withdrawalRequestId].votedVoters[i] == msg.sender)
			{
				// Flag
				voted = true;

				break;
			}
		}

		// [require] msg.sender's (voter's) has not voted already
		require(!voted, "You have already casted a vote for this WithdrawalRequest");

		if (vote)
		{
			// [update] `_withdrawalRequest` → [increment] Approve vote count
			_withdrawalRequest[withdrawalRequestId].voteCount++;

			// If required signatures met..
			if (_withdrawalRequest[withdrawalRequestId].voteCount >= requiredVoteCount)
			{
				// [emit]
				emit WithdrawalRequestReadyToBeProccessed(withdrawalRequestId);
			}
		}

		// [emit]
		emit VoterVoted(withdrawalRequestId, msg.sender, vote);

		// [update] `_withdrawalRequest[withdrawalRequestId].votedVoters` → Add msg.sender
		_withdrawalRequest[withdrawalRequestId].votedVoters.push(msg.sender);

		// If the required signatures has not yet been reached..
		if (_withdrawalRequest[withdrawalRequestId].voteCount < requiredVoteCount)
		{
			// [update] latestRelevantApproveVoteTime timestamp
			_withdrawalRequest[withdrawalRequestId].latestRelevantApproveVoteTime = block.timestamp;
		}

		return (
			_withdrawalRequest[withdrawalRequestId].voteCount,
			_withdrawalRequest[withdrawalRequestId].latestRelevantApproveVoteTime
		);
	}

	/// @inheritdoc IIglooFiV1Vault
	function processWithdrawalRequest(uint256 withdrawalRequestId)
		public
		override
		onlyRole(VOTER)
		validWithdrawalRequest(withdrawalRequestId)
	{
		// Temporary variable
		WithdrawalRequest memory w = _withdrawalRequest[withdrawalRequestId];
		
		// [require] Required signatures to be met
		require(
			w.voteCount >= requiredVoteCount,
			"Not enough votes"
		);

		// [require] WithdrawalRequest time delay passed
		require(
			block.timestamp - w.latestRelevantApproveVoteTime >= withdrawalDelaySeconds * 1 seconds,
			"Not enough time has passed"
		);

		// Transfer accordingly
		if (w.forERC20 && !w.forERC721)
		{
			if (IERC20(w.token).balanceOf(address(this)) >= w.amount)
			{
				// [ERC20-transfer]
				IERC20(w.token).transfer(w.to, w.amount);
			}
		}
		else if (w.forERC721 && !w.forERC20)
		{
			if (IERC721(w.token).ownerOf(w.tokenId) == address(this))
			{
				// [ERC721-transfer]
				IERC721(w.token).transferFrom(address(this), w.to, w.tokenId);
			}
		}
		else
		{
			// [transfer]
			(bool success, ) = w.to.call{value: w.amount}("");
			
			require(success, "Unable to send value, recipient may have reverted");
		}

		// [call][internal]
		_deleteWithdrawalRequest(withdrawalRequestId);

		// [emit]
		emit TokensWithdrawn(msg.sender, w.to, w.amount);
	}


	/// @inheritdoc IIglooFiV1Vault
	function addVoter(address targetAddress)
		public
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (address)
	{
		// [add] address to VOTER on `AccessControlEnumerable`
		_setupRole(VOTER, targetAddress);

		return targetAddress;
	}

	/// @inheritdoc IIglooFiV1Vault
	function removeVoter(address voter)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (address)
	{
		// [remove] address with VOTER on `AccessControlEnumerable`
		_revokeRole(VOTER, voter);

		return voter;
	}

	/// @inheritdoc IIglooFiV1Vault
	function updateRequiredVoteCount(uint256 newRequiredVoteCount)
		public
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (uint256)
	{
		require(newRequiredVoteCount > 0, "!newRequiredVoteCount");

		// [update]
		requiredVoteCount = newRequiredVoteCount;

		// [emit]
		emit UpdatedRequiredVoteCount(requiredVoteCount);

		return (requiredVoteCount);
	}

	/// @inheritdoc IIglooFiV1Vault
	function updateWithdrawalDelaySeconds(uint256 newWithdrawalDelaySeconds)
		public
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (uint256)
	{
		// [require] newWithdrawalDelaySeconds is greater than OR equal to 0
		require(newWithdrawalDelaySeconds >= 0, "Invalid newWithdrawalDelaySeconds");

		// [update] `withdrawalDelaySeconds`
		withdrawalDelaySeconds = newWithdrawalDelaySeconds;

		// [emit]
		emit UpdatedWithdrawalDelaySeconds(withdrawalDelaySeconds);

		return withdrawalDelaySeconds;
	}

	/// @inheritdoc IIglooFiV1Vault
	function updateWithdrawalRequestLatestRelevantApproveVoteTime(
		uint256 withdrawalRequestId,
		uint256 latestRelevantApproveVoteTime
	)
		public
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
		validWithdrawalRequest(withdrawalRequestId)
		returns (uint256, uint256)
	{
		// [update] WithdrawalRequest within `_withdrawalRequest`
		_withdrawalRequest[
			withdrawalRequestId
		].latestRelevantApproveVoteTime = latestRelevantApproveVoteTime;

		// [emit]
		emit UpdatedWithdrawalRequestLastSignificantApproveVote(
			withdrawalRequestId,
			latestRelevantApproveVoteTime
		);

		return (withdrawalRequestId, latestRelevantApproveVoteTime);
	}

	/// @inheritdoc IIglooFiV1Vault
	function deleteWithdrawalRequest(uint256 withdrawalRequestId)
		public
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
		validWithdrawalRequest(withdrawalRequestId)
		returns (uint256)
	{
		// [call][internal]
		_deleteWithdrawalRequest(withdrawalRequestId);

		return withdrawalRequestId;
	}
}