// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [import] */
import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";


/**
* @title IVault
*/
interface IVault is
	IAccessControlEnumerable
{
	struct WithdrawalRequest {
		address creator;
		address to;
		address token;
		uint256 amount;
		uint256 forVoteCount;
		uint256 againstVoteCount;
		uint256 lastImpactfulVoteTime;

		bool accelerated;
		bool paused;
	}


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
	* @dev [uint256-getter]
	*
	* @return {uint256}
	*/
	function requiredSignatures()
		external
		view
		returns (uint256)
	;

	/**
	* @notice Get Withdrawal delay in minutes
	*
	* @dev [uint256-getter]
	*
	* @return {uint256}
	*/
	function withdrawalDelayMinutes()
		external
		view
		returns (uint256)
	;

	/**
	* @notice Create a WithdrawalRequest
	*
	* @dev [increment] `_withdrawalRequestId`
	*      [add] `_withdrawalRequest` value
	*      [push-into] `_withdrawalRequestByCreator`
	*
	* @param to {address} Address the withdrawn tokens will be sent
	* @param tokenAddress {address}
	* @param amount {uint256} Amount to be withdrawn
	* @return {bool} Status
	* @return {uint256} Id of the added `WithdrawalRequest`
	*
	* Emits: `CreatedWithdrawalRequest`
	*/
	function createWithdrawalRequest(
		address to,
		address tokenAddress,
		uint256 amount
	)
		external
		returns (bool, uint256)
	;

	/**
	* @notice Vote on WithdrawalRequest
	*
	* @dev [update] `_withdrawalRequest`
	*      [update] `_withdrawalRequestVotedVoters`
	*
	* @param withdrawalRequestId {uint256}
	* @param vote {bool} Approve (true) or deny (false)
	* @return {bool} Status
	* @return {bool} Vote
	* @return {bool} forVoteCount
	* @return {bool} againstVoteCount
	* @return {bool} lastImpactfulVote
	*
	* Emits: `WithdrawalRequestReadyToBeProccessed`
	* Emits: `VoterVoted`
	*/
	function voteOnWithdrawalRequest(uint256 withdrawalRequestId, bool vote)
		external
		returns (bool, bool, uint256, uint256, uint256)
	;

	/**
	* @notice Process WithdrawalRequest with given `withdrawalRequestId`
	*
	* @dev [ERC20-transfer]
	*      [decrement] `_tokenBalance`
	*      [call][internal] `_deleteWithdrawalRequest`
	*
	* @param withdrawalRequestId {uint256} Id of the WithdrawalRequest
	* @return {bool} Status
	*
	* Emits: `TokensDeposited`
	* Emits: `DeletedWithdrawalRequest`
	*/
	function processWithdrawalRequests(uint256 withdrawalRequestId)
		external
		returns (bool)
	;


	/**
	* @notice Get token balance
	*
	* @dev [getter][mapping]
	*
	* @param tokenAddress {address} Token contract address
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
	* @dev [getter][mapping]
	*
	* @param withdrawalRequestId {uint256}
	* @return {WithdrawalRequest}
	*/
	function withdrawalRequest(uint256 withdrawalRequestId)
		external
		view returns (WithdrawalRequest memory)
	;

	/**
	* @notice Get array of voters
	*
	* @dev [getter][mapping]
	*
	* @param withdrawalRequestId {uint256} Id of WithdrawalRequest
	* @return {WithdrawalRequest}
	*/
	function withdrawalRequestVotedVoters(uint256 withdrawalRequestId)
		view
		external
		returns (address[] memory)
	;

	/**
	* @notice Get withdrawalRequestIds by a given creator
	*
	* @dev [getter][mapping]
	*
	* @param creator {address}
	* @return {uint256[]} Array of `WithdrawalRequestId`'s
	*/
	function withdrawalRequestByCreator(address creator)
		view
		external
		returns (uint256[] memory)
	;

	/**
	* @notice Deposit tokens
	*
	* @dev [ERC20-transfer] Transfer amount from msg.sender to this contract
	*      [increment] `_tokenBalance`
	*
	* @param tokenAddress {address}
	* @param amount {uint256} Amount to be moved
	* @return {bool} Status
	* @return {uint256} Amount deposited
	* @return {uint256} New token balance
	*
	* Emits: `TokensDeposited`
	*/
	function depositTokens(address tokenAddress, uint256 amount)
		external
		payable
		returns (bool, uint256, uint256)
	;
}