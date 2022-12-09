// contracts/Vault.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [IMPORT] */
// /access
import "@openzeppelin/contracts/access/AccessControl.sol";
// /token
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';


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
	}


	/* [STATE-VARIABLE] */
	uint256 public requiredSignatures;

	uint256 _withdrawalRequestId;

	// Addresses that can vote
	address[] public authorizedVoters;

	// ERC20 Contract Address => Balance
	mapping (address => uint256) _tokenBalance;

	// WithdrawalRequest Id => Withdrawal Requested
	mapping (uint256 => WithdrawalRequest) _withdrawalRequest;

	// WithdrawalRequest Id => Withdrawal Requested
	mapping (uint256 => WithdrawalRequest) _queuedWithdrawalRequest;


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
		authorizedVoters.push(voter);
	}


	/**
	* @notice Remove an authorized voter
	* @param voter {address} Address of the voter to remove
	*/
	function removeAuthorizedVoter(address voter)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		// Iterate over the authorizedVoters array
		for (uint256 i = 0; i < authorizedVoters.length; i++) {
			// Check if the current voter is the one we want to remove
			if (authorizedVoters[i] == voter) {
				// Delete the voter from the array
				delete authorizedVoters[i];
				// Stop iterating over the array
				break;
			}
		}
	}


	/**
	 * @notice Deposit funds into vault
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
	 * @notice Create a withdrawal request
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

		// Create a new withdrawal request
		uint256 id = _withdrawalRequestId++;

		_withdrawalRequest[id] = WithdrawalRequest({
			msgSender: msg.sender,
			to: to,
			token: tokenAddress,
			amount: amount,
			forVoteCount: 0,
			againstVoteCount: 0
		});
	}


	/**
	 * @notice Change voter weight
	 * @param WithdrawalRequestId {uint256} Id of the WithdrawalRequest
	 * @param msgSenderVote {bool} For or against vote
	*/
	function vote(
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

		// Check if the msg.sender is authorized to vote
		bool isAuthorized = false;
		
		for (uint256 i = 0; i < authorizedVoters.length; i++) {
			if (authorizedVoters[i] == msg.sender) {
				isAuthorized = true;
				break;
			}
		}

		require(isAuthorized, "msg.sender is not authorized to vote");

		if (msgSenderVote) {
			_withdrawalRequest[WithdrawalRequestId].forVoteCount++;
		}
		else {
			_withdrawalRequest[WithdrawalRequestId].againstVoteCount++;
		}
	}
}