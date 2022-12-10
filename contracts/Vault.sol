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
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


contract Vaults is AccessControl {
	/* [USING] */
	using EnumerableSet for EnumerableSet.AddressSet;
	using EnumerableSet for EnumerableSet.UintSet;
	using SafeERC20 for IERC20;


	/* [STRUCT] */
	struct WithdrawalRequest {
		address msgSender;

		address to;
		
		address token;

		uint256 amount;

		uint256 forVoteCount;

		uint256 againstVoteCount;

		uint lastChecked;		
	}


	/* [STATE-VARIABLE] */
	uint256 public requiredSignatures;

	uint256 _withdrawalRequestId;


	// ERC20 Contract Address => Balance
	mapping (address => uint256) _tokenBalance;

	// WithdrawalRequest Id => WithdrawalRequest
	mapping (uint256 => WithdrawalRequest) _withdrawalRequest;


	// [ENMERABLE-SET]
	// Addresses allowed to vote
	EnumerableSet.AddressSet authorizedVoters;
	
	// Queued Withdrawals 
	EnumerableSet.UintSet queuedWithdrawals;


	/* [CONSTRUCTOR] */
	constructor (uint256 requiredSignatures_)
	{
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

		requiredSignatures = requiredSignatures_;

		_withdrawalRequestId = 0;
	}


	/* [RECIEVE] */
	receive ()
		external payable
	{}


	/**
	* @notice Add an authorized voter
	* @param voter {address} Address of the voter to add
	*/
	function addAuthorizedVoter(address voter)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		// Add the voter to the list of authorized voters
		authorizedVoters.add(voter);
	}


	/**
	* @notice Remove an authorized voter
	* @param voter {address} Address of the voter to remove
	*/
	function removeAuthorizedVoter(address voter)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		authorizedVoters.remove(voter);
	}


	/**
	 * @notice Deposit funds into this vault
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
		uint256 id = _withdrawalRequestId++;

		_withdrawalRequest[id] = WithdrawalRequest({
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
	 * @notice Vote to approve or disapprove withdrawal request
	 * @param WithdrawalRequestId {uint256} Id of the WithdrawalRequest
	 * @param msgSenderVote {bool} For or against vote
	*/
	function voteOnWithdrawalRequest(
		uint256 WithdrawalRequestId,
		bool msgSenderVote
	)
		public
	{
		// Check if the WithdrawalRequestId exists
		require(
			_withdrawalRequest[WithdrawalRequestId].msgSender != address(0),
			"Invalid WithdrawalRequestId"
		);

		require(authorizedVoters.contains(msg.sender), "!AUTH");

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
	 * @notice Proccess WithdrawalRequest
	 * @param wRId {uint256} Id of the WithdrawalRequest
	*/
	function processWithdrawalRequests(uint256 wRId) public returns (bool) {
		// If the withdrawal request has reached the required number of signatures
		if (_withdrawalRequest[wRId].forVoteCount >= requiredSignatures) {
			// Transfer the specified amount of tokens to the recipient
			IERC20(_withdrawalRequest[wRId].token)
				.safeTransfer(
					_withdrawalRequest[wRId].to,
					_withdrawalRequest[wRId].amount
				)
			;

			// [UPDATE] the vault token balance
			_tokenBalance[_withdrawalRequest[wRId].token] -= _withdrawalRequest[wRId].amount;

			// Remove the withdrawal request from the queue
			queuedWithdrawals.remove(wRId);
		}
		
		return true;
	}
}