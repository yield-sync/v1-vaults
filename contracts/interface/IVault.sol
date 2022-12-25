// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [import] */
import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";


/* [struct] */
struct WithdrawalRequest {
	address creator;
	address to;
	address token;
	uint256 amount;
	uint256 approveVoteCount;
	uint256 denyVoteCount;
	uint256 latestSignificantApproveVoteTime;
}


/**
* @title IVault
*/
interface IVault is
	IAccessControlEnumerable
{
	/* [event] */
	/**
	* @dev Emits when a `WithdrawalRequest` is deleted
	*/
	event DeletedWithdrawalRequest (
		uint256 WithdrawalRequest
	);

	/**
	* @dev Emits when a `WithdrawalRequest` is created
	*/
	event CreatedWithdrawalRequest (
		WithdrawalRequest withdrawalRequest
	);

	/**
	* @dev Emits when a voter has voted
	*/
	event VoterVoted (
		uint256 withdrawalRequestId,
		address indexed voter,
		bool vote
	);

	/**
	* @dev Emit when a WithdrawalRequest is ready to be processed
	*/
	event WithdrawalRequestReadyToBeProccessed (
		uint256 withdrawalRequestId
	);

	/**
	* @dev Emits when tokens are withdrawn
	*/
	event TokensWithdrawn (
		address indexed withdrawer,
		address indexed token,
		uint256 amount
	);

	/**
	* @dev Emits when tokens are deposited
	*/
	event TokensDeposited (
		address indexed depositor,
		address indexed token,
		uint256 amount
	);


	/**
	* @notice Required signatures for approval
	*
	* @dev [view-uint256]
	*
	* @return {uint256}
	*/
	function requiredApproveVotes()
		external
		view
		returns (uint256)
	;

	/**
	* @notice Get Withdrawal delay in minutes
	*
	* @dev [view-uint256]
	*
	* @return {uint256}
	*/
	function withdrawalDelayMinutes()
		external
		view
		returns (uint256)
	;


	/**
	* @notice Get token balance
	*
	* @dev [view][mapping]
	*
	* @param tokenAddress {address} Token contract address
	*
	* @return {uint256}
	*/
	function tokenBalance(address tokenAddress)
		external
		view
		returns (uint256)
	;

	/**
	* @notice Get WithdrawalRequest with given `withdrawalRequestId`
	*
	* @dev [view][mapping]
	*
	* @param withdrawalRequestId {uint256}
	*
	* @return {WithdrawalRequest}
	*/
	function withdrawalRequest(uint256 withdrawalRequestId)
		external
		view returns (WithdrawalRequest memory)
	;

	/**
	* @notice Get withdrawalRequestIds by a given creator
	*
	* @dev [view][mapping]
	*
	* @param creator {address}
	*
	* @return {uint256[]} Array of `WithdrawalRequestId`
	*/
	function withdrawalRequestByCreator(address creator)
		view
		external
		returns (uint256[] memory)
	;

	/**
	* @notice Get array of voters
	*
	* @dev [view][mapping]
	*
	* @param withdrawalRequestId {uint256} Id of WithdrawalRequest
	*
	* @return {WithdrawalRequest}
	*/
	function withdrawalRequestVotedVoters(uint256 withdrawalRequestId)
		view
		external
		returns (address[] memory)
	;


	/**
	* @notice Deposit tokens
	*
	* @dev [ERC20-transfer] Transfer amount from msg.sender to this contract
	*      [increment] `_tokenBalance`
	*
	* @param tokenAddress {address}
	* @param amount {uint256} Amount to be moved
	*
	* @return {uint256} Amount deposited
	* @return {uint256} New `_tokenBalance`
	*
	* Emits: `TokensDeposited`
	*/
	function depositTokens(address tokenAddress, uint256 amount)
		external
		returns (uint256, uint256)
	;


	/**
	* @notice Create a WithdrawalRequest
	*
	* @dev [restriction] AccessControlEnumerable → VOTER_ROLE
	*
	* @dev [increment] `_withdrawalRequestId`
	*      [add] `_withdrawalRequest` value
	*      [push-into] `_withdrawalRequestByCreator`
	*
	* @param to {address} Address the withdrawn tokens will be sent
	* @param tokenAddress {address}
	* @param amount {uint256} Amount to be withdrawn
	*
	* @return {uint256} `_withdrawalRequestId`
	*
	* Emits: `CreatedWithdrawalRequest`
	*/
	function createWithdrawalRequest(
		address to,
		address tokenAddress,
		uint256 amount
	)
		external
		returns (uint256)
	;

	/**
	* @notice Vote on WithdrawalRequest
	*
	* @dev [restriction] AccessControlEnumerable → VOTER_ROLE
	*
	* @dev [update] `_withdrawalRequest`
	*      [update] `_withdrawalRequestVotedVoters`
	*
	* @param withdrawalRequestId {uint256}
	* @param vote {bool} true (approve) or false (deny)
	*
	* @return {bool} Vote
	* @return {bool} approveVoteCount
	* @return {bool} denyVoteCount
	* @return {bool} lastImpactfulVote
	*
	* Emits: `WithdrawalRequestReadyToBeProccessed`
	* Emits: `VoterVoted`
	*/
	function voteOnWithdrawalRequest(uint256 withdrawalRequestId, bool vote)
		external
		returns (bool, uint256, uint256, uint256)
	;

	/**
	* @notice Process WithdrawalRequest with given `withdrawalRequestId`
	*
	* @dev [restriction] AccessControlEnumerable → VOTER_ROLE
	*
	* @dev [ERC20-transfer]
	*      [decrement] `_tokenBalance`
	*      [call][internal] `_deleteWithdrawalRequest`
	*
	* @param withdrawalRequestId {uint256} Id of the WithdrawalRequest
	*
	* Emits: `TokensWithdrawn`
	*/
	function processWithdrawalRequests(uint256 withdrawalRequestId)
		external
	;
}