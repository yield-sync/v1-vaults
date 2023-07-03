// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


interface IYieldSyncV1VaultFactory
{
	event DeployedYieldSyncV1Vault(address indexed vaultAddress);


	receive ()
		external
		payable
	;


	fallback ()
		external
		payable
	;


	/**
	* @notice YieldSyncGovernance contract address
	* @dev [view-address]
	* @return {address}
	*/
	function YieldSyncGovernance()
		external
		view
		returns (address)
	;

	/**
	* @notice YieldSyncV1VaultAccessControl contract address
	* @dev [view-address]
	* @return {address}
	*/
	function YieldSyncV1VaultAccessControl()
		external
		view
		returns (address)
	;

	/**
	* @notice Default Transfer Request protocol contract address
	* @dev [view-address]
	* @return {address}
	*/
	function transferRequestProtocol()
		external
		view
		returns (address)
	;

	/**
	* @notice Default Signature Protocol contract address
	* @dev [view-address]
	* @return {address}
	*/
	function defaultSignatureProtocol()
		external
		view
		returns (address)
	;

	/**
	* @notice Transfer Ether Locked
	* @dev [view-bool]
	* @return {bool}
	*/
	function transferEtherLocked()
		external
		view
		returns (bool)
	;

	/**
	* @notice Fee
	* @dev [view-uint256]
	* @return {uint256}
	*/
	function fee()
		external
		view
		returns (uint256)
	;

	/**
	* @notice yieldSyncV1Vault Id Tracker
	* @dev [view-uint256]
	* @return {uint256}
	*/
	function yieldSyncV1VaultIdTracker()
		external
		view
		returns (uint256)
	;

	/**
	* @notice yieldSyncV1VaultAddress to yieldSyncV1VaultId
	* @dev [view-mapping]
	* @param yieldSyncV1VaultAddress {address}
	* @return {uint256}
	*/
	function yieldSyncV1VaultAddress_yieldSyncV1VaultId(address yieldSyncV1VaultAddress)
		external
		view
		returns (uint256)
	;

	/**
	* @notice yieldSyncV1VaultId to yieldSyncV1VaultAddress
	* @dev [view-mapping]
	* @param yieldSyncV1VaultId {uint256}
	* @return {address}
	*/
	function yieldSyncV1VaultId_yieldSyncV1VaultAddress(uint256 yieldSyncV1VaultId)
		external
		view
		returns (address)
	;

	/**
	* @notice Deploy a YieldSyncV1Vault contract
	* @dev [create]
	* @param admins {address[]}
	* @param members {address[]}
	* @param signatureProtocol {address}
	* @param transferRequest {uint256}
	* @param useDefaultTransferRequestProtocol {uint256}
	* @param useDefaultSignatureProtocol {uint256}
	* @return {address} Deployed vault
	*/
	function deployYieldSyncV1Vault(
		address[] memory admins,
		address[] memory members,
		address signatureProtocol,
		address transferRequest,
		bool useDefaultTransferRequestProtocol,
		bool useDefaultSignatureProtocol
	)
		external
		payable
		returns (address)
	;

	/**
	* @notice Updates Default Signature Protocol
	* @dev [restriction] `IYieldSyncGovernance` AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [update] `defaultSignatureProtocol`
	* @param _defaultSignatureProtocol {address}
	*/
	function updateDefaultSignatureProtocol(address _defaultSignatureProtocol)
		external
	;

	/**
	* @notice Update fee
	* @dev [restriction] `IYieldSyncGovernance` AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [update] `fee`
	* @param _fee {uint256}
	*/
	function updateFee(uint256 _fee)
		external
	;

	/**
	* @notice Transfer Ether to
	* @dev [restriction] `IYieldSyncGovernance` AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [transfer]
	* @param to {uint256}
	*/
	function transferEther(address to)
		external
	;
}
