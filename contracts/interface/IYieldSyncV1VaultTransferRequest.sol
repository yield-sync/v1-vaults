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


interface IYieldSyncV1VaultTransferRequest
{
	event CreatedTransferRequest(uint256 transferRequestId);
	event DeletedTransferRequest(uint256 transferRequestId);
	event TokensTransferred(address indexed to, address indexed token, uint256 amount);
	event UpdatedAgainstVoteCountRequired(uint256 againstVoteCountRequired);
	event UpdatedForVoteCountRequired(uint256 forVoteCountRequired);
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
	* @notice Process TransferRequest Locked
	* @dev [!restriction]
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
	* @notice Transfer Delay In Seconds
	* @dev [!restriction]
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
	* @dev [!restriction]
	* @dev [view-uint256[]]
	* @return {uint256[]}
	*/
	function yieldSyncV1Vault_idsOfOpenTransferRequests(address yieldSyncV1VaultAddress)
		external
		view
		returns (uint256[] memory)
	;

	/**
	* @notice transferRequestId to transferRequest
	* @dev [!restriction]
	* @dev [view][mapping]
	* @param transferRequestId {uint256}
	* @return {TransferRequest}
	*/
	function vaultTransferRequestById(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId
	)
		external
		view returns (TransferRequest memory)
	;

	/**
	* @notice Delete transferRequest & all associated values
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [call][internal] {_deleteTransferRequest}
	* @param transferRequestId {uint256}
	* Emits: `DeletedTransferRequest`
	*/
	function deleteTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId)
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
	function updateTransferRequest(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId,
		TransferRequest memory __transferRequest
	)
		external
	;

	/**
	* @notice Update Against Vote Count Required
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `againstVoteCountRequired`
	* @param _againstVoteCountRequired {uint256}
	* Emits: `UpdatedAgainstVoteCountRequired`
	*/
	function updateAgainstVoteCountRequired(address yieldSyncV1VaultAddress, uint256 _againstVoteCountRequired)
		external
	;

	/**
	* @notice Update For Vote Count Required
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `forVoteCountRequired`
	* @param _forVoteCountRequired {uint256}
	* Emits: `UpdatedRequiredVoteCount`
	*/
	function updateForVoteCountRequired(address yieldSyncV1VaultAddress,  uint256 _forVoteCountRequired)
		external
	;

	/**
	* @notice Update `transferDelaySeconds`
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `transferDelaySeconds` to new value
	* @param _transferDelaySeconds {uint256}
	* Emits: `UpdatedTransferDelaySeconds`
	*/
	function updateTransferDelaySeconds(address yieldSyncV1VaultAddress, uint256 _transferDelaySeconds)
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
		address yieldSyncV1VaultAddress,
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
	function voteOnTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId, bool vote)
		external
	;

	/**
	* @notice Transfer Request Ready to Be Processed
	*/
	function transferRequestStatus(address yieldSyncV1VaultAddress, uint256 transferRequestId)
		external
		view
		returns (bool, bool, string memory)
	;
}
