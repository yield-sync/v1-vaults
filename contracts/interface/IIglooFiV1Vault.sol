// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [struct] */
struct WithdrawalRequest {
	bool requestETH;
	address creator;
	address to;
	address token;
	uint256 amount;
	uint256 tokenId;
	uint256 voteCount;
	uint256 latestRelevantApproveVoteTime;
	address[] votedVoters;
}


/**
* @title IIglooFiV1Vault
*/
interface IIglooFiV1Vault
{
	/* [event] */
	/**
	* @dev
	*/
	event EtherRecieved(
		address msgSender,
		uint256 EtherRecieved
	);

	/**
	* @dev Emits when a `WithdrawalRequest` is deleted
	*/
	event DeletedWithdrawalRequest(
		uint256 WithdrawalRequest
	);

	/**
	* @dev Emits when a `WithdrawalRequest` is created
	*/
	event CreatedWithdrawalRequest(
		WithdrawalRequest withdrawalRequest
	);

	/**
	* @dev Emits when a voter has voted
	*/
	event VoterVoted(
		uint256 withdrawalRequestId,
		address indexed voter,
		bool vote
	);

	/**
	* @dev Emit when a WithdrawalRequest is ready to be processed
	*/
	event WithdrawalRequestReadyToBeProccessed(
		uint256 withdrawalRequestId
	);

	/**
	* @dev Emits when tokens are withdrawn
	*/
	event TokensWithdrawn(
		address indexed withdrawer,
		address indexed token,
		uint256 amount
	);

	/**
	* @dev Emits when `requiredVoteCount` are updated
	*/
	event UpdatedRequiredVoteCount(
		uint256 requiredVoteCount
	);

	/**
	* @dev Emits when `withdrawalDelaySeconds` is updated
	*/
	event UpdatedWithdrawalDelaySeconds(
		uint256 withdrawalDelaySeconds
	);

	/**
	* @dev Emits when `_withdrawalRequest[withdrawalRequestId].latestRelevantApproveVoteTime` is updated
	*/
	event UpdatedWithdrawalRequestLastSignificantApproveVote(
		uint256 withdrawalRequestId,
		uint256 latestRelevantApproveVoteTime
	);


	/**
	* @notice Invalid return value for isValidSignature
	*
	* @dev [!restriction]
	* @dev [view-bytes4]
	*
	* @return {uint256}
	*/
	function INVALID_SIGNATURE()
		external
		view
		returns (bytes4)
	;

	/**
	* @notice Valid return value for isValidSignature
	*
	* @dev [!restriction]
	* @dev [view-bytes4]
	*
	* @return {uint256}
	*/
	function MAGICVALUE()
		external
		view
		returns (bytes4)
	;

	/**
	* @notice AccessControlEnumerable role
	*
	* @dev [!restriction]
	* @dev [view-bytes32]
	*
	* @return {uint256}
	*/
	function VOTER()
		external
		view
		returns (bytes32)
	;

	/**
	* @notice Required signatures for approval
	*
	* @dev [!restriction]
	* @dev [view-uint256]
	*
	* @return {uint256}
	*/
	function requiredVoteCount()
		external
		view
		returns (uint256)
	;

	/**
	* @notice Withdrawal delay in minutes
	*
	* @dev [!restriction]
	* @dev [view-uint256]
	*
	* @return {uint256}
	*/
	function withdrawalDelaySeconds()
		external
		view
		returns (uint256)
	;

	/**
	* @notice Getter for `creatorWithdrawalRequests`
	*
	* @dev [!restriction]
	* @dev [view][mapping]
	*
	* @param creator {address}
	*
	* @return {uint256[]}
	*/
	function creatorWithdrawalRequests(address creator)
		view
		external
		returns (uint256[] memory)
	;

	/**
	* @notice Getter for `_messageSignature`
	*
	* @dev [!restriction]
	* @dev [view][mapping]
	*
	* @param message {bytes32}
	*
	* @return {uint256}
	*/
	function messageSignatures(bytes32 message)
		view
		external
		returns (uint256)
	;

	/**
	* @notice Getter for `_withdrawalRequest`
	*
	* @dev [!restriction]
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
	* @notice Sign a message
	*
	* @dev [!restriction]
	* @dev [increment] Value in `messageSignatures`
	*
	* @param _messageHash {bytes32}
	* @param _signature {byte}
	*/
	function sign(bytes32 _messageHash, bytes memory _signature)
		external
	;


	/**
	* @notice Create a WithdrawalRequest
	*
	* @dev [restriction] AccessControlEnumerable → VOTER
	* @dev [increment] `_withdrawalRequestId`
	*      [add] `_withdrawalRequest` value
	*      [push-into] `_creatorWithdrawalRequests`
	*
	* @param requestETH {bool} If to be withdrawn asset is ETH set to true
	* @param to {address} Address the withdrawn tokens will be sent
	* @param tokenAddress {address}
	* @param amount {uint256} Amount to be withdrawn
	* @param tokenId {uint256} erc721 token id
	*
	* @return {uint256} `_withdrawalRequestId`
	*
	* Emits: `CreatedWithdrawalRequest`
	*/
	function createWithdrawalRequest(
		bool requestETH,
		address to,
		address tokenAddress,
		uint256 amount,
		uint256 tokenId
	)
		external
		returns (uint256)
	;

	/**
	* @notice Vote on WithdrawalRequest
	*
	* @dev [restriction] AccessControlEnumerable → VOTER
	* @dev [update] `_withdrawalRequest`
	*      [update] `_withdrawalRequestVotedVoters`
	*
	* @param withdrawalRequestId {uint256}
	* @param vote {bool} true (approve) or false (deny)
	*
	* @return {bool} Vote
	* @return {bool} voteCount
	* @return {bool} lastImpactfulVote
	*
	* Emits: `WithdrawalRequestReadyToBeProccessed`
	* Emits: `VoterVoted`
	*/
	function voteOnWithdrawalRequest(uint256 withdrawalRequestId, bool vote)
		external
		returns (bool, uint256, uint256)
	;

	/**
	* @notice Process WithdrawalRequest with given `withdrawalRequestId`
	*
	* @dev [restriction] AccessControlEnumerable → VOTER
	* @dev [erc20-transfer]
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
	* @notice Assign VOTER to an address on AccessControlEnumerable
	*
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [add] address to VOTER on `AccessControlEnumerable`
	*
	* @param targetAddress {address}
	*
	* @return {address} Voter added
	*/
	function addVoter(address targetAddress)
		external
		returns (address)
	;

	/**
	* @notice Remove a voter
	*
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [remove] address with VOTER on `AccessControlEnumerable`
	*
	* @param voter {address} Address of the voter to remove
	*
	* @return {address} Removed voter
	*/	
	function removeVoter(address voter)
		external
		returns (address)
	;

	/**
	* @notice Update the required approved votes
	*
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [update] `requiredVoteCount`
	*
	* @param newRequiredVoteCount {uint256}
	*
	* @return {uint256} New `requiredVoteCount`
	*
	* Emits: `UpdatedRequiredVoteCount`
	*/
	function updateRequiredVoteCount(uint256 newRequiredVoteCount)
		external
		returns (uint256)
	;

	/**
	* @notice Update `withdrawalDelaySeconds`
	*
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [update] `withdrawalDelaySeconds` to new value
	*
	* @param newWithdrawalDelaySeconds {uint256}
	*
	* @return {uint256} New `withdrawalDelaySeconds`
	*
	* Emits: `UpdatedWithdrawalDelaySeconds`
	*/
	function updateWithdrawalDelaySeconds(uint256 newWithdrawalDelaySeconds)
		external
		returns (uint256)
	;

	/**
	* @notice
	*
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
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
	* @dev [call][internal] {_deleteWithdrawalRequest}
	*
	* @param withdrawalRequestId {uint256}
	*
	* @return {bool} Status
	*
	* Emits: `DeletedWithdrawalRequest`
	*/
	function deleteWithdrawalRequest(uint256 withdrawalRequestId)
		external
		returns (uint256)
	;
}