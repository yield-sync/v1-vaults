// contracts/Vault.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [IMPORT] */
// /access
import "@openzeppelin/contracts/access/AccessControl.sol";
// /token
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// /utils
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


/**
 * @title Vault
 * @notice This is a vault for storing ERC20 tokens.
*/
contract Vault is AccessControl {
	/* [EVENT] */
	event TokensDeposited (
		address indexed depositor,
		address indexed token,
		uint256 amount
	);


	event TokensWithdrawn (
		address indexed withdrawer,
		address indexed token,
		uint256 amount
	);


	/* [USING] */
	using SafeERC20 for IERC20;


	/* [STRUCT] */
	struct WithdrawalRequest {
		address creator;
		address to;
		address token;

		bool paused;
		bool accelerated;

		uint256 amount;
		uint256 forVoteCount;
		uint256 againstVoteCount;

		uint256 lastImpactfulVote;
	}


	/* [STATE-VARIABLE][CONSTANT] */
	bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE");

	/* [STATE-VARIABLE] */
	uint256 public requiredSignatures;

	uint256 public withdrawalDelayMinutes;

	uint256 _withdrawalRequestId;

	// ERC20 Contract Address => Balance
	mapping (address => uint256) _tokenBalance;

	// WithdrawalRequest Id => WithdrawalRequest
	mapping (uint256 => WithdrawalRequest) _withdrawalRequest;

	// WithdrawalRequest Id => Voted Voter Addresses)
	mapping (uint256 => address[]) public _withdrawalRequestVotedVoters;

	// Creator => Array of WithdrawalRequest
	mapping (address => uint256[]) _withdrawalRequestByCreator;


	/* [MODIFIER] */
	modifier validWithdrawalRequest(uint256 withdrawalRequestId) {
		// [REQUIRE] withdrawalRequestId exists
		require(
			_withdrawalRequest[withdrawalRequestId].creator != address(0),
			"No WithdrawalRequest found"
		);
		
		_;
	}


	/** [CONSTRUCTOR] */
	
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

		// Set up the voter role and add the admin as the first voter
		_setupRole(VOTER_ROLE, admin);

		// For each voter address..
		for (uint256 i = 0; i < voters.length; i++)
		{
			// Set up the role VOTER_ROLE for the voter address
			_setupRole(VOTER_ROLE, voters[i]);
		}
	}


	/** [RECIEVE] */
	receive ()
		external
		payable
	{
		revert(
			"Sending Ether directly to this contract is disabled, please use `depositTokens` function to send ERC20 tokens into vault"
		);
	}


	/** [FALLBACK] */
	fallback ()
		external
		payable
	{
		revert(
			"Sending Ether directly to this contract is disabled, please use `depositTokens` function to send ERC20 tokens into vault"
		);
	}


	/**
	 * %%%%%%%%%%%%%%%%%
	 * %%% 	INTERNAL %%%
	 * %%%%%%%%%%%%%%%%%
	*/

	/**
	 * @notice [DELETE] WithdrawalRequest
	 * @param withdrawalRequestId {uint256} Id of the WithdrawalRequest
	 * @return {bool} Status
	*/
	function _deleteWithdrawalRequest(uint256 withdrawalRequestId)
		internal
		returns (bool)
	{
		// [DELETE] _withdrawalRequest WithdrawalRequest
		delete _withdrawalRequest[withdrawalRequestId];

		// [DELETE] _withdrawalRequestVotedVoters value
		delete _withdrawalRequestVotedVoters[withdrawalRequestId];

		// [DELETE] _withdrawalRequestByCreator
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

	/**
	 * @notice [GETTER] _tokenBalance
	 * @param tokenAddress {address} Token address
	 * @return {uint256} Token balance
	*/
	function tokenBalance(address tokenAddress)
		public
		view
		returns (uint256)
	{
		// Return token balance
		return _tokenBalance[tokenAddress];
	}

	/**
	 * @notice [GETTER] _withdrawalRequest
	 * @param withdrawalRequestId {uint256} Id of the WithdrawalRequest
	 * @return {WithdrawalRequest} WithdrawalRequest
	*/
	function withdrawalRequest(uint256 withdrawalRequestId)
		public
		view
		validWithdrawalRequest(withdrawalRequestId)
		returns (WithdrawalRequest memory)
	{
		// Create temporary variable
		WithdrawalRequest memory wr = _withdrawalRequest[withdrawalRequestId];
		
		return wr;
	}

	/**
	 * @notice all WithdrawalRequests by a provided Creator
	 * @param creator {uint256} Address to query WithdrawalRequests for
	 * @return {WithdrawalRequest[]} Array of WithdrawalRequests
	*/
	function WithdrawalRequestsByCreator(address creator)
		public
		view
		returns (bool, WithdrawalRequest[] memory)
	{
		// Get array of WithdrawalRequest Ids for the provided creator
		uint256[] memory withdrawalRequestIds = _withdrawalRequestByCreator[creator];

		// Create array of WithdrawalRequests
		WithdrawalRequest[] memory wr = new WithdrawalRequest[](
			withdrawalRequestIds.length
		);

		// For each withdrawalRequestId..
		for (uint256 i = 0; i < withdrawalRequestIds.length; i++) {
			// Store into array
			wr[i] = _withdrawalRequest[withdrawalRequestIds[i]];
		}

		return (true, wr);
	}
	
	/**
	 * @notice Deposit funds
	 * @param tokenAddress {address} Address of token contract
	 * @param amount {uint256} Amount to be moved
	 * @return {bool} Status
	 * @return {uint256} Amount deposited
	 * @return {uint256} New ERC20 token balance
	*/
	function depositTokens(
		address tokenAddress,
		uint256 amount
	)
		public payable
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
			
		// [EMIT]
		emit TokensDeposited(msg.sender, tokenAddress, amount);
		
		return (true, amount, _tokenBalance[tokenAddress]);
	}

	/**
	 * @notice [CREATE] WithdrawalRequest
	 * @param to {address} Address the withdrawal it to be sent
	 * @param tokenAddress {address} Address of token contract
	 * @param amount {uint256} Amount to be moved
	 * @return {bool} Status
	 * @return {WithdrawalRequest} Created WithdrawalRequest
	*/
	function createWithdrawalRequest(
		address to,
		address tokenAddress,
		uint256 amount
	)
		public
		returns (bool, WithdrawalRequest memory)
	{
		// [REQUIRE]  The specified amount is available
		require(_tokenBalance[tokenAddress] >= amount, "Insufficient funds");

		// [REQUIRE] 'to' is a valid Ethereum address
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

	/**
	 * @notice Proccess the WithdrawalRequest
	 * @param withdrawalRequestId {uint256} Id of the WithdrawalRequest
	 * @return {bool} Status
	 * @return {string} Message
	*/
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

			// [DECREMENT] The vault token balance
			_tokenBalance[wr.token] -= wr.amount;

			// [EMIT]
			emit TokensDeposited(msg.sender, wr.to, wr.amount);

			// [CALL]
			_deleteWithdrawalRequest(withdrawalRequestId);
		
			return (true, "Processed WithdrawalRequest");
		}
		
		return (false, "Unable to process WithdrawalRequest");
	}


	/**
	 * %%%%%%%%%%%%%%%%%%%%%%%%
	 * %%% ROLE: VOTER_ROLE %%%
	 * %%%%%%%%%%%%%%%%%%%%%%%%
	*/

	/**
	 * @notice Vote to approve or disapprove withdrawal request
	 * @param withdrawalRequestId {uint256} Id of the WithdrawalRequest
	 * @param vote {bool} For or against vote
	 * @return {bool} Status
	 * @return {bool} Vote received
	 * @return {bool} forVoteCount
	 * @return {bool} againstVoteCount
	 * @return {bool} lastImpactfulVote
	*/
	function voteOnWithdrawalRequest(
		uint256 withdrawalRequestId,
		bool vote
	)
		public
		onlyRole(VOTER_ROLE)
		validWithdrawalRequest(withdrawalRequestId)
		returns (bool, bool, uint256, uint256, uint256)
	{
		// [INIT]
		bool voted = false;

		// For each voter within WithdrawalRequest
		for (uint256 i = 0; i < _withdrawalRequestVotedVoters[withdrawalRequestId].length; i++)
		{
			if (_withdrawalRequestVotedVoters[withdrawalRequestId][i] == msg.sender)
			{
				// Flag
				voted = true;
			}
		}

		// [REQUIRE] It is msg.sender's (voter's) first vote
		require(!voted, "You have already casted a vote for this WithdrawalRequest");

		if (vote)
		{
			// [INCREMENT] For count
			_withdrawalRequest[withdrawalRequestId].forVoteCount++;
		}
		else
		{
			// [INCREMENT] Against count
			_withdrawalRequest[withdrawalRequestId].againstVoteCount++;
		}

		// [ADD] Mark msg.sender (voter) has voted
		_withdrawalRequestVotedVoters[withdrawalRequestId].push(msg.sender);

		// If the required signatures has not yet been reached..
		if (_withdrawalRequest[withdrawalRequestId].forVoteCount < requiredSignatures)
		{
			// [UPDATE] lastImpactfulVote timestamp
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
	 * %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	 * %%% ROLE: DEFAULT_ADMIN_ROLE %%%
	 * %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	*/

	/**
	 * @notice Update `requiredSignatures`
	 * @param newRequiredSignatures {uint256} New requiredSignatures
	 * @return {bool} Status
	 * @return {uint256} New requiredSignatures
	*/
	function updateRequiredSignatures(uint256 newRequiredSignatures)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (bool, uint256)
	{
		// [UPDATE]
		requiredSignatures = newRequiredSignatures;

		return (true, requiredSignatures);
	}

	/**
	 * @notice Add a voter
	 * @param voter {address} Address of the voter to add
	 * @return {bool} Status
	 * @return {address} Voter added
	*/
	function addVoter(address voter)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (bool, address)
	{
		// Add the voter to the VOTER_ROLE
		_setupRole(VOTER_ROLE, voter);

		return (true, voter);
	}

	/**
	 * @notice Remove a voter
	 * @param voter {address} Address of the voter to remove
	 * @return {bool} Status
	 * @return {address} Voter removed
	*/
	function removeVoter(address voter)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (bool, address)
	{
		_revokeRole(VOTER_ROLE, voter);

		return (true, voter);
	}

	/**
	 * @notice Update `withdrawalDelayMinutes`
	 * @param newWithdrawalDelayMinutes {uint256} New withdrawalDelayMinutes
	 * @return {bool} Status
	 * @return {uint256} New withdrawalDelayMinutes
	*/
	function updateWithdrawalDelayMinutes(uint256 newWithdrawalDelayMinutes)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (bool, uint256)
	{
		// [REQUIRE] newWithdrawalDelayMinutes is greater than 0
		require(newWithdrawalDelayMinutes >= 0, "Invalid newWithdrawalDelayMinutes");

		// Set delay (in minutes)
		withdrawalDelayMinutes = newWithdrawalDelayMinutes;

		return (true, withdrawalDelayMinutes);
	}

	/**
	 * @notice Toggle `pause` on a WithdrawalRequest
	 * @param withdrawalRequestId {uint256} Id of the WithdrawalRequest
	 * @return {bool} Status
	 * @return {WithdrawalRequest} Updated WithdrawalRequest
	*/
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

	/**
	 * @notice Toggle `pause` on a WithdrawalRequest
	 * @param withdrawalRequestId {uint256} Id of the WithdrawalRequest
	 * @return {bool} Status
	*/
	function deleteWithdrawalRequest(uint256 withdrawalRequestId)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		validWithdrawalRequest(withdrawalRequestId)
		returns (bool)
	{
		// [CALL]
		_deleteWithdrawalRequest(withdrawalRequestId);

		return true;
	}
}