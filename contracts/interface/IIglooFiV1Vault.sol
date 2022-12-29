// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [struct] */
struct WithdrawalRequest {
	address creator;
	address to;
	address token;
	uint256 amount;
	uint256 approveVoteCount;
	uint256 denyVoteCount;
	uint256 latestRelevantApproveVoteTime;
}


/**
* @title Igloo Fi V1 Vault
*/
interface IglooFiV1Vault
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
	* @dev Emits when `requiredApproveVotes` are updated
	*/
	event UpdatedRequiredApproveVotes (
		uint256 requiredApproveVotes
	);

	/**
	* @dev Emits when an address is added to VOTER_ROLE on `AccessControlEnumerable`
	*/
	event VoterAdded (
		address addedVoter
	);

	/**
	* @dev Emits when an address is removed from VOTER_ROLE on `AccessControlEnumerable`
	*/
	event VoterRemoved (
		address addedVoter
	);

	/**
	* @dev Emits when `withdrawalDelayMinutes` is updated
	*/
	event UpdatedWithdrawalDelayMinutes (
		uint256 withdrawalDelayMinutes
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
	* @notice Sign a message
	*
	* @dev [increment] Value in `messageSignatures`
	*
	* @param _messageHash {bytes32}
	* @param _signature {byte}
	*/
    function sign(bytes32 _messageHash, bytes memory _signature)
		public
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

	/**
	* @notice Assign VOTER_ROLE to an address on AccessControlEnumerable
	*
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	*
	* @dev [add] address to VOTER_ROLE on `AccessControlEnumerable`
	*
	* @param targetAddress {address}
	*
	* @return {address} Voter added
	*
	* Emits: `VoterAdded`
	*/
	function addVoter(address targetAddress)
		external
		returns (address)
	;

	/**
	* @notice Remove a voter
	*
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	*
	* @dev [remove] address with VOTER_ROLE on `AccessControlEnumerable`
	*
	* @param voter {address} Address of the voter to remove
	*
	* @return {address} Removed voter
	*
	* Emits: `VoterRemoved`
	*/	
	function removeVoter(address voter)
		external
		returns (address)
	;

	/**
	* @notice Update the required approved votes
	*
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	*
	* @dev [update] `requiredApproveVotes`
	*
	* @param newRequiredApproveVotes {uint256}
	*
	* @return {uint256} New `requiredApproveVotes`
	*
	* Emits: `UpdatedRequiredApproveVotes`
	*/
	function updateRequiredApproveVotes(uint256 newRequiredApproveVotes)
		external
		returns (uint256)
	;

	/**
	* @notice Update `withdrawalDelayMinutes`
	*
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	*
	* @dev [update] `withdrawalDelayMinutes` to new value
	*
	* @param newWithdrawalDelayMinutes {uint256}
	*
	* @return {uint256} New `withdrawalDelayMinutes`
	*
	* Emits: `UpdatedWithdrawalDelayMinutes`
	*/
	function updateWithdrawalDelayMinutes(uint256 newWithdrawalDelayMinutes)
		external
		returns (uint256)
	;

	/**
	* @notice
	*
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	*
	* @dev [update] WithdrawalRequest within `_withdrawalRequest`
	*
	* @param newLatestRelevantApproveVoteTime {uint256}
	*
	* @return {uint256} `withdrawalRequestId`
	* @return {uint256} `newLatestRelevantApproveVoteTime`
	*
	* Emits: `UpdatedWithdrawalRequestLastSignificantApproveVote`
	*/
	function updateWithdrawalRequestLatestRelevantApproveVoteTime(
		uint256 withdrawalRequestId,
		uint256 newLatestRelevantApproveVoteTime
	)
		external
		returns (uint256, uint256)
	;

	/**
	* @notice Delete WithdrawalRequest & all associated values
	*
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	*
	* @dev [call][internal] {_deleteWithdrawalRequest}
	*
	* @param withdrawalRequestId {uint256}
	* @return {bool} Status
	*
	* Emits: `DeletedWithdrawalRequest`
	*/
	function deleteWithdrawalRequest(uint256 withdrawalRequestId)
		external
		returns (uint256)
}