// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { ITransferRequestProtocol, TransferRequest } from "./ITransferRequestProtocol.sol";


struct YieldSyncV1VaultProperty
{
	uint256 againstVoteRequired;
	uint256 forVoteRequired;
	uint256 transferDelaySeconds;
}

struct TransferRequestVote
{
	uint256 againstVoteCount;
	uint256 forVoteCount;
	uint256 latestRelevantForVoteTime;
	address[] votedMembers;
}


interface IYieldSyncV1TransferRequestProtocol is
	ITransferRequestProtocol
{
	event CreatedTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId);
	event DeletedTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId);
	event UpdatedTransferRequest(address yieldSyncV1VaultAddress, TransferRequest transferRequest);
	event UpdatedTransferRequestVote(address yieldSyncV1VaultAddress, TransferRequestVote transferRequestVote);
	event MemberVoted(address yieldSyncV1VaultAddress, uint256 transferRequestId, address indexed member, bool vote);
	event TransferRequestReadyToBeProcessed(address yieldSyncV1VaultAddress, uint256 transferRequestId);


	/**
	* @notice YieldSyncV1VaultAccessControl Contract Address
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
	* @notice Getter for `_yieldSyncV1Vault_openTransferRequestIds`
	* @dev [view][mapping]
	* @param yieldSyncV1VaultAddress {address}
	* @return {uint256[]}
	*/
	function yieldSyncV1Vault_openTransferRequestIds(address yieldSyncV1VaultAddress)
		external
		view
		returns (uint256[] memory)
	;

	/**
	* @notice Getter for `_purposer_yieldSyncV1VaultProperty`
	* @dev [view][mapping]
	* @param purposer {address}
	* @return {YieldSyncV1VaultProperty}
	*/
	function purposer_yieldSyncV1VaultProperty(address purposer)
		external
		returns (YieldSyncV1VaultProperty memory)
	;

	/**
	* @notice Getter for `_yieldSyncV1Vault_yieldSyncV1VaultProperty`
	* @dev [view][mapping]
	* @param yieldSyncV1VaultAddress {address}
	* @return {YieldSyncV1VaultProperty}
	*/
	function yieldSyncV1Vault_yieldSyncV1VaultProperty(address yieldSyncV1VaultAddress)
		external
		returns (YieldSyncV1VaultProperty memory)
	;

	/**
	* @notice Getter for `_yieldSyncV1Vault_transferRequestId_transferRequestVote`
	* @dev [view][mapping]
	* @param yieldSyncV1VaultAddress {address}
	* @param transferRequestId {uint256}
	* @return {TransferRequestVote}
	*/
	function yieldSyncV1Vault_transferRequestId_transferRequestVote(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId
	)
		external
		view returns (TransferRequestVote memory)
	;


	/**
	* @notice Update yieldSyncV1VaultProperty
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `_purposer_yieldSyncV1VaultProperty`
	* @param yieldSyncV1VaultProperty {YieldSyncV1VaultProperty}
	* Emits: `UpdatedPurposerYieldSyncV1VaultProperty`
	*/
	function purposeYieldSyncV1VaultProperty(YieldSyncV1VaultProperty memory yieldSyncV1VaultProperty)
		external
	;

	/**
	* @notice Update transferRequest
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `_transferRequest`
	* @param yieldSyncV1VaultAddress {address}
	* @param transferRequestId {uint256}
	* @param transferRequest {TransferRequest}
	* Emits: `UpdatedTransferRequest`
	*/
	function updateTransferRequest(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId,
		TransferRequest memory transferRequest
	)
		external
	;

	/**
	* @notice Update a TransferRequestVote
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `_transferRequest`
	* @param yieldSyncV1VaultAddress {address}
	* @param transferRequestId {uint256}
	* @param transferRequestVote {TransferRequestVote}
	* Emits: `UpdatedTransferRequestVote`
	*/
	function updateTransferRequestVote(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId,
		TransferRequestVote memory transferRequestVote
	)
		external
	;

	/**
	* @notice Update
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `_updateYieldSyncV1VaultProperty`
	* @param yieldSyncV1VaultAddress {address}
	* @param yieldSyncV1VaultProperty {YieldSyncV1VaultProperty}
	* Emits: `UpdatedYieldSyncV1VaultYieldSyncV1VaultProperty`
	*/
	function updateYieldSyncV1VaultProperty(
		address yieldSyncV1VaultAddress,
		YieldSyncV1VaultProperty memory yieldSyncV1VaultProperty
	)
		external
	;


	/**
	* @notice Create a transferRequest
	* @dev [restriction] `YieldSyncV1Record` → member
	* @dev [add] `_yieldSyncV1Vault_transferRequestId_transferRequest` value
	*      [add] `_yieldSyncV1Vault_transferRequestId_transferRequestVote` value
	*      [push-into] `_yieldSyncV1Vault_openTransferRequestIds`
	*      [increment] `_transferRequestIdTracker`
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

	/**
	* @notice Delete transferRequest & all associated values
	* @dev Utilized by `YieldSyncV1Vault`
	* @param yieldSyncV1VaultAddress {address}
	* @param transferRequestId {uint256}
	*/
	function deleteTransferRequest(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId
	)
		external
	;
}
