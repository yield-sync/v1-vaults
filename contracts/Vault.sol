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


contract Vaults is AccessControl {
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
		uint256 lastChecked;
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


	/* [CONSTRUCTOR] */
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


	/* [RECIEVE] */
	receive () external payable {
		revert(
			"Sending Ether directly to this contract is disabled"
			"Please use `depositTokens` function to send ERC20 tokens into vault"
		);
	}


	/* [FALLBACK] */
	fallback () external payable {
		revert(
			"Sending Ether directly to this contract is disabled"
			"Please use `depositTokens` function to send ERC20 tokens into vault"
		);
	}


	/**
	 * %%%%%%%%%%%%%%%%%%%%%%
	 * %%% NO ROLE NEEDED %%%
	 * %%%%%%%%%%%%%%%%%%%%%%
	*/

	/**
	 * @notice [GETTER] _withdrawalRequest
	 * @param withdrawalRequestId {uint256} Id of the WithdrawalRequest
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
	 * @notice Get WithdrawalRequests by Creator
	 * @param creator {uint256} Address to query WithdrawalRequests for
	*/
	function WithdrawalRequestsByCreator(address creator)
		public
		view
		returns (WithdrawalRequest[] memory)
	{
		// Get array of WithdrawalRequest Ids for the provided creator
		uint256[] memory withdrawalRequestIds = _withdrawalRequestByCreator[creator];

		// Create array of WithdrawalRequests
		WithdrawalRequest[] memory wr = new WithdrawalRequest[](
			withdrawalRequestIds.length
		);

		// For each WithdrawalRequest Id..
		for (uint256 i = 0; i < withdrawalRequestIds.length; i++) {
			// Look up the request using the ID
			wr[i] = _withdrawalRequest[withdrawalRequestIds[i]];
		}

		return wr;
	}
	
	/**
	 * @notice Deposit funds
	 * @param tokenAddress {address} Address of token contract
	 * @param amount {uint256} Amount to be moved
	*/
	function depositTokens(
		address tokenAddress,
		uint256 amount
	)
		public payable
		returns (bool)
	{
		// Transfer amount from msg.sender to this contract
		IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);

		// Update vault token balance
		_tokenBalance[tokenAddress] += amount;

		return true;
	}

	/**
	 * @notice [CREATE] WithdrawalRequest
	 * @param to {address} Address the withdrawal it to be sent
	 * @param tokenAddress {address} Address of token contract
	 * @param amount {uint256} Amount to be moved
	*/
	function createWithdrawalRequest(
		address to,
		address tokenAddress,
		uint256 amount
	)
		public
		returns (bool)
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
			lastChecked: block.timestamp
		});

		_withdrawalRequestByCreator[msg.sender].push(_withdrawalRequestId);

		return true;
	}

	/**
	 * @notice Proccess the WithdrawalRequest
	 * @param withdrawalRequestId {uint256} Id of the WithdrawalRequest
	*/
	function processWithdrawalRequests(uint256 withdrawalRequestId)
		public
		validWithdrawalRequest(withdrawalRequestId)
		returns (bool)
	{
		// Get the current time
		uint256 currentTime = block.timestamp;

		// Create temporary variable
		WithdrawalRequest memory wr = _withdrawalRequest[withdrawalRequestId];

		// If the withdrawal request has reached the required number of signatures
		if (
			wr.forVoteCount >= requiredSignatures &&
			(
				currentTime - wr.lastChecked >= SafeMath.mul(withdrawalDelayMinutes, 60) ||
				wr.accelerated
			) &&
			!wr.paused
		)
		{
			// Transfer the specified amount of tokens to the recipient
			IERC20(wr.token).safeTransfer(wr.to, wr.amount);

			// [DECREMENT] The vault token balance
			_tokenBalance[wr.token] -= wr.amount;

			// [DELETE] _withdrawalRequest WithdrawalRequest
			delete _withdrawalRequest[withdrawalRequestId];

			// [DELETE] _withdrawalRequestVotedVoters value
			delete _withdrawalRequestVotedVoters[withdrawalRequestId];

			// [DELETE] _withdrawalRequestByCreator
			for (uint256 i = 0; i < _withdrawalRequestByCreator[msg.sender].length; i++)
			{
				if (_withdrawalRequestByCreator[msg.sender][i] == withdrawalRequestId)
				{
					delete _withdrawalRequestByCreator[msg.sender][i];

					break;
				}
			}
		}
		
		return true;
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
	*/
	function voteOnWithdrawalRequest(
		uint256 withdrawalRequestId,
		bool vote
	)
		public
		onlyRole(VOTER_ROLE)
		validWithdrawalRequest(withdrawalRequestId)
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
			// [UPDATE] lastChecked timestamp
			_withdrawalRequest[withdrawalRequestId].lastChecked = block.timestamp;
		}
	}


	/**
	 * %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	 * %%% ROLE: DEFAULT_ADMIN_ROLE %%%
	 * %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	*/

	/**
	 * @notice Add a voter
	 * @param voter {address} Address of the voter to add
	*/
	function addVoter(address voter)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		// Add the voter to the VOTER_ROLE
		_setupRole(VOTER_ROLE, voter);
	}

	/**
	 * @notice Remove a voter
	 * @param voter {address} Address of the voter to remove
	*/
	function removeVoter(address voter)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		_revokeRole(VOTER_ROLE, voter);
	}

	/**
	 * @notice Update `withdrawalDelayMinutes`
	 * @param withdrawalDelayMinutes_ {uint256} New withdrawalDelayMinutes
	*/
	function updateWithdrawalDelayMinutes(uint256 withdrawalDelayMinutes_)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		// [REQUIRE] withdrawalDelayMinutes_ is greater than 0
		require(withdrawalDelayMinutes_ >= 0, "Invalid withdrawalDelayMinutes_");

		// Set delay (in minutes)
		withdrawalDelayMinutes = withdrawalDelayMinutes_;
	}

	/**
	 * @notice Toggle `pause` on a WithdrawalRequest
	 * @param withdrawalRequestId {uint256} Id of the WithdrawalRequest
	*/
	function toggleWithdrawalRequestPause(uint256 withdrawalRequestId)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		validWithdrawalRequest(withdrawalRequestId)
	{
		_withdrawalRequest[withdrawalRequestId].paused = !_withdrawalRequest[
			withdrawalRequestId
		].paused;
	}

	/**
	 * @notice Toggle `pause` on a WithdrawalRequest
	 * @param withdrawalRequestId {uint256} Id of the WithdrawalRequest
	*/
	function deleteWithdrawalRequest(uint256 withdrawalRequestId)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		validWithdrawalRequest(withdrawalRequestId)
	{
		// [DELETE] _withdrawalRequest WithdrawalRequest
		delete _withdrawalRequest[withdrawalRequestId];

		// [DELETE] _withdrawalRequestVotedVoters value
		delete _withdrawalRequestVotedVoters[withdrawalRequestId];

		// [DELETE] _withdrawalRequestByCreator
		for (uint256 i = 0; i < _withdrawalRequestByCreator[msg.sender].length; i++)
		{
			if (_withdrawalRequestByCreator[msg.sender][i] == withdrawalRequestId)
			{
				delete _withdrawalRequestByCreator[msg.sender][i];

				break;
			}
		}
	}
}