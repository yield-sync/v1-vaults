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
}


interface IYieldSyncV1Vault
{
	event TokensTransferred(address indexed to, address indexed token, uint256 amount);
	event UpdatedSignatureManger(address signatureManager);
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
	* @notice SignatureManager Contract Address
	* @dev [view-address]
	* @return {address}
	*/
	function signatureManager()
		external
		view
		returns (address)
	;

	/**
	* @notice YieldSyncV1TransferRequest Contract Address
	* @dev [view-address]
	* @return {address}
	*/
	function yieldSyncV1TransferRequest()
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
	* @notice Update Signature Manager Contract
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `signatureManager`
	* @param _signatureManager {address}
	*/
	function updateSignatureManager(address _signatureManager)
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
