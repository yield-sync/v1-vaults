// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/**
* @title IVault
*/
interface IVault
{
	/**
	* @dev [struct]
	* @notice Struct of a `WithdrawalRequest`
	*/
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
	* @notice Get Withdrawal delay (denominated in minutes)
	* @return {bytes32} keccak256 value
	*/
	function withdrawalDelayMinutes()
		external
		view
		returns (uint256)
	;

	/**
	* @dev [getter][mapping]
	* @notice Get token balance
	* @param {address} Token contract address
	* @return {uint256} Balance of token
	*/
	function tokenBalance(address tokenAddress)
		external
		view
		returns (uint256)
	;

	/**
	* @dev [getter][mapping]
	* @notice Get `WithdrawalRequest` with given Id
	* @param {address} WithdrawalRequestId
	* @return {WithdrawalRequest} Balance of token
	*/
	function withdrawalRequest(uint256 withdrawalRequestId)
		external
		view returns (WithdrawalRequest memory)
	;

	/**
	* @dev [getter][mapping]
	* @notice Get array of voters that have voted with given `WithdrawalRequest` Id
	* @param withdrawalRequestId {uint256} Id of `WithdrawalRequest`
	* @return {WithdrawalRequest}
	*/
	function withdrawalRequestVotedVoters(uint256 withdrawalRequestId)
		view
		external
		returns (address[] memory)
	;

	/**
	* @dev [getter][mapping]
	* @notice Get array of `WithdrawalRequest` Ids by a given creator 
	* @param creator {address} Id of `WithdrawalRequest`
	* @return {uint256[]} Array of `WithdrawalRequest` Ids
	*/
	function withdrawalRequestByCreator(address creator)
		view
		external
		returns (uint256[] memory)
	;

	/**
	* @dev [IERC20][emit]
	* @notice Deposit tokens
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
	* @notice Create a `WithdrawalRequest`
	* @param to {address} Address the withdrawn tokens will be sent
	* @param tokenAddress {address} Address of token contract
	* @param amount {uint256} Amount to be withdrawn
	* @return {bool} Status
	* @return {WithdrawalRequest} The created `WithdrawalRequest`
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
	* @notice Process the WithdrawalRequest
	* @param withdrawalRequestId {uint256} Id of the `WithdrawalRequest`
	* @return {bool} Status
	* @return {string} Message
	*/
	function processWithdrawalRequests(uint256 withdrawalRequestId)
		external
		returns (bool, string memory)
	;

	/**
	* @dev [update]
	* @notice Vote on withdrawal request
	* @param withdrawalRequestId {uint256} Id of the `WithdrawalRequest`
	* @param vote {bool} Approve (true) or deny (false)
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
	* @param newRequiredSignatures {uint256} New `requiredSignatures`
	* @return {bool} Status
	* @return {uint256} New `requiredSignatures`
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
	* @return {address} Removed voter
	*/	
	function removeVoter(address voter)
		external
		returns (bool, address)
	;

	/**
	* @dev [update]
	* @notice Update `withdrawalDelayMinutes`
	* @param newWithdrawalDelayMinutes {uint256} New `withdrawalDelayMinutes`
	* @return {bool} Status
	* @return {uint256} New `withdrawalDelayMinutes`
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
	* @return {WithdrawalRequest} Updated `WithdrawalRequest`
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