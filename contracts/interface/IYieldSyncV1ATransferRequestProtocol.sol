// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { ITransferRequestProtocol, TransferRequest } from "./ITransferRequestProtocol.sol";


struct YieldSyncV1VaultProperty
{
	uint256 againstVoteRequired;
	uint256 forVoteRequired;
	uint256 transferDelaySeconds;
}

struct TransferRequestPoll
{
	uint256 againstVoteCount;
	uint256 forVoteCount;
	uint256 latestRelevantForVoteTime;
	address[] votedMembers;
}


interface IYieldSyncV1ATransferRequestProtocol is
	ITransferRequestProtocol
{
	event CreatedTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId);
	event DeletedTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId);
	event UpdatedTransferRequest(address yieldSyncV1VaultAddress, TransferRequest transferRequest);
	event UpdatedTransferRequestPoll(address yieldSyncV1VaultAddress, TransferRequestPoll transferRequestPoll);
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
	* @notice Getter for `_yieldSyncV1VaultAddress_openTransferRequestIds`
	* @dev [view][mapping]
	* @param yieldSyncV1VaultAddress {address}
	* @return {uint256[]}
	*/
	function yieldSyncV1VaultAddress_openTransferRequestIds(address yieldSyncV1VaultAddress)
		external
		view
		returns (uint256[] memory)
	;

	/**
	* @notice Getter for `_yieldSyncV1VaultAddress_yieldSyncV1VaultProperty`
	* @dev [view][mapping]
	* @param yieldSyncV1VaultAddress {address}
	* @return {YieldSyncV1VaultProperty}
	*/
	function yieldSyncV1VaultAddress_yieldSyncV1VaultProperty(address yieldSyncV1VaultAddress)
		external
		returns (YieldSyncV1VaultProperty memory)
	;

	/**
	* @notice Getter for `_yieldSyncV1VaultAddress_transferRequestId_transferRequestPoll`
	* @dev [view][mapping]
	* @param yieldSyncV1VaultAddress {address}
	* @param transferRequestId {uint256}
	* @return {TransferRequestPoll}
	*/
	function yieldSyncV1VaultAddress_transferRequestId_transferRequestPoll(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId
	)
		external
		view returns (TransferRequestPoll memory)
	;


	/**
	* @notice Create a transferRequest
	* @dev [restriction] `YieldSyncV1Record` → member
	* @dev [add] `_yieldSyncV1VaultAddress_transferRequestId_transferRequest` value
	*      [add] `_yieldSyncV1VaultAddress_transferRequestId_transferRequestPoll` value
	*      [push-into] `_yieldSyncV1VaultAddress_openTransferRequestIds`
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
	function yieldSyncV1VaultAddress_transferRequestId_transferRequestCreate(
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
	* @notice Delete transferRequest & all associated values
	* @dev Utilized by `YieldSyncV1Vault`
	* @param yieldSyncV1VaultAddress {address}
	* @param transferRequestId {uint256}
	*/
	function yieldSyncV1VaultAddress_transferRequestId_transferRequestDelete(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId
	)
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
	function yieldSyncV1VaultAddress_transferRequestId_transferRequestUpdate(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId,
		TransferRequest memory transferRequest
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
	function yieldSyncV1VaultAddress_transferRequestId_transferRequestPollVote(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId,
		bool vote
	)
		external
	;

	/**
	* @notice Update a TransferRequestPoll
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `_transferRequest`
	* @param yieldSyncV1VaultAddress {address}
	* @param transferRequestId {uint256}
	* @param transferRequestPoll {TransferRequestPoll}
	* Emits: `UpdatedTransferRequestPoll`
	*/
	function yieldSyncV1VaultAddress_transferRequestId_transferRequestPollUpdate(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId,
		TransferRequestPoll memory transferRequestPoll
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
	function yieldSyncV1VaultAddress_yieldSyncV1VaultPropertyUpdate(
		address yieldSyncV1VaultAddress,
		YieldSyncV1VaultProperty memory yieldSyncV1VaultProperty
	)
		external
	;
}
