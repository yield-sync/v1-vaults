// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { IIglooFiV1Vault, WithdrawalRequest } from "./interface/IIglooFiV1Vault.sol";


/**
* @title IglooFiV1Vault
*/
contract IglooFiV1Vault is
	AccessControlEnumerable,
	IERC1271,
	IIglooFiV1Vault
{
	// [bytes4][public]
	address public override signatureManager;

	// [byte32][public]
	bytes32 public constant override VOTER = keccak256("VOTER");

	// [uint256][internal]
	uint256 internal _withdrawalRequestIdTracker;
	uint256[] internal _openWithdrawalRequestIds;

	// [uint256][public]
	uint256 public override requiredVoteCount;
	uint256 public override withdrawalDelaySeconds;

	// [mapping][internal]
	// withdrawalRequestId => withdralRequest
	mapping (uint256 => WithdrawalRequest) internal _withdrawalRequest;


	constructor (
		address admin,
		address _signatureManager,
		uint256 _requiredVoteCount,
		uint256 _withdrawalDelaySeconds
	)
	{
		require(_requiredVoteCount > 0, "!_requiredVoteCount");
		
		_setupRole(DEFAULT_ADMIN_ROLE, admin);

		signatureManager = _signatureManager;
		requiredVoteCount = _requiredVoteCount;
		withdrawalDelaySeconds = _withdrawalDelaySeconds;
		
		_withdrawalRequestIdTracker = 0;
	}


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


	modifier validWithdrawalRequest(uint256 withdrawalRequestId)
	{
		// [require] WithdrawalRequest exists
		require(_withdrawalRequest[withdrawalRequestId].creator != address(0), "No WithdrawalRequest found");
		
		_;
	}


	/**
	* @notice Delete WithdrawalRequest
	* @dev [restriction][internal]
	* @dev [delete] `_withdrawalRequest` value
	*      [delete] `_openWithdrawalRequestIds` value
	* @param withdrawalRequestId {uint256}
	* Emits: `DeletedWithdrawalRequest`
	*/
	function _deleteWithdrawalRequest(uint256 withdrawalRequestId)
		internal
	{
		// [delete] `_withdrawalRequest` value
		delete _withdrawalRequest[withdrawalRequestId];

		for (uint256 i = 0; i < _openWithdrawalRequestIds.length; i++)
		{
			if (_openWithdrawalRequestIds[i] == withdrawalRequestId)
			{
				// [delete] `_openWithdrawalRequestIds` value
				_openWithdrawalRequestIds[i] = _openWithdrawalRequestIds[_openWithdrawalRequestIds.length - 1];
				_openWithdrawalRequestIds.pop();

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


	/// @inheritdoc IIglooFiV1Vault
	function openWithdrawalRequestIds()
		public
		view
		override
		returns (uint256[] memory)
	{
		return _openWithdrawalRequestIds;
	}

	/// @inheritdoc IIglooFiV1Vault
	function withdrawalRequest(uint256 withdrawalRequestId)
		public
		view
		override
		returns (WithdrawalRequest memory)
	{
		return _withdrawalRequest[withdrawalRequestId];
	}


	/// @inheritdoc IIglooFiV1Vault
	function createWithdrawalRequest(
		bool forEther,
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
	{
		require(amount > 0, "!amount");

		address[] memory initialVotedVoters;

		// [add] `_withdrawalRequest` value
		_withdrawalRequest[_withdrawalRequestIdTracker] = WithdrawalRequest(
			{
				forEther: forEther,
				forERC20: forERC20,
				forERC721: forERC721,
				creator: _msgSender(),
				to: to,
				token: tokenAddress,
				amount: amount,
				tokenId: tokenId,
				voteCount: 0,
				latestRelevantApproveVoteTime: block.timestamp,
				votedVoters: initialVotedVoters
			}
		);

		// [push-into] `_openWithdrawalRequestIds`
		_openWithdrawalRequestIds.push(_withdrawalRequestIdTracker);

		// [increment] `_withdrawalRequestIdTracker`
		_withdrawalRequestIdTracker++;

		// [emit]
		emit CreatedWithdrawalRequest(_withdrawalRequestIdTracker - 1);
	}

	/// @inheritdoc IIglooFiV1Vault
	function voteOnWithdrawalRequest(uint256 withdrawalRequestId, bool vote)
		public
		override
		onlyRole(VOTER)
		validWithdrawalRequest(withdrawalRequestId)
	{
		// [for] each voter within WithdrawalRequest
		for (uint256 i = 0; i < _withdrawalRequest[withdrawalRequestId].votedVoters.length; i++)
		{
			require(_withdrawalRequest[withdrawalRequestId].votedVoters[i] != _msgSender(), "Already voted");
		}
		
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
		emit VoterVoted(withdrawalRequestId, _msgSender(), vote);

		// [update] `_withdrawalRequest[withdrawalRequestId].votedVoters` → Add _msgSender()
		_withdrawalRequest[withdrawalRequestId].votedVoters.push(_msgSender());

		if (_withdrawalRequest[withdrawalRequestId].voteCount < requiredVoteCount)
		{
			// [update] latestRelevantApproveVoteTime timestamp
			_withdrawalRequest[withdrawalRequestId].latestRelevantApproveVoteTime = block.timestamp;
		}
	}

	/// @inheritdoc IIglooFiV1Vault
	function processWithdrawalRequest(uint256 withdrawalRequestId)
		public
		override
		onlyRole(VOTER)
		validWithdrawalRequest(withdrawalRequestId)
	{
		// Temporary variable
		WithdrawalRequest memory wR = _withdrawalRequest[withdrawalRequestId];
		
		// [require] Required signatures to be met
		require(wR.voteCount >= requiredVoteCount, "Not enough votes");

		// [require] WithdrawalRequest time delay passed
		require(
			block.timestamp - wR.latestRelevantApproveVoteTime >= withdrawalDelaySeconds * 1 seconds,
			"Not enough time has passed"
		);

		// Transfer accordingly
		if (wR.forERC20 && !wR.forERC721)
		{
			if (IERC20(wR.token).balanceOf(address(this)) >= wR.amount)
			{
				// [ERC20-transfer]
				IERC20(wR.token).transfer(wR.to, wR.amount);
			}
		}
		else if (wR.forERC721 && !wR.forERC20)
		{
			if (IERC721(wR.token).ownerOf(wR.tokenId) == address(this))
			{
				// [ERC721-transfer]
				IERC721(wR.token).transferFrom(address(this), wR.to, wR.tokenId);
			}
		}
		else if (wR.forEther)
		{
			// [transfer]
			(bool success, ) = wR.to.call{value: wR.amount}("");
			
			require(success, "Unable to send value");
		}

		// [call][internal]
		_deleteWithdrawalRequest(withdrawalRequestId);

		// [emit]
		emit TokensWithdrawn(_msgSender(), wR.to, wR.amount);
	}


	/// @inheritdoc IIglooFiV1Vault
	function addVoter(address targetAddress)
		public
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		// [add] address to VOTER on `AccessControlEnumerable`
		_setupRole(VOTER, targetAddress);
	}

	/// @inheritdoc IIglooFiV1Vault
	function removeVoter(address voter)
		public
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		// [remove] address with VOTER on `AccessControlEnumerable`
		_revokeRole(VOTER, voter);
	}

		/// @inheritdoc IIglooFiV1Vault
	function updateSignatureManager(address _signatureManager)
		public
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		signatureManager = _signatureManager;
	}

	/// @inheritdoc IIglooFiV1Vault
	function updateRequiredVoteCount(uint256 _requiredVoteCount)
		public
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(_requiredVoteCount > 0, "!_requiredVoteCount");

		// [update]
		requiredVoteCount = _requiredVoteCount;

		// [emit]
		emit UpdatedRequiredVoteCount(requiredVoteCount);
	}

	/// @inheritdoc IIglooFiV1Vault
	function updateWithdrawalDelaySeconds(uint256 _withdrawalDelaySeconds)
		public
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(_withdrawalDelaySeconds >= 0, "!_withdrawalDelaySeconds");

		// [update] `withdrawalDelaySeconds`
		withdrawalDelaySeconds = _withdrawalDelaySeconds;

		// [emit]
		emit UpdatedWithdrawalDelaySeconds(withdrawalDelaySeconds);
	}

	/// @inheritdoc IIglooFiV1Vault
	function updateWithdrawalRequest(uint256 withdrawalRequestId, WithdrawalRequest memory __withdrawalRequest)
		public
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
		validWithdrawalRequest(withdrawalRequestId)
	{
		// [update] `_withdrawalRequest`
		_withdrawalRequest[withdrawalRequestId] = __withdrawalRequest;

		if (_withdrawalRequest[withdrawalRequestId].voteCount < requiredVoteCount)
		{
			// [update] `withdrawalRequest.latestRelevantApproveVoteTime`
			_withdrawalRequest[withdrawalRequestId].latestRelevantApproveVoteTime = block.timestamp;
		}

		emit UpdatedWithdrawalRequest(__withdrawalRequest);
	}

	/// @inheritdoc IIglooFiV1Vault
	function deleteWithdrawalRequest(uint256 withdrawalRequestId)
		public
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
		validWithdrawalRequest(withdrawalRequestId)
	{
		// [call][internal]
		_deleteWithdrawalRequest(withdrawalRequestId);

		emit DeletedWithdrawalRequest(withdrawalRequestId);
	}
}