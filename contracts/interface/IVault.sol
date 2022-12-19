// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/**
* @title IVault
* @notice This is a vault for storing ERC20 tokens.
*/
interface IVault
{
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


	/**
	* @dev [uint256]
	* @notice Required signatures for a vote
	* @return {bytes32} keccak256 value
	*/
	function requiredSignatures()
		external
		view
		returns (uint256)
	;

	/**
	* @dev [uint256]
	* @notice Delay in minutes withdrawal
	* @return {bytes32} keccak256 value
	*/
	function withdrawalDelayMinutes()
		external
		view
		returns (uint256)
	;

	/**
	* @dev [mapping]
	* @notice Token Balances
	* @param {address} Token contract address
	* @return {uint256} Balance of token
	*/
	function tokenBalance(address tokenAddress)
		external
		view
		returns (uint256)
	;

	/**
	* @dev [mapping]
	* @notice WithdrawalRequest Id => WithdrawalRequest
	* @param {address} WithdrawalRequestId
	* @return {WithdrawalRequest} Balance of token
	*/
	function withdrawalRequest(uint256 withdrawalRequestId)
		external
		view returns (WithdrawalRequest memory)
	;

	/**
	* @dev [getter]
	* @notice Get array of voters who have already voted on given Withdrawal Request 
	* @param withdrawalRequestId {uint256} Id of Withdrawal Request
	* @return {WithdrawalRequest}
	*/
	function withdrawalRequestVotedVoters(uint256 withdrawalRequestId)
		view
		external
		returns (address[] memory)
	;

	/**
	* @dev [getter]
	* @notice Get array of Withdrawal Request Ids by a given creator 
	* @param creator {address} Id of Withdrawal Request
	* @return {uint256[]} Array of Withdrawal Request Ids
	*/
	function withdrawalRequestByCreator(address creator)
		view
		external
		returns (uint256[] memory)
	;

	/**
	* @dev [IERC20][emit]
	* @notice Deposit funds
	* @param tokenAddress {address} Address of token contract
	* @param amount {uint256} Amount to be moved
	* @return {bool} Status
	* @return {uint256} Amount deposited
	* @return {uint256} New ERC20 token balance
	*/
	function depositTokens(address tokenAddress, uint256 amount)
		external
		payable
		returns (bool, uint256, uint256)
	;

	/**
	* @dev [create]
	* @notice Create a WithdrawalRequest
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
		external
		returns (bool, WithdrawalRequest memory)
	;

	/**
	* @dev 
	* @notice Proccess the WithdrawalRequest
	* @param withdrawalRequestId {uint256} Id of the WithdrawalRequest
	* @return {bool} Status
	* @return {string} Message
	*/
	function processWithdrawalRequests(uint256 withdrawalRequestId)
		external
		returns (bool, string memory)
	;

	/**
	* @dev [update]
	* @notice Vote to approve or disapprove withdrawal request
	* @param withdrawalRequestId {uint256} Id of the WithdrawalRequest
	* @param vote {bool} For or against vote
	* @return {bool} Status
	* @return {bool} Vote received
	* @return {bool} forVoteCount
	* @return {bool} againstVoteCount
	* @return {bool} lastImpactfulVote
	*/
	function voteOnWithdrawalRequest(uint256 withdrawalRequestId, bool vote)
		external
		returns (bool, bool, uint256, uint256, uint256)
	;

	/**
	* @dev [update]
	* @notice Update `requiredSignatures`
	* @param newRequiredSignatures {uint256} New requiredSignatures
	* @return {bool} Status
	* @return {uint256} New requiredSignatures
	*/
	function updateRequiredSignatures(uint256 newRequiredSignatures)
		external
		returns (bool, uint256)
	;

	/**
	* @dev [create]
	* @notice Add a voter
	* @param voter {address} Address of the voter to add
	* @return {bool} Status
	* @return {address} Voter added
	*/
	function addVoter(address voter)
		external
		returns (bool, address)
	;

	/**
	* @dev [delete]
	* @notice Remove a voter
	* @param voter {address} Address of the voter to remove
	* @return {bool} Status
	* @return {address} Voter removed
	*/	
	function removeVoter(address voter)
		external
		returns (bool, address)
	;

	/**
	* @dev [update]
	* @notice Update `withdrawalDelayMinutes`
	* @param newWithdrawalDelayMinutes {uint256} New withdrawalDelayMinutes
	* @return {bool} Status
	* @return {uint256} New withdrawalDelayMinutes
	*/
	function updateWithdrawalDelayMinutes(uint256 newWithdrawalDelayMinutes)
		external
		returns (bool, uint256)
	;

	/**
	* @dev [update]
	* @notice Toggle `pause` on a WithdrawalRequest
	* @param withdrawalRequestId {uint256} Id of the WithdrawalRequest
	* @return {bool} Status
	* @return {WithdrawalRequest} Updated WithdrawalRequest
	*/
	function toggleWithdrawalRequestPause(uint256 withdrawalRequestId)
		external
		returns (bool, WithdrawalRequest memory)
	;

	/**
	* @dev [delete]
	* @notice Toggle `pause` on a WithdrawalRequest
	* @param withdrawalRequestId {uint256} Id of the WithdrawalRequest
	* @return {bool} Status
	*/
	function deleteWithdrawalRequest(uint256 withdrawalRequestId)
		external
		returns (bool)
	;


	/**
	* @dev [event]
	* @notice Emits when tokens are deposited
	*/
	event TokensDeposited (
		address indexed depositor,
		address indexed token,
		uint256 amount
	);

	/**
	* @dev [event]
	* @notice Emits when tokens are withdrawn
	*/
	event TokensWithdrawn (
		address indexed withdrawer,
		address indexed token,
		uint256 amount
	);
}