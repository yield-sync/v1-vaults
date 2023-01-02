// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [struct] */
struct WithdrawalRequest {
	uint256 id;
	bool requestETH;
	address creator;
	address to;
	address token;
	uint256 amount;
	uint256 tokenId;
	uint256 approveVoteCount;
	uint256 denyVoteCount;
	uint256 latestRelevantApproveVoteTime;
}


/**
* @title IglooFiV1Vault
*/
interface IglooFiV1Vault
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
	* @dev Emits when an address is added to VOTER_ROLE on `AccessControlEnumerable`
	*/
	event AddedVoter(
		address addedVoter
	);

	/**
	* @dev Emits when an address is removed from VOTER_ROLE on `AccessControlEnumerable`
	*/
	event RemovedVoter(
		address addedVoter
	);

	/**
	* @dev Emits when `name` is updated
	*/
	event UpdatedName(
		string name
	);

	/**
	* @dev Emits when `requiredApproveVotes` are updated
	*/
	event UpdatedRequiredApproveVotes(
		uint256 requiredApproveVotes
	);

	/**
	* @dev Emits when `withdrawalDelayMinutes` is updated
	*/
	event UpdatedWithdrawalDelayMinutes(
		uint256 withdrawalDelayMinutes
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
		returns (uint256)
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
		returns (uint256)
	;

	/**
	* @notice AccessControlEnumerable role
	*
	* @dev [!restriction]
	* @dev [view-bytes32]
	*
	* @return {uint256}
	*/
	function VOTER_ROLE()
		external
		view
		returns (uint256)
	;

	/**
	* @notice Required signatures for approval
	*
	* @dev [!restriction]
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
	* @notice Withdrawal delay in minutes
	*
	* @dev [!restriction]
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
	* @notice Name
	*
	* @dev [!restriction]
	* @dev [view-string]
	*
	* @return {string}
	*/
	function name()
		external
		view
		returns (string)
	;


	/**
	* @notice Getter for array of withdrawalRequestIds by a given creator
	*
	* @dev [!restriction]
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
	* @notice Getter for `_withdrawalRequestVotedVoters`
	*
	* @dev [!restriction]
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
		public
		returns (uint256)
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
		public
	;


	/**
	* @notice Create a WithdrawalRequest
	*
	* @dev [restriction] AccessControlEnumerable → VOTER_ROLE
	* @dev [increment] `_withdrawalRequestId`
	*      [add] `_withdrawalRequest` value
	*      [push-into] `_withdrawalRequestByCreator`
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
	* @dev [restriction] AccessControlEnumerable → VOTER_ROLE
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
	* @notice Assign VOTER_ROLE to an address on AccessControlEnumerable
	*
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
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
	* @notice Update `name`
	*
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [update] `name`
	*
	* @param _name {string} 
	*
	* @return {address} Updated `name`
	*
	* Emits: `VoterRemoved`
	*/	
	function updateName(string memory _name)
		external
		returns (address)
	;

	/**
	* @notice Update the required approved votes
	*
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
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
}