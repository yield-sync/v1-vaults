// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [struct] */
struct WithdrawalRequest {
	bool forEther;
	bool forERC20;
	bool forERC721;
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
	/**
	* @dev Emits when a `WithdrawalRequest` is deleted
	*/
	event DeletedWithdrawalRequest(uint256 withdrawalRequest);

	/**
	* @dev Emits when a `WithdrawalRequest` is created
	*/
	event CreatedWithdrawalRequest(uint256 withdrawalRequest);

	/**
	* @dev Emits when a voter has voted
	*/
	event VoterVoted(uint256 withdrawalRequestId, address indexed voter, bool vote);

	/**
	* @dev Emit when a WithdrawalRequest is ready to be processed
	*/
	event WithdrawalRequestReadyToBeProccessed(uint256 withdrawalRequestId);

	/**
	* @dev Emits when tokens are withdrawn
	*/
	event TokensWithdrawn(address indexed withdrawer, address indexed token, uint256 amount);

	/**
	* @dev Emits when `requiredVoteCount` are updated
	*/
	event UpdatedRequiredVoteCount(uint256 requiredVoteCount);

	/**
	* @dev Emits when `withdrawalDelaySeconds` is updated
	*/
	event UpdatedWithdrawalDelaySeconds(uint256 withdrawalDelaySeconds);

	/**
	* @dev Emits when `_withdrawalRequest[withdrawalRequestId].latestRelevantApproveVoteTime` is updated
	*/
	event UpdatedWithdrawalRequestLastSignificantApproveVote(
		uint256 withdrawalRequestId,
		uint256 latestRelevantApproveVoteTime
	);


	receive () external payable;


	fallback () external payable;


	/**
	* @notice Address of signature manager
	* @dev [!restriction]
	* @dev [view-address]
	* @return {address}
	*/
	function signatureManager()
		external
		view
		returns (address)
	;

	/**
	* @notice AccessControlEnumerable role
	* @dev [!restriction]
	* @dev [view-bytes32]
	* @return {uint256}
	*/
	function VOTER()
		external
		view
		returns (bytes32)
	;

	/**
	* @notice Required signatures for approval
	* @dev [!restriction]
	* @dev [view-uint256]
	* @return {uint256}
	*/
	function requiredVoteCount()
		external
		view
		returns (uint256)
	;

	/**
	* @notice Withdrawal delay in minutes
	* @dev [!restriction]
	* @dev [view-uint256]
	* @return {uint256}
	*/
	function withdrawalDelaySeconds()
		external
		view
		returns (uint256)
	;


	/**
	* @notice Getter for active WithdrawlRequests
	* @dev [!restriction]
	* @dev [view-uint256[]]
	* @return {uint256[]}
	*/
	function openWithdrawalRequestIds()
		external
		view
		returns (uint256[] memory)
	;

	/**
	* @notice Getter for `_withdrawalRequest`
	* @dev [!restriction]
	* @dev [view][mapping]
	* @param withdrawalRequestId {uint256}
	* @return {WithdrawalRequest}
	*/
	function withdrawalRequest(uint256 withdrawalRequestId)
		external
		view returns (WithdrawalRequest memory)
	;


	/**
	* @notice Create a WithdrawalRequest
	* @dev [restriction] AccessControlEnumerable → VOTER
	* @dev [increment] `_withdrawalRequestId`
	*      [add] `_withdrawalRequest` value
	*      [push-into] `_withdrawalRequestIds`
	* @param forEther {bool} If to be withdrawn asset is Ether
	* @param forERC20 {bool} If to be withdrawn asset is ERC20
	* @param forERC721 {bool} If to be withdrawn asset is ERC721
	* @param to {address} Address the withdrawn tokens will be sent
	* @param tokenAddress {address}
	* @param amount {uint256} Amount to be withdrawn
	* @param tokenId {uint256} erc721 token id
	* @return {uint256} `_withdrawalRequestId`
	* Emits: `CreatedWithdrawalRequest`
	*/
	function createWithdrawalRequest(
		bool forEther,
		bool forERC20,
		bool forERC721,
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
	* @dev [restriction] AccessControlEnumerable → VOTER
	* @dev [update] `_withdrawalRequest`
	*      [update] `_withdrawalRequestVotedVoters`
	* @param withdrawalRequestId {uint256}
	* @param vote {bool} true (approve) or false (deny)
	* Emits: `WithdrawalRequestReadyToBeProccessed`
	* Emits: `VoterVoted`
	*/
	function voteOnWithdrawalRequest(uint256 withdrawalRequestId, bool vote)
		external
	;

	/**
	* @notice Process WithdrawalRequest with given `withdrawalRequestId`
	* @dev [restriction] AccessControlEnumerable → VOTER
	* @dev [erc20-transfer]
	*      [decrement] `_tokenBalance`
	*      [call][internal] `_deleteWithdrawalRequest`
	* @param withdrawalRequestId {uint256} Id of the WithdrawalRequest
	* Emits: `TokensWithdrawn`
	*/
	function processWithdrawalRequest(uint256 withdrawalRequestId)
		external
	;


	/**
	* @notice Update Signature Manager Contract
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [update] `signatureManager`
	* @param _signatureManager {address}
	*/
	function updateSignatureManager(address _signatureManager)
		external
	;

	/**
	* @notice Assign VOTER to an address on AccessControlEnumerable
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [add] address to VOTER on `AccessControlEnumerable`
	* @param targetAddress {address}
	*/
	function addVoter(address targetAddress)
		external
	;

	/**
	* @notice Remove a voter
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [remove] address with VOTER on `AccessControlEnumerable`
	* @param voter {address} Address of the voter to remove
	*/	
	function removeVoter(address voter)
		external
	;

	/**
	* @notice Update the required approved votes
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [update] `requiredVoteCount`
	* @param newRequiredVoteCount {uint256}
	* Emits: `UpdatedRequiredVoteCount`
	*/
	function updateRequiredVoteCount(uint256 newRequiredVoteCount)
		external
	;

	/**
	* @notice Update `withdrawalDelaySeconds`
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [update] `withdrawalDelaySeconds` to new value
	* @param newWithdrawalDelaySeconds {uint256}
	* Emits: `UpdatedWithdrawalDelaySeconds`
	*/
	function updateWithdrawalDelaySeconds(uint256 newWithdrawalDelaySeconds)
		external
	;

	/**
	* @notice 
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [update] WithdrawalRequest within `_withdrawalRequest`
	* @param withdrawalRequestId {uint256}
	* @param arithmaticSign {bool} true → Add | false → Subtract 
	* @param timeInSeconds {uint256}
	* Emits: `UpdatedWithdrawalRequestLastSignificantApproveVote`
	*/
	function updateWithdrawalRequestLatestRelevantApproveVoteTime(
		uint256 withdrawalRequestId,
		bool arithmaticSign,
		uint256 timeInSeconds
	)
		external
	;

	/**
	* @notice Delete WithdrawalRequest & all associated values
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [call][internal] {_deleteWithdrawalRequest}
	* @param withdrawalRequestId {uint256}
	* Emits: `DeletedWithdrawalRequest`
	*/
	function deleteWithdrawalRequest(uint256 withdrawalRequestId)
		external
	;
}