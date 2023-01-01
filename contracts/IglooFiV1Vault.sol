// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [import] */
// [!local]
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
// [local]
import "./interface/IIglooFiV1Vault.sol";


/**
* @title Igloo Fi V1 Vault
*/
contract IglooFiV1Vault is
	AccessControlEnumerable,
	IERC1271,
	IIglooFiV1Vault
{
	/* [using] */
	using Address for address payable;
	using ECDSA for bytes32;
	using SafeERC20 for IERC20;


	/* [state-variable] */
	// [bytes4][public]
	bytes4 public constant INVALID_SIGNATURE = 0xffffffff;
	bytes4 public constant MAGICVALUE = 0x1626ba7e;

	// [byte32][public]
	bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE");

	// [uint256][internal]
	uint256 internal _withdrawalRequestId;

	// [uint256][public]
	uint256 public requiredApproveVotes;
	uint256 public withdrawalDelayMinutes;

	// [mapping][internal]
	// Voter Address => Array of WithdrawalRequest
	mapping (address => uint256[]) internal _withdrawalRequestByCreator;
	// WithdrawalRequestId => WithdrawalRequest
	mapping (uint256 => WithdrawalRequest) internal _withdrawalRequest;
	// WithdrawalRequestId => Voted Voter Addresses Array
	mapping (uint256 => address[]) internal _withdrawalRequestVotedVoters;
	// Message => votes
	mapping(bytes32 => uint256) internal _messageSignatures;


	/* [constructor] */
	constructor (
		address admin,
		uint256 _requiredApproveVotes,
		uint256 _withdrawalDelayMinutes,
		address[] memory voters
	)
	{
		// Initialize WithdrawalRequestId
		_withdrawalRequestId = 0;

		// Set DEFAULT_ADMIN_ROLE
		_setupRole(DEFAULT_ADMIN_ROLE, admin);

		requiredApproveVotes = _requiredApproveVotes;
		withdrawalDelayMinutes = _withdrawalDelayMinutes;

		// [for] each voter address..
		for (uint256 i = 0; i < voters.length; i++)
		{
			// [add] Voter to `AccessControl._roles` as VOTER_ROLE
			_setupRole(VOTER_ROLE, voters[i]);
		}
	}


	/* [recieve] */
	receive ()
		external
		payable
	{
		emit EtherRecieved(msg.value);
	}


	/* [fallback] */
	fallback ()
		external
		payable
	{}


	/* [modifier] */
	modifier validWithdrawalRequest(uint256 withdrawalRequestId) {
		// [require] withdrawalRequestId exists
		require(
			_withdrawalRequest[withdrawalRequestId].creator != address(0),
			"No WithdrawalRequest found"
		);
		
		_;
	}


	/* [function] */
	/**
	* @notice Delete WithdrawalRequest
	*
	* @dev [restriction][internal]
	*
	* @dev [delete] `_withdrawalRequest` value
	*      [delete] `_withdrawalRequestVotedVoters` value
	*      [delete] `_withdrawalRequestByCreator` value
	*
	* @param withdrawalRequestId {uint256}
	*
	* Emits: `DeletedWithdrawalRequest`
	*/
	function _deleteWithdrawalRequest(uint256 withdrawalRequestId)
		internal
	{
		// [delete] `_withdrawalRequest` value
		delete _withdrawalRequest[withdrawalRequestId];

		// [delete] `_withdrawalRequestVotedVoters` value
		delete _withdrawalRequestVotedVoters[withdrawalRequestId];

		for (uint256 i = 0; i < _withdrawalRequestByCreator[_withdrawalRequest[withdrawalRequestId].creator].length; i++)
		{
			// If match found..
			if (
				_withdrawalRequestByCreator[
					_withdrawalRequest[withdrawalRequestId].creator
				][i] == withdrawalRequestId
			)
			{
				// [delete] `_withdrawalRequestByCreator` value
				delete _withdrawalRequestByCreator[
					_withdrawalRequest[withdrawalRequestId].creator
				][i];

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
			hasRole(VOTER_ROLE, signer) &&
			_messageSignatures[_messageHash] >= requiredApproveVotes
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
	function withdrawalRequestByCreator(address creator)
		view
		public
		returns (uint256[] memory)
	{
		return _withdrawalRequestByCreator[creator];
	}

	/// @inheritdoc IIglooFiV1Vault
	function withdrawalRequest(uint256 withdrawalRequestId)
		view
		public
		returns (WithdrawalRequest memory)
	{
		return _withdrawalRequest[withdrawalRequestId];
	}

	/// @inheritdoc IIglooFiV1Vault
	function withdrawalRequestVotedVoters(uint256 withdrawalRequestId)
		view
		public
		returns (address[] memory)
	{
		return _withdrawalRequestVotedVoters[withdrawalRequestId];
	}

	/// @inheritdoc IIglooFiV1Vault
	function messageSignatures(bytes32 message)
		view
		public
		returns (uint256)
	{
		return _messageSignatures[message];
	}

	/// @inheritdoc IIglooFiV1Vault
	function sign(bytes32 _messageHash, bytes memory _signature)
		public
	{
		address signer = _messageHash.recover(_signature);

		if (hasRole(VOTER_ROLE, signer))
		{
			// [increment] Value in `_messageSignatures`
			_messageSignatures[_messageHash]++;
		}
	}
	

	/// @inheritdoc IIglooFiV1Vault
	function createWithdrawalRequest(
		bool requestETH,
		address to,
		address tokenAddress,
		uint256 amount,
		uint256 tokenId
	)
		public
		onlyRole(VOTER_ROLE)
		returns (uint256)
	{
		// [require] 'to' is a valid Ethereum address
		require(to != address(0), "Invalid `to` address");

		// [increment] `_withdrawalRequestId`
		_withdrawalRequestId++;

		// [add] `_withdrawalRequest` value
		_withdrawalRequest[_withdrawalRequestId] = WithdrawalRequest({
			requestETH: requestETH,
			creator: msg.sender,
			to: to,
			token: tokenAddress,
			amount: amount,
			tokenId: tokenId,
			approveVoteCount: 0,
			denyVoteCount: 0,
			latestRelevantApproveVoteTime: block.timestamp
		});

		// [push-into] `_withdrawalRequestByCreator`
		_withdrawalRequestByCreator[msg.sender].push(_withdrawalRequestId);

		// [emit]
		emit CreatedWithdrawalRequest(_withdrawalRequest[_withdrawalRequestId]);
		
		return _withdrawalRequestId;
	}

	/// @inheritdoc IIglooFiV1Vault
	function voteOnWithdrawalRequest(uint256 withdrawalRequestId, bool vote)
		public
		onlyRole(VOTER_ROLE)
		validWithdrawalRequest(withdrawalRequestId)
		returns (bool, uint256, uint256, uint256)
	{
		// [init]
		bool voted = false;

		// [for] each voter within WithdrawalRequest
		for (uint256 i = 0; i < _withdrawalRequestVotedVoters[withdrawalRequestId].length; i++)
		{
			if (_withdrawalRequestVotedVoters[withdrawalRequestId][i] == msg.sender)
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
			_withdrawalRequest[withdrawalRequestId].approveVoteCount++;

			// If required signatures met..
			if (_withdrawalRequest[withdrawalRequestId].approveVoteCount >= requiredApproveVotes)
			{
				// [emit]
				emit WithdrawalRequestReadyToBeProccessed(withdrawalRequestId);
			}
		}
		else
		{
			// [update] `_withdrawalRequest` → [increment] Deny vote count
			_withdrawalRequest[withdrawalRequestId].denyVoteCount++;
		}

		// [emit]
		emit VoterVoted(withdrawalRequestId, msg.sender, vote);

		// [update] `_withdrawalRequestVotedVoters` → Mark voter has voted
		_withdrawalRequestVotedVoters[withdrawalRequestId].push(msg.sender);

		// If the required signatures has not yet been reached..
		if (_withdrawalRequest[withdrawalRequestId].approveVoteCount < requiredApproveVotes)
		{
			// [update] latestRelevantApproveVoteTime timestamp
			_withdrawalRequest[withdrawalRequestId].latestRelevantApproveVoteTime = block.timestamp;
		}

		return (
			vote,
			_withdrawalRequest[withdrawalRequestId].approveVoteCount,
			_withdrawalRequest[withdrawalRequestId].denyVoteCount,
			_withdrawalRequest[withdrawalRequestId].latestRelevantApproveVoteTime
		);
	}

	/// @inheritdoc IIglooFiV1Vault
	function processWithdrawalRequests(uint256 withdrawalRequestId)
		public
		onlyRole(VOTER_ROLE)
		validWithdrawalRequest(withdrawalRequestId)
	{
		// Temporary variable
		WithdrawalRequest memory w = _withdrawalRequest[withdrawalRequestId];
		
		// [require] Required signatures to be met
		require(
			w.approveVoteCount >= requiredApproveVotes,
			"Not enough for votes"
		);

		// [require] WithdrawalRequest time delay passed
		require(
			block.timestamp - w.latestRelevantApproveVoteTime >= SafeMath.mul(withdrawalDelayMinutes, 60),
			"Not enough time has passed"
		);

		// If WithdrawalRequest is for Ether, erc20, or erc721 and transfer accordingly
		if (w.requestETH)
		{
			// [transfer]
			w.to.sendValue(w.amount);
		}
		else if (IERC165(w.token).supportsInterface(type(IERC20).interfaceId))
		{
			if (IERC20(w.token).balanceOf(address(this)) >= w.amount)
			{
				// [erc20-transfer]
				IERC20(w.token).safeTransfer(w.to, w.amount);
			}
		}
		else if (IERC165(w.token).supportsInterface(type(IERC721).interfaceId))
		{
			if (IERC721(w.token).ownerOf(address(this)) >= w.amount)
			{
				// [erc721-transfer]
				IERC721(w.token).safeTransferFrom(address(this), w.to, w.tokenId);
			}
		}

		// [call][internal]
		_deleteWithdrawalRequest(withdrawalRequestId);

		// [emit]
		emit TokensWithdrawn(msg.sender, w.to, w.amount);
	}
	

	/// @inheritdoc IIglooFiV1Vault
	function addVoter(address targetAddress)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (address)
	{
		// [add] address to VOTER_ROLE on `AccessControlEnumerable`
		_setupRole(VOTER_ROLE, targetAddress);

		// [emit]
		emit VoterAdded(targetAddress);

		return targetAddress;
	}

	/// @inheritdoc IIglooFiV1Vault
	function removeVoter(address voter)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (address)
	{
		// [remove] address with VOTER_ROLE on `AccessControlEnumerable`
		_revokeRole(VOTER_ROLE, voter);

		// [emit]
		emit VoterRemoved(voter);

		return voter;
	}

	/// @inheritdoc IIglooFiV1Vault
	function updateRequiredApproveVotes(uint256 newRequiredApproveVotes)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (uint256)
	{
		// [update]
		requiredApproveVotes = newRequiredApproveVotes;

		// [emit]
		emit UpdatedRequiredApproveVotes(requiredApproveVotes);

		return (requiredApproveVotes);
	}

	/// @inheritdoc IIglooFiV1Vault
	function updateWithdrawalDelayMinutes(uint256 newWithdrawalDelayMinutes)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (uint256)
	{
		// [require] newWithdrawalDelayMinutes is greater than OR equal to 0
		require(newWithdrawalDelayMinutes >= 0, "Invalid newWithdrawalDelayMinutes");

		// [update] `withdrawalDelayMinutes`
		withdrawalDelayMinutes = newWithdrawalDelayMinutes;

		// [emit]
		emit UpdatedWithdrawalDelayMinutes(withdrawalDelayMinutes);

		return withdrawalDelayMinutes;
	}

	/// @inheritdoc IIglooFiV1Vault
	function updateWithdrawalRequestLatestRelevantApproveVoteTime(
		uint256 withdrawalRequestId,
		uint256 latestRelevantApproveVoteTime
	)
		public
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
		onlyRole(DEFAULT_ADMIN_ROLE)
		validWithdrawalRequest(withdrawalRequestId)
		returns (uint256)
	{
		// [call][internal]
		_deleteWithdrawalRequest(withdrawalRequestId);

		return withdrawalRequestId;
	}
}