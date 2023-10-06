// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


interface IYieldSyncV1VaultDeployer
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
	* @notice YieldSyncV1VaultRegistry contract address
	* @dev [view-address]
	* @return {address}
	*/
	function YieldSyncV1VaultRegistry()
		external
		view
		returns (address)
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
	* @notice yieldSyncV1Vault to yieldSyncV1VaultId
	* @dev [view-mapping]
	* @param yieldSyncV1Vault {address}
	* @return {uint256}
	*/
	function yieldSyncV1Vault_yieldSyncV1VaultId(address yieldSyncV1Vault)
		external
		view
		returns (uint256)
	;

	/**
	* @notice yieldSyncV1VaultId to yieldSyncV1Vault
	* @dev [view-mapping]
	* @param yieldSyncV1VaultId {uint256}
	* @return {address}
	*/
	function yieldSyncV1VaultId_yieldSyncV1Vault(uint256 yieldSyncV1VaultId)
		external
		view
		returns (address)
	;

	/**
	* @notice Deploy a YieldSyncV1Vault contract
	* @dev [create]
	* @param signatureProtocol {address}
	* @param transferRequestProtocol {uint256}
	* @param admins {address[]}
	* @param members {address[]}
	* @return deployedYieldSyncV1Vault {address} Deployed vault
	*/
	function deployYieldSyncV1Vault(
		address signatureProtocol,
		address transferRequestProtocol,
		address[] memory admins,
		address[] memory members
	)
		external
		payable
		returns (address deployedYieldSyncV1Vault)
	;

	/**
	* @notice Transfer Ether to
	* @dev [restriction] `IYieldSyncGovernance` AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [transfer]
	* @param to {uint256}
	*/
	function etherTransfer(address to)
		external
	;

	/**
	* @notice Update fee
	* @dev [restriction] `IYieldSyncGovernance` AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [update] `fee`
	* @param _fee {uint256}
	*/
	function feeUpdate(uint256 _fee)
		external
	;
}
