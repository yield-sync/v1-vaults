// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


struct WithdrawalRequest {
	bool forERC20;
	bool forERC721;
	address creator;
	address to;
	address token;
	uint256 amount;
	uint256 tokenId;
	uint256 forVoteCount;
	uint256 againstVoteCount;
	uint256 latestRelevantApproveVoteTime;
	address[] votedMembers;
}


interface IYieldSyncV1Vault
{
	event CreatedWithdrawalRequest(uint256 withdrawalRequestId);
	event DeletedWithdrawalRequest(uint256 withdrawalRequestId);
	event TokensWithdrawn(address indexed withdrawer, address indexed token, uint256 amount);
	event UpdatedAgainstVoteCountRequired(uint256 againstVoteCountRequired);
	event UpdatedForVoteCountRequired(uint256 forVoteCountRequired);
	event UpdatedSignatureManger(address signatureManager);
	event UpdatedWithdrawalDelaySeconds(uint256 withdrawalDelaySeconds);
	event UpdatedWithdrawalRequest(WithdrawalRequest withdrawalRequest);
	event MemberVoted(uint256 withdrawalRequestId, address indexed member, bool vote);
	event WithdrawalRequestReadyToBeProcessed(uint256 withdrawalRequestId);
	event ProcessWithdrawalRequestFailed(uint256 withdrawalRequestId);


	receive ()
		external
		payable
	;

	fallback ()
		external
		payable
	;


	/**
	* @notice YieldSyncV1Vault Contract Address
	* @dev [!restriction]
	* @dev [view-address]
	* @return {address}
	*/
	function YieldSyncV1VaultAccessControl()
		external
		view
		returns (address)
	;

	/**
	* @notice signatureManager Contract Address
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
	* @notice Process WithdrawalRequest Locked
	* @dev [!restriction]
	* @dev [view-bool]
	* @return {bool}
	*/
	function processWithdrawalRequestLocked()
		external
		view
		returns (bool)
	;

	/**
	* @notice Against Vote Count Required
	* @dev [!restriction]
	* @dev [view-uint256]
	* @return {uint256}
	*/
	function againstVoteCountRequired()
		external
		view
		returns (uint256)
	;

	/**
	* @notice For Vote Count Required
	* @dev [!restriction]
	* @dev [view-uint256]
	* @return {uint256}
	*/
	function forVoteCountRequired()
		external
		view
		returns (uint256)
	;

	/**
	* @notice Withdrawal Delay In Seconds
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
	* @notice Ids of Open withdrawlRequests
	* @dev [!restriction]
	* @dev [view-uint256[]]
	* @return {uint256[]}
	*/
	function idsOfOpenWithdrawalRequests()
		external
		view
		returns (uint256[] memory)
	;

	/**
	* @notice withdrawalRequestId to withdralRequest
	* @dev [!restriction]
	* @dev [view][mapping]
	* @param withdrawalRequestId {uint256}
	* @return {WithdrawalRequest}
	*/
	function withdrawalRequestId_withdralRequest(uint256 withdrawalRequestId)
		external
		view returns (WithdrawalRequest memory)
	;


	/**
	* @notice Add Admin
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [add] admin on `YieldSyncV1Record`
	* @param targetAddress {address}
	*/
	function addAdmin(address targetAddress)
		external
	;

	/**
	* @notice Remove Admin
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [remove] admin on `YieldSyncV1Record`
	* @param admin {address}
	*/
	function removeAdmin(address admin)
		external
	;

	/**
	* @notice Add Member
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [add] member `YieldSyncV1Record`
	* @param targetAddress {address}
	*/
	function addMember(address targetAddress)
		external
	;

	/**
	* @notice Remove Member
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [remove] member on `YieldSyncV1Record`
	* @param member {address}
	*/
	function removeMember(address member)
		external
	;

	/**
	* @notice Delete withdrawalRequest & all associated values
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [call][internal] {_deleteWithdrawalRequest}
	* @param withdrawalRequestId {uint256}
	* Emits: `DeletedWithdrawalRequest`
	*/
	function deleteWithdrawalRequest(uint256 withdrawalRequestId)
		external
	;

	/**
	* @notice Update withdrawalRequest
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `_withdrawalRequest`
	* @param withdrawalRequestId {uint256}
	* @param __withdrawalRequest {WithdrawalRequest}
	* Emits: `UpdatedWithdrawalRequest`
	*/
	function updateWithdrawalRequest(uint256 withdrawalRequestId, WithdrawalRequest memory __withdrawalRequest)
		external
	;

	/**
	* @notice Update Against Vote Count Required
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `againstVoteCountRequired`
	* @param _againstVoteCountRequired {uint256}
	* Emits: `UpdatedAgainstVoteCountRequired`
	*/
	function updateAgainstVoteCountRequired(uint256 _againstVoteCountRequired)
		external
	;

	/**
	* @notice Update For Vote Count Required
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `forVoteCountRequired`
	* @param _forVoteCountRequired {uint256}
	* Emits: `UpdatedRequiredVoteCount`
	*/
	function updateForVoteCountRequired(uint256 _forVoteCountRequired)
		external
	;

	/**
	* @notice Update Signature Manager Contract
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `signatureManager`
	* @param _signatureManager {address}
	*/
	function updateSignatureManager(address _signatureManager)
		external
	;

	/**
	* @notice Update `withdrawalDelaySeconds`
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `withdrawalDelaySeconds` to new value
	* @param _withdrawalDelaySeconds {uint256}
	* Emits: `UpdatedWithdrawalDelaySeconds`
	*/
	function updateWithdrawalDelaySeconds(uint256 _withdrawalDelaySeconds)
		external
	;


	/**
	* @notice Create a withdrawalRequest
	* @dev [restriction] `YieldSyncV1Record` → member
	* @dev [increment] `_withdrawalRequestId`
	*      [add] `_withdrawalRequest` value
	*      [push-into] `_withdrawalRequestIds`
	* @param forERC20 {bool}
	* @param forERC721 {bool}
	* @param to {address}
	* @param tokenAddress {address} Token contract
	* @param amount {uint256}
	* @param tokenId {uint256} ERC721 token id
	* Emits: `CreatedWithdrawalRequest`
	*/
	function createWithdrawalRequest(
		bool forERC20,
		bool forERC721,
		address to,
		address tokenAddress,
		uint256 amount,
		uint256 tokenId
	)
		external
	;

	/**
	* @notice Vote on withdrawalRequest
	* @dev [restriction] `YieldSyncV1Record` → member
	* @dev [update] `_withdrawalRequest`
	* @param withdrawalRequestId {uint256}
	* @param vote {bool} true (approve) or false (deny)
	* Emits: `WithdrawalRequestReadyToBeProcessed`
	* Emits: `MemberVoted`
	*/
	function voteOnWithdrawalRequest(uint256 withdrawalRequestId, bool vote)
		external
	;

	/**
	* @notice Process withdrawalRequest with given `withdrawalRequestId`
	* @dev [restriction] `YieldSyncV1Record` → member
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
	* @notice Renounce Membership
	* @dev [restriction] `YieldSyncV1Record` → member
	* @dev [remove] member on `YieldSyncV1Record`
	*/
	function renounceMembership()
		external
	;
}
