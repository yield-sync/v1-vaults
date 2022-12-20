// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [import] */
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/* [import] Internal */
import "./interface/IVault.sol";


/**
* @title Vault
*/
contract Vault is
	AccessControl,
	IVault
{
	/* [USING] */
	using SafeERC20 for IERC20;


	/* [state-variable][public][constant] */
	bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE");


	/* [state-variable][public] */
	uint256 public requiredSignatures;

	uint256 public withdrawalDelayMinutes;


	/* [state-variable] */
	uint256 _withdrawalRequestId;

	// ERC20 Contract Address => Balance
	mapping(address => uint256) _tokenBalance;

	// WithdrawalRequest Id => WithdrawalRequest
	mapping(uint256 => WithdrawalRequest) _withdrawalRequest;

	// Creator => Array of WithdrawalRequest
	mapping(address => uint256[]) _withdrawalRequestByCreator;

	// WithdrawalRequest Id => Voted Voter Addresses Array
	mapping(uint256 => address[]) _withdrawalRequestVotedVoters;


	/* [constructor] */
	constructor (
		address admin,
		uint256 requiredSignatures_,
		uint256 withdrawalDelayMinutes_,
		address[] memory voters
	)
	{
		// Initialize WithdrawalRequest Id
		_withdrawalRequestId = 0;

		requiredSignatures = requiredSignatures_;

		// Set delay (in minutes)
		withdrawalDelayMinutes = withdrawalDelayMinutes_;

		// Set up the default admin role
		_setupRole(DEFAULT_ADMIN_ROLE, admin);

		// [for] each voter address..
		for (uint256 i = 0; i < voters.length; i++)
		{
			// Set up the role VOTER_ROLE for the voter address
			_setupRole(VOTER_ROLE, voters[i]);
		}
	}


	/* [recieve] */
	receive ()
		external
		payable
	{
		revert(
			"Sending Ether directly to this contract is disabled, please use `depositTokens` function to send ERC20 tokens into vault"
		);
	}


	/* [fallback] */
	fallback ()
		external
		payable
	{
		revert(
			"Sending Ether directly to this contract is disabled, please use `depositTokens` function to send ERC20 tokens into vault"
		);
	}


	/** [MODIFIER] */
	modifier validWithdrawalRequest(uint256 withdrawalRequestId) {
		// [require] withdrawalRequestId exists
		require(
			_withdrawalRequest[withdrawalRequestId].creator != address(0),
			"No WithdrawalRequest found"
		);
		
		_;
	}


	/**
	* %%%%%%%%%%%%%%%%
	* %%% internal %%%
	* %%%%%%%%%%%%%%%%
	*/

	/**
	* @notice [delete] WithdrawalRequest
	* @param withdrawalRequestId {uint256}
	* @return {bool} Status
	*/
	function _deleteWithdrawalRequest(uint256 withdrawalRequestId)
		internal
		returns (bool)
	{
		// [delete] _withdrawalRequest WithdrawalRequest
		delete _withdrawalRequest[withdrawalRequestId];

		// [delete] _withdrawalRequestVotedVoters value
		delete _withdrawalRequestVotedVoters[withdrawalRequestId];

		// [delete] _withdrawalRequestByCreator
		for (uint256 i = 0; i < _withdrawalRequestByCreator[_withdrawalRequest[withdrawalRequestId].creator].length; i++)
		{
			if (_withdrawalRequestByCreator[_withdrawalRequest[withdrawalRequestId].creator][i] == withdrawalRequestId)
			{
				delete _withdrawalRequestByCreator[_withdrawalRequest[withdrawalRequestId].creator][i];

				break;
			}
		}

		return true;
	}

	/**
	* %%%%%%%%%%%%%%%%%%%%%%
	* %%% NO ROLE NEEDED %%%
	* %%%%%%%%%%%%%%%%%%%%%%
	*/

	/// @inheritdoc IVault
	function tokenBalance(address tokenAddress)
		view
		public
		returns (uint256)
	{
		return _tokenBalance[tokenAddress];
	}

	/// @inheritdoc IVault
	function withdrawalRequest(uint256 withdrawalRequestId)
		view
		public
		returns (WithdrawalRequest memory)
	{
		return _withdrawalRequest[withdrawalRequestId];
	}

	/// @inheritdoc IVault
	function withdrawalRequestVotedVoters(uint256 withdrawalRequestId)
		view
		public
		returns (address[] memory)
	{
		return _withdrawalRequestVotedVoters[withdrawalRequestId];
	}

	/// @inheritdoc IVault
	function withdrawalRequestByCreator(address creator)
		view
		public
		returns (uint256[] memory)
	{
		return _withdrawalRequestByCreator[creator];
	}
	
	/// @inheritdoc IVault
	function depositTokens(address tokenAddress, uint256 amount)
		public
		payable
		returns (bool, uint256, uint256)
	{
		// Ensure token is not a null address
		require(
			tokenAddress != address(0),
			"Token address cannot be null"
		);
		
		// Ensure amount is greater than zero
		require(
			amount > 0,
			"Amount must be greater than zero"
		);

		// Transfer amount from msg.sender to this contract
		IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);

		// Update vault token balance
		_tokenBalance[tokenAddress] += amount;
			
		// [emit]
		emit TokensDeposited(msg.sender, tokenAddress, amount);
		
		return (true, amount, _tokenBalance[tokenAddress]);
	}

	/// @inheritdoc IVault
	function createWithdrawalRequest(
		address to,
		address tokenAddress,
		uint256 amount
	)
		public
		returns (bool, WithdrawalRequest memory)
	{
		// [require]  The specified amount is available
		require(_tokenBalance[tokenAddress] >= amount, "Insufficient funds");

		// [require] 'to' is a valid Ethereum address
		require(to != address(0), "Invalid 'to' address");

		// Create a new WithdrawalRequest
		_withdrawalRequestId++;

		_withdrawalRequest[_withdrawalRequestId] = WithdrawalRequest({
			creator: msg.sender,
			to: to,
			token: tokenAddress,
			paused: false,
			accelerated: false,
			amount: amount,
			forVoteCount: 0,
			againstVoteCount: 0,
			lastImpactfulVote: block.timestamp
		});

		_withdrawalRequestByCreator[msg.sender].push(_withdrawalRequestId);

		return (true, _withdrawalRequest[_withdrawalRequestId]);
	}

	/// @inheritdoc IVault
	function processWithdrawalRequests(uint256 withdrawalRequestId)
		public
		validWithdrawalRequest(withdrawalRequestId)
		returns (bool, string memory)
	{
		// Get the current time
		uint256 currentTime = block.timestamp;

		// Create temporary variable
		WithdrawalRequest memory wr = _withdrawalRequest[withdrawalRequestId];

		// If the withdrawal request has reached the required number of signatures
		if (
			wr.forVoteCount >= requiredSignatures &&
			(
				currentTime - wr.lastImpactfulVote >= SafeMath.mul(withdrawalDelayMinutes, 60) ||
				wr.accelerated
			) &&
			!wr.paused
		)
		{
			// Transfer the specified amount of tokens to the recipient
			IERC20(wr.token).safeTransfer(wr.to, wr.amount);

			// [decrement] The vault token balance
			_tokenBalance[wr.token] -= wr.amount;

			// [emit]
			emit TokensDeposited(msg.sender, wr.to, wr.amount);

			// [call]
			_deleteWithdrawalRequest(withdrawalRequestId);
		
			return (true, "Processed WithdrawalRequest");
		}
		
		return (false, "Unable to process WithdrawalRequest");
	}


	/** 
	* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	* %%% Auth Level: VOTER_ROLE %%%
	* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	*/

	/// @inheritdoc IVault
	function voteOnWithdrawalRequest(uint256 withdrawalRequestId, bool vote)
		public
		onlyRole(VOTER_ROLE)
		validWithdrawalRequest(withdrawalRequestId)
		returns (bool, bool, uint256, uint256, uint256)
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
			}
		}

		// [require] It is msg.sender's (voter's) first vote
		require(!voted, "You have already casted a vote for this WithdrawalRequest");

		if (vote)
		{
			// [increment] For count
			_withdrawalRequest[withdrawalRequestId].forVoteCount++;
		}
		else
		{
			// [increment] Against count
			_withdrawalRequest[withdrawalRequestId].againstVoteCount++;
		}

		// [update] Mark msg.sender (voter) has voted
		_withdrawalRequestVotedVoters[withdrawalRequestId].push(msg.sender);

		// If the required signatures has not yet been reached..
		if (_withdrawalRequest[withdrawalRequestId].forVoteCount < requiredSignatures)
		{
			// [update] lastImpactfulVote timestamp
			_withdrawalRequest[withdrawalRequestId].lastImpactfulVote = block.timestamp;
		}

		return (
			true,
			vote,
			_withdrawalRequest[withdrawalRequestId].forVoteCount,
			_withdrawalRequest[withdrawalRequestId].againstVoteCount,
			_withdrawalRequest[withdrawalRequestId].lastImpactfulVote
		);
	}


	/**
	* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	* %%% Auth Level: DEFAULT_ADMIN_ROLE %%%
	* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	*/

	/// @inheritdoc IVault
	function updateRequiredSignatures(uint256 newRequiredSignatures)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (bool, uint256)
	{
		// [update]
		requiredSignatures = newRequiredSignatures;

		return (true, requiredSignatures);
	}

	/// @inheritdoc IVault
	function addVoter(address voter)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (bool, address)
	{
		// Add the voter to the VOTER_ROLE
		_setupRole(VOTER_ROLE, voter);

		return (true, voter);
	}

	/// @inheritdoc IVault
	function removeVoter(address voter)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (bool, address)
	{
		_revokeRole(VOTER_ROLE, voter);

		return (true, voter);
	}

	/// @inheritdoc IVault
	function updateWithdrawalDelayMinutes(uint256 newWithdrawalDelayMinutes)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (bool, uint256)
	{
		// [require] newWithdrawalDelayMinutes is greater than 0
		require(newWithdrawalDelayMinutes >= 0, "Invalid newWithdrawalDelayMinutes");

		// Set delay (in minutes)
		withdrawalDelayMinutes = newWithdrawalDelayMinutes;

		return (true, withdrawalDelayMinutes);
	}

	/// @inheritdoc IVault
	function toggleWithdrawalRequestPause(uint256 withdrawalRequestId)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		validWithdrawalRequest(withdrawalRequestId)
		returns (bool, WithdrawalRequest memory)
	{
		_withdrawalRequest[withdrawalRequestId].paused = !_withdrawalRequest[
			withdrawalRequestId
		].paused;

		return (true, _withdrawalRequest[withdrawalRequestId]);
	}

	/// @inheritdoc IVault
	function deleteWithdrawalRequest(uint256 withdrawalRequestId)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		validWithdrawalRequest(withdrawalRequestId)
		returns (bool)
	{
		// [call]
		_deleteWithdrawalRequest(withdrawalRequestId);

		return true;
	}
}