// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { TransferRequest } from "./IYieldSyncV1Vault.sol";


struct TransferRequestVote {
	uint256 forVoteCount;
	uint256 againstVoteCount;
	uint256 latestRelevantForVoteTime;
	address[] votedMembers;
}


interface IYieldSyncV1VaultTransferRequest
{
	event CreatedTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId);
	event DeletedTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId);
	event UpdatedAgainstVoteCountRequired(address yieldSyncV1VaultAddress, uint256 againstVoteCountRequired);
	event UpdatedForVoteCountRequired(address yieldSyncV1VaultAddress, uint256 forVoteCountRequired);
	event UpdatedTransferDelaySeconds(address yieldSyncV1VaultAddress, uint256 transferDelaySeconds);
	event UpdatedTransferRequest(address yieldSyncV1VaultAddress, TransferRequest transferRequest);
	event MemberVoted(address yieldSyncV1VaultAddress, uint256 transferRequestId, address indexed member, bool vote);
	event TransferRequestReadyToBeProcessed(address yieldSyncV1VaultAddress, uint256 transferRequestId);


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
	* @notice YieldSyncV1VaultFactory Contract Address
	* @dev [view-address]
	* @return {address}
	*/
	function YieldSyncV1VaultFactory()
		external
		view
		returns (address)
	;


	/**
	* @notice Against Vote Count Required
	* @dev [view][mapping]
	* @param yieldSyncV1VaultAddress {address}
	* @return {uint256}
	*/
	function yieldSyncV1Vault_againstVoteCountRequired(address yieldSyncV1VaultAddress)
		external
		view
		returns (uint256)
	;

	/**
	* @notice For Vote Count Required
	* @dev [view][mapping]
	* @param yieldSyncV1VaultAddress {address}
	* @return {uint256}
	*/
	function yieldSyncV1Vault_forVoteCountRequired(address yieldSyncV1VaultAddress)
		external
		view
		returns (uint256)
	;

	/**
	* @notice Transfer Delay Seconds
	* @dev [view][mapping]
	* @param yieldSyncV1VaultAddress {address}
	* @return {uint256}
	*/
	function yieldSyncV1Vault_transferDelaySeconds(address yieldSyncV1VaultAddress)
		external
		view
		returns (uint256)
	;

	/**
	* @notice Ids of Open transferRequests
	* @dev [view][mapping]
	* @param yieldSyncV1VaultAddress {address}
	* @return {uint256[]}
	*/
	function yieldSyncV1Vault_idsOfOpenTransferRequests(address yieldSyncV1VaultAddress)
		external
		view
		returns (uint256[] memory)
	;

	/**
	* @notice transferRequestId to transferRequest
	* @dev [view][mapping]
	* @param yieldSyncV1VaultAddress {address}
	* @param transferRequestId {uint256}
	* @return {TransferRequest}
	*/
	function yieldSyncV1Vault_transferRequestId_transferRequest(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId
	)
		external
		view returns (TransferRequest memory)
	;

	/**
	* @notice Transfer Request Ready to Be Processed
	* @dev [view]
	* @param yieldSyncV1VaultAddress {address}
	* @param transferRequestId {uint256}
	* @return readyToBeProcessed {bool}
	* @return approved {bool}
	* @return message {string}
	*/
	function transferRequestStatus(address yieldSyncV1VaultAddress, uint256 transferRequestId)
		external
		view
		returns (bool readyToBeProcessed, bool approved, string memory message)
	;


	/**
	* @notice Delete transferRequest & all associated values
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [call][internal] `_deleteTransferRequest`
	* @param yieldSyncV1VaultAddress {address}
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
	* @param yieldSyncV1VaultAddress {address}
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
	* @param yieldSyncV1VaultAddress {address}
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
	* @param yieldSyncV1VaultAddress {address}
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
	* @param yieldSyncV1VaultAddress {address}
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
	* @param yieldSyncV1VaultAddress {address}
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
	* @param yieldSyncV1VaultAddress {address}
	* @param transferRequestId {uint256}
	* @param vote {bool} true (approve) or false (deny)
	* Emits: `TransferRequestReadyToBeProcessed`
	* Emits: `MemberVoted`
	*/
	function voteOnTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId, bool vote)
		external
	;
}
