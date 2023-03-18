// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


/**
* @title IYieldSyncV1VaultFactory
*/
interface IYieldSyncV1VaultFactory {
	event DeployedYieldSyncV1Vault(address indexed vaultAddress);
	event UpdatedDefaultSignatureManager(address defaultSignatureManager);
	event UpdatedFee(uint256 fee);


	receive ()
		external
		payable
	;


	fallback ()
		external
		payable
	;


	/**
	* @notice YieldSyncGovernance Contract Address
	* @dev [!restriction]
	* @dev [view-address]
	* @return {address}
	*/
	function YieldSyncGovernance()
		external
		view
		returns (address)
	;

	/**
	* @notice YieldSyncV1VaultRecord Contract Address
	* @dev [!restriction]
	* @dev [view-address]
	* @return {address}
	*/
	function YieldSyncV1VaultRecord()
		external
		view
		returns (address)
	;

	/**
	* @notice Default SignatureManager Contract Address
	* @dev [!restriction]
	* @dev [view-address]
	* @return {address}
	*/
	function defaultSignatureManager()
		external
		view
		returns (address)
	;


	/**
	* @notice Fee
	* @dev [!restriction]
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
	* @dev [!restriction]
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
	* @dev [!restriction]
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
	* @dev [!restriction]
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
	* @notice Creates a Vault
	* @dev [!restriction]
	* @dev [create]
	* @param admins {address[]}
	* @param members {address[]}
	* @param signatureManager {address}
	* @param againstVoteCountRequired {uint256}
	* @param forVoteCountRequired {uint256}
	* @param withdrawalDelaySeconds {uint256}
	* @return {address} Deployed vault
	*/
	function deployYieldSyncV1Vault(
		address[] memory admins,
		address[] memory members,
		address signatureManager,
		bool useDefaultSignatureManager,
		uint256 againstVoteCountRequired,
		uint256 forVoteCountRequired,
		uint256 withdrawalDelaySeconds
	)
		external
		payable
		returns (address)
	;

	/**
	* @notice Updates default signature manager
	* @dev [restriction] `IYieldSyncGovernance` AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [update] `defaultSignatureManager`
	* @param _defaultSignatureManager {address}
	*/
	function updateDefaultSignatureManager(address _defaultSignatureManager)
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
