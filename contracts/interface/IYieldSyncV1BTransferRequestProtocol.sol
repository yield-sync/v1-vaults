// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { ITransferRequestProtocol, TransferRequest } from "./ITransferRequestProtocol.sol";
import { IYieldSyncV1VaultRegistry } from "./IYieldSyncV1VaultRegistry.sol";


struct YieldSyncV1VaultProperty
{
	uint256 voteAgainstRequired;
	uint256 voteForRequired;
	uint256 maxVotePeriodSeconds;
	uint256 minVotePeriodSeconds;
}

struct TransferRequestPoll
{
	uint256 voteCloseTimestamp;
	address[] voteAgainstMembers;
	address[] voteForMembers;
}


interface IYieldSyncV1BTransferRequestProtocol is
	ITransferRequestProtocol
{
	event CreatedTransferRequest(address _yieldSyncV1Vault, uint256 _transferRequestId);
	event DeletedTransferRequest(address _yieldSyncV1Vault, uint256 _transferRequestId);
	event UpdateTransferRequest(address _yieldSyncV1Vault, TransferRequest _transferRequest);
	event UpdateTransferRequestPoll(address _yieldSyncV1Vault, TransferRequestPoll _transferRequestPoll);
	event MemberVoted(address _yieldSyncV1Vault, uint256 _transferRequestId, address member, bool _vote);


	/**
	* @notice YieldSyncV1VaultRegistry Interfaced
	* @dev [view-address]
	* @return {IYieldSyncV1VaultRegistry}
	*/
	function YieldSyncV1VaultRegistry()
		external
		view
		returns (IYieldSyncV1VaultRegistry)
	;


	/**
	* @notice Getter for `_yieldSyncV1Vault_openTransferRequestIds`
	* @dev [view][mapping]
	* @param _yieldSyncV1Vault {address}
	* @return openTransferRequestIds_ {uint256[]}
	*/
	function yieldSyncV1Vault_openTransferRequestIds(address _yieldSyncV1Vault)
		external
		view
		returns (uint256[] memory openTransferRequestIds_)
	;

	/**
	* @notice Getter for `_yieldSyncV1Vault_yieldSyncV1VaultProperty`
	* @dev [view][mapping]
	* @param _yieldSyncV1Vault {address}
	* @return yieldSyncV1VaultProperty_ {YieldSyncV1VaultProperty}
	*/
	function yieldSyncV1Vault_yieldSyncV1VaultProperty(address _yieldSyncV1Vault)
		external
		returns (YieldSyncV1VaultProperty memory yieldSyncV1VaultProperty_)
	;

	/**
	* @notice Getter for `_yieldSyncV1Vault_transferRequestId_transferRequestPoll`
	* @dev [view][mapping]
	* @param _yieldSyncV1Vault {address}
	* @param _transferRequestId {uint256}
	* @return transferRequestPoll_ {TransferRequestPoll}
	*/
	function yieldSyncV1Vault_transferRequestId_transferRequestPoll(
		address _yieldSyncV1Vault,
		uint256 _transferRequestId
	)
		external
		view
		returns (TransferRequestPoll memory transferRequestPoll_)
	;


	/**
	* @notice Delete transferRequest & all associated values
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev Utilized by `YieldSyncV1Vault`
	* @param _yieldSyncV1Vault {address}
	* @param _transferRequestId {uint256}
	*/
	function yieldSyncV1Vault_transferRequestId_transferRequestAdminDelete(
		address _yieldSyncV1Vault,
		uint256 _transferRequestId
	)
		external
	;

	/**
	* @notice Update transferRequest
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `_transferRequest`
	* @param _yieldSyncV1Vault {address}
	* @param _transferRequestId {uint256}
	* @param _transferRequest {TransferRequest}
	* Emits: `UpdateTransferRequest`
	*/
	function yieldSyncV1Vault_transferRequestId_transferRequestAdminUpdate(
		address _yieldSyncV1Vault,
		uint256 _transferRequestId,
		TransferRequest memory _transferRequest
	)
		external
	;

	/**
	* @notice Create a transferRequest
	* @dev [restriction] `YieldSyncV1Record` → member
	* @dev [add] `_yieldSyncV1Vault_transferRequestId_transferRequest` value
	*      [add] `_yieldSyncV1Vault_transferRequestId_transferRequestPoll` value
	*      [push-into] `_yieldSyncV1Vault_openTransferRequestIds`
	*      [increment] `_transferRequestIdTracker`
	* @param _yieldSyncV1Vault {address}
	* @param _forERC20 {bool}
	* @param _forERC721 {bool}
	* @param _to {address}
	* @param _token {address} Token contract
	* @param _amount {uint256}
	* @param _tokenId {uint256} ERC721 token id
	* Emits: `CreatedTransferRequest`
	*/
	function yieldSyncV1Vault_transferRequestId_transferRequestCreate(
		address _yieldSyncV1Vault,
		bool _forERC20,
		bool _forERC721,
		address _to,
		address _token,
		uint256 _amount,
		uint256 _tokenId,
		uint256 _voteCloseTimestamp
	)
		external
	;

	/**
	* @notice Delete transferRequest & all associated values
	* @dev [restriction] `YieldSyncV1Record` → member
	* @dev Utilized by `YieldSyncV1Vault`
	* @param _yieldSyncV1Vault {address}
	* @param _transferRequestId {uint256}
	*/
	function yieldSyncV1Vault_transferRequestId_transferRequestDelete(
		address _yieldSyncV1Vault,
		uint256 _transferRequestId
	)
		external
	;

	/**
	* @notice Update a TransferRequestPoll
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `_transferRequest`
	* @param _yieldSyncV1Vault {address}
	* @param _transferRequestId {uint256}
	* @param _transferRequestPoll {TransferRequestPoll}
	* Emits: `UpdateTransferRequestPoll`
	*/
	function yieldSyncV1Vault_transferRequestId_transferRequestPollAdminUpdate(
		address _yieldSyncV1Vault,
		uint256 _transferRequestId,
		TransferRequestPoll memory _transferRequestPoll
	)
		external
	;

	/**
	* @notice Vote on transferRequest
	* @dev [restriction] `YieldSyncV1Record` → member
	* @dev [update] `_transferRequest`
	* @param _yieldSyncV1Vault {address}
	* @param _transferRequestId {uint256}
	* @param _vote {bool} true (approve) or false (deny)
	* Emits: `TransferRequestReadyToBeProcessed`
	* Emits: `MemberVoted`
	*/
	function yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
		address _yieldSyncV1Vault,
		uint256 _transferRequestId,
		bool _vote
	)
		external
	;

	/**
	* @notice Update
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `_updateYieldSyncV1VaultProperty`
	* @param _yieldSyncV1Vault {address}
	* @param _yieldSyncV1VaultProperty {YieldSyncV1VaultProperty}
	* Emits: `UpdatedYieldSyncV1VaultYieldSyncV1VaultProperty`
	*/
	function yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
		address _yieldSyncV1Vault,
		YieldSyncV1VaultProperty memory _yieldSyncV1VaultProperty
	)
		external
	;
}
