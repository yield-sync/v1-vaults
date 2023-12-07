// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


interface IYieldSyncV1VaultDeployer
{
	event DeployedYieldSyncV1Vault(address indexed yieldSyncV1Vault);


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
	* @return yieldSyncGovernance_ {address}
	*/
	function YieldSyncGovernance()
		external
		view
		returns (address yieldSyncGovernance_)
	;

	/**
	* @notice YieldSyncV1VaultRegistry contract address
	* @dev [view-address]
	* @return yieldSyncV1VaultRegistry_ {address}
	*/
	function YieldSyncV1VaultRegistry()
		external
		view
		returns (address yieldSyncV1VaultRegistry_)
	;

	/**
	* @notice Fee
	* @dev [view-uint256]
	* @return fee_ {uint256}
	*/
	function fee()
		external
		view
		returns (uint256 fee_)
	;

	/**
	* @notice yieldSyncV1Vault Id Tracker
	* @dev [view-uint256]
	* @return yieldSyncV1VaultIdTracker_ {uint256}
	*/
	function yieldSyncV1VaultIdTracker()
		external
		view
		returns (uint256 yieldSyncV1VaultIdTracker_)
	;

	/**
	* @notice yieldSyncV1Vault to yieldSyncV1VaultId
	* @dev [view-mapping]
	* @param _yieldSyncV1Vault {address}
	* @return yieldSyncV1VaultId_ {uint256}
	*/
	function yieldSyncV1Vault_yieldSyncV1VaultId(address _yieldSyncV1Vault)
		external
		view
		returns (uint256 yieldSyncV1VaultId_)
	;

	/**
	* @notice yieldSyncV1VaultId to yieldSyncV1Vault
	* @dev [view-mapping]
	* @param _yieldSyncV1VaultId {uint256}
	* @return yieldSyncV1Vault_ {address}
	*/
	function yieldSyncV1VaultId_yieldSyncV1Vault(uint256 _yieldSyncV1VaultId)
		external
		view
		returns (address yieldSyncV1Vault_)
	;

	/**
	* @notice Deploy a YieldSyncV1Vault contract
	* @dev [create]
	* @param _signatureProtocol {address}
	* @param _transferRequestProtocol {uint256}
	* @param _admins {address[]}
	* @param _members {address[]}
	* @return yieldSyncV1Vault_ {address} Deployed yieldSyncV1Vault
	*/
	function deployYieldSyncV1Vault(
		address _signatureProtocol,
		address _transferRequestProtocol,
		address[] memory _admins,
		address[] memory _members
	)
		external
		payable
		returns (address yieldSyncV1Vault_)
	;

	/**
	* @notice Transfer Ether to
	* @dev [restriction] `IYieldSyncGovernance` AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [transfer]
	* @param _to {uint256}
	*/
	function etherTransfer(address _to)
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
