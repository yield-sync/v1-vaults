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
		address msgSender;
		address to;
		address token;
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
		for (uint256 i = 0; i < voters.length; i++) {
			// Set up the role VOTER_ROLE for the voter address
			_setupRole(VOTER_ROLE, voters[i]);
		}
	}


	/* [RECIEVE] */
	receive () external payable {
		revert("Cannot directly send Ether to this contract. Please use `depositTokens` function to send ERC20 tokens into vault.");
	}


	/* [FALLBACK] */
	fallback () external payable {
		revert("Cannot directly send Ether to this contract. Please use `depositTokens` function to send ERC20 tokens into vault.");
	}


	/**
	 * %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	 * %%% ROLE: DEFAULT_ADMIN_ROLE %%%
	 * %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	*/

	/**
	 * @notice Add an authorized voter
	 * @param voter {address} Address of the voter to add
	*/
	function addAuthorizedVoter(address voter)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		// Add the voter to the VOTER_ROLE
		_setupRole(VOTER_ROLE, voter);
	}

	/**
	 * @notice Remove an authorized voter
	 * @param voter {address} Address of the voter to remove
	*/
	function removeAuthorizedVoter(address voter)
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
		require(withdrawalDelayMinutes_ >= 0, "Invalid withdrawalDelayMinutes_");

		// Set delay (in minutes)
		withdrawalDelayMinutes = withdrawalDelayMinutes_;
	}


	/**
	 * %%%%%%%%%%%%%%%%%%%%%%%%
	 * %%% ROLE: VOTER_ROLE %%%
	 * %%%%%%%%%%%%%%%%%%%%%%%%
	*/

	/**
	 * @notice Vote to approve or disapprove withdrawal request
	 * @param WithdrawalRequestId {uint256} Id of the WithdrawalRequest
	 * @param msgSenderVote {bool} For or against vote
	*/
	function voteOnWithdrawalRequest(
		uint256 WithdrawalRequestId,
		bool msgSenderVote
	)
		public
		onlyRole(VOTER_ROLE)
	{
		// Check if the WithdrawalRequestId exists
		require(
			_withdrawalRequest[WithdrawalRequestId].msgSender != address(0),
			"Invalid WithdrawalRequestId"
		);

		if (msgSenderVote) {
			// [INCREMENT] For count
			_withdrawalRequest[WithdrawalRequestId].forVoteCount++;
		}
		else {
			// [INCREMENT] Against count
			_withdrawalRequest[WithdrawalRequestId].againstVoteCount++;
		}

		// [UPDATE] lastChecked timestamp
		_withdrawalRequest[WithdrawalRequestId].lastChecked = block.timestamp;
	}


	/**
	 * %%%%%%%%%%%%%%%%%%%%%%
	 * %%% NO ROLE NEEDED %%%
	 * %%%%%%%%%%%%%%%%%%%%%%
	*/
	
	/**
	 * @notice Deposit funds into this vault
	 * @param tokenAddress {address} Address of token contract
	 * @param amount {uint256} Amount to be moved
	*/
	function depositTokens(
		address tokenAddress,
		uint256 amount
	)
		public payable
	{
		// Transfer amount from msg.sender to this contract
		IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);

		// Update vault token balance
		_tokenBalance[tokenAddress] += amount;
	}

	/**
	 * @notice Create a WithdrawalRequest
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
	{
		// Require that the specified amount is available
		require(_tokenBalance[tokenAddress] >= amount, "Insufficient funds");

		// Require that 'to' is a valid Ethereum address
		require(to != address(0), "Invalid 'to' address");

		// Create a new WithdrawalRequest
		_withdrawalRequestId++;

		_withdrawalRequest[_withdrawalRequestId] = WithdrawalRequest({
			msgSender: msg.sender,
			to: to,
			token: tokenAddress,
			amount: amount,
			forVoteCount: 0,
			againstVoteCount: 0,
			lastChecked: block.timestamp
		});
	}

	/**
	 * @notice Proccess WithdrawalRequest
	 * @param wRId {uint256} Id of the WithdrawalRequest
	*/
	function processWithdrawalRequests(uint256 wRId) public returns (bool) {
		// Get the current time
		uint256 currentTime = block.timestamp;

		// If the withdrawal request has reached the required number of signatures
		if (
			_withdrawalRequest[wRId].forVoteCount >= requiredSignatures &&
			currentTime - _withdrawalRequest[wRId].lastChecked >= SafeMath.mul(withdrawalDelayMinutes, 60)
		) {
			// Transfer the specified amount of tokens to the recipient
			IERC20(_withdrawalRequest[wRId].token)
				.safeTransfer(
					_withdrawalRequest[wRId].to,
					_withdrawalRequest[wRId].amount
				)
			;

			// [UPDATE] the vault token balance
			_tokenBalance[_withdrawalRequest[wRId].token] -= _withdrawalRequest[wRId].amount;
		}
		
		return true;
	}
}