// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { ITransferRequestProtocol, TransferRequest } from "./ITransferRequestProtocol.sol";
import { IYieldSyncV1VaultRegistry } from "./IYieldSyncV1VaultRegistry.sol";


interface IYieldSyncV1Vault
{
	event TokensTransferred(address indexed _to, address indexed _token, uint256 _amount);
	event UpdatedSignatureProtocol(address _signatureProtocol);
	event ProcessTransferRequestFailed(uint256 _transferRequestId);


	receive ()
		external
		payable
	;

	fallback ()
		external
		payable
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
	* @notice Add Admin
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [add] admin on `YieldSyncV1Record`
	* @param _target {address}
	*/
	function adminAdd(address _target)
		external
	;

	/**
	* @notice Remove Admin
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [remove] admin on `YieldSyncV1Record`
	* @param _admin {address}
	*/
	function adminRemove(address _admin)
		external
	;

	/**
	* @notice Add Member
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [add] member `YieldSyncV1Record`
	* @param _target {address}
	*/
	function memberAdd(address _target)
		external
	;

	/**
	* @notice Remove Member
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [remove] member on `YieldSyncV1Record`
	* @param _member {address}
	*/
	function memberRemove(address _member)
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
	* @notice Renounce Membership
	* @dev [restriction] `YieldSyncV1Record` → member
	* @dev [remove] member on `YieldSyncV1Record`
	*/
	function renounceMembership()
		external
	;


	/**
	* @notice Process transferRequest with given `transferRequestId`
	* @dev [restriction] `YieldSyncV1Record` → member
	* @dev [erc20-transfer]
	*      [decrement] `_tokenBalance`
	*      [call][internal] `_yieldSyncV1Vault_transferRequestId_transferRequestDelete`
	* @param _transferRequestId {uint256} Id of the TransferRequest
	* Emits: `TokensTransferred`
	*/
	function yieldSyncV1Vault_transferRequestId_transferRequestProcess(uint256 _transferRequestId)
		external
	;
}
