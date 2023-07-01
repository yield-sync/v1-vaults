// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


struct TransferRequest {
	bool forERC20;
	bool forERC721;
	address creator;
	address token;
	uint256 tokenId;
	uint256 amount;
	address to;
	uint256 forVoteCount;
	uint256 againstVoteCount;
	uint256 latestRelevantForVoteTime;
	address[] votedMembers;
}


interface IYieldSyncV1Vault
{
	event CreatedTransferRequest(uint256 transferRequestId);
	event DeletedTransferRequest(uint256 transferRequestId);
	event TokensTransferred(address indexed to, address indexed token, uint256 amount);
	event UpdatedAgainstVoteCountRequired(uint256 againstVoteCountRequired);
	event UpdatedForVoteCountRequired(uint256 forVoteCountRequired);
	event UpdatedSignatureManger(address signatureManager);
	event UpdatedTransferDelaySeconds(uint256 transferDelaySeconds);
	event UpdatedTransferRequest(TransferRequest transferRequest);
	event MemberVoted(uint256 transferRequestId, address indexed member, bool vote);
	event TransferRequestReadyToBeProcessed(uint256 transferRequestId);
	event ProcessTransferRequestFailed(uint256 transferRequestId);


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
	* @dev [view-address]
	* @return {address}
	*/
	function signatureManager()
		external
		view
		returns (address)
	;

	/**
	* @notice Process TransferRequest Locked
	* @dev [view-bool]
	* @return {bool}
	*/
	function processTransferRequestLocked()
		external
		view
		returns (bool)
	;

	/**
	* @notice Against Vote Count Required
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
	* @dev [view-uint256]
	* @return {uint256}
	*/
	function forVoteCountRequired()
		external
		view
		returns (uint256)
	;

	/**
	* @notice Transfer Delay In Seconds
	* @dev [view-uint256]
	* @return {uint256}
	*/
	function transferDelaySeconds()
		external
		view
		returns (uint256)
	;


	/**
	* @notice Ids of Open transferRequests
	* @dev [view][mapping]
	* @return {uint256[]}
	*/
	function idsOfOpenTransferRequests()
		external
		view
		returns (uint256[] memory)
	;

	/**
	* @notice transferRequestId to transferRequest
	* @dev [view][mapping]
	* @param transferRequestId {uint256}
	* @return {TransferRequest}
	*/
	function transferRequestId_transferRequest(uint256 transferRequestId)
		external
		view returns (TransferRequest memory)
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
	* @notice Delete transferRequest & all associated values
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [call][internal] {_deleteTransferRequest}
	* @param transferRequestId {uint256}
	* Emits: `DeletedTransferRequest`
	*/
	function deleteTransferRequest(uint256 transferRequestId)
		external
	;

	/**
	* @notice Update transferRequest
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `_transferRequest`
	* @param transferRequestId {uint256}
	* @param __transferRequest {TransferRequest}
	* Emits: `UpdatedTransferRequest`
	*/
	function updateTransferRequest(uint256 transferRequestId, TransferRequest memory __transferRequest)
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
	* @notice Update `transferDelaySeconds`
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `transferDelaySeconds` to new value
	* @param _transferDelaySeconds {uint256}
	* Emits: `UpdatedTransferDelaySeconds`
	*/
	function updateTransferDelaySeconds(uint256 _transferDelaySeconds)
		external
	;


	/**
	* @notice Create a transferRequest
	* @dev [restriction] `YieldSyncV1Record` → member
	* @dev [increment] `_transferRequestId`
	*      [add] `_transferRequest` value
	*      [push-into] `_transferRequestIds`
	* @param forERC20 {bool}
	* @param forERC721 {bool}
	* @param to {address}
	* @param tokenAddress {address} Token contract
	* @param amount {uint256}
	* @param tokenId {uint256} ERC721 token id
	* Emits: `CreatedTransferRequest`
	*/
	function createTransferRequest(
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
	* @notice Vote on transferRequest
	* @dev [restriction] `YieldSyncV1Record` → member
	* @dev [update] `_transferRequest`
	* @param transferRequestId {uint256}
	* @param vote {bool} true (approve) or false (deny)
	* Emits: `TransferRequestReadyToBeProcessed`
	* Emits: `MemberVoted`
	*/
	function voteOnTransferRequest(uint256 transferRequestId, bool vote)
		external
	;

	/**
	* @notice Process transferRequest with given `transferRequestId`
	* @dev [restriction] `YieldSyncV1Record` → member
	* @dev [erc20-transfer]
	*      [decrement] `_tokenBalance`
	*      [call][internal] `_deleteTransferRequest`
	* @param transferRequestId {uint256} Id of the TransferRequest
	* Emits: `TokensTransferred`
	*/
	function processTransferRequest(uint256 transferRequestId)
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
