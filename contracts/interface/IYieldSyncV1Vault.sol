// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { ITransferRequestProtocol, TransferRequest } from "./ITransferRequestProtocol.sol";


interface IYieldSyncV1Vault
{
	event TokensTransferred(address indexed to, address indexed token, uint256 amount);
	event UpdatedSignatureProtocol(address signatureProtocol);
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
	* @notice SignatureProtocol Contract Address
	* @dev [view-address]
	* @return {address}
	*/
	function signatureProtocol()
		external
		view
		returns (address)
	;

	/**
	* @notice transferRequestProtocol Contract Address
	* @dev [view-address]
	* @return {address}
	*/
	function transferRequestProtocol()
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
	* @notice Add Admin
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [add] admin on `YieldSyncV1Record`
	* @param targetAddress {address}
	*/
	function adminAdd(address targetAddress)
		external
	;

	/**
	* @notice Remove Admin
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [remove] admin on `YieldSyncV1Record`
	* @param admin {address}
	*/
	function adminRemove(address admin)
		external
	;

	/**
	* @notice Add Member
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [add] member `YieldSyncV1Record`
	* @param targetAddress {address}
	*/
	function memberAdd(address targetAddress)
		external
	;

	/**
	* @notice Remove Member
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [remove] member on `YieldSyncV1Record`
	* @param member {address}
	*/
	function memberRemove(address member)
		external
	;

	/**
	* @notice Update Signature Protocol Contract
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `signatureProtocol`
	* @param _signatureProtocol {address}
	*/
	function signatureProtocolUpdate(address _signatureProtocol)
		external
	;

	/**
	* @notice Update TransferRequest Protocol Contract
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `transferRequestProtocol`
	* @param _transferRequestProtocol {address}
	*/
	function transferRequestProtocolUpdate(address _transferRequestProtocol)
		external
	;


	/**
	* @notice Process transferRequest with given `transferRequestId`
	* @dev [restriction] `YieldSyncV1Record` → member
	* @dev [erc20-transfer]
	*      [decrement] `_tokenBalance`
	*      [call][internal] `_yieldSyncV1VaultAddress_transferRequestId_transferRequestDelete`
	* @param transferRequestId {uint256} Id of the TransferRequest
	* Emits: `TokensTransferred`
	*/
	function yieldSyncV1VaultAddress_transferRequestId_transferRequestProcess(uint256 transferRequestId)
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
