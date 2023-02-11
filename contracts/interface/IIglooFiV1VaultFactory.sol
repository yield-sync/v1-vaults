// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/**
* @title IIglooFiV1VaultFactory
*/
interface IIglooFiV1VaultFactory {
	/* [event] */
	/**
	* @dev Emits when a vault is deployed
	*/
	event VaultDeployed(
		address indexed VaultAddress
	);

	/**
	* @dev Emits when a `fee` is updated
	*/
	event UpdatedFee(
		uint256 fee
	);


	/**
	* @notice CONSTANT Address of Igloo Fi Governance contract
	* @dev [!restriction]
	* @dev [view-address]
	* @return {address}
	*/
	function IGLOO_FI_GOVERNANCE()
		external
		view
		returns (address)
	;

	/**
	* @notice CONSTANT Address of Igloo Fi V1 Vaults Multi Signed Messages
	* @dev [!restriction]
	* @dev [view-address]
	* @return {address}
	*/
	function IGLOO_FI_V1_VAULTS_MULTI_SIGNED_MESSAGES()
		external
		view
		returns (address)
	;

	/**
	* @notice Get vault deployment fee
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
	* @notice Get vault address
	* @dev [!restriction]
	* @dev [view]
	* @param vaultId {uint256}
	* @return {address}
	*/
	function vaultAddress(uint256 vaultId)
		external
		view
		returns (address)
	;

	/**
	* @notice Creates a Vault
	* @dev [!restriction]
	* @dev [create]
	* @param _admin {address}
	* @param _signatureManager {address}
	* @param _requiredVoteCount {uint256}
	* @param _withdrawalDelaySeconds {uint256}
	* @return {address} Deployed vault
	*/
	function deployVault(
		address _admin,
		address _signatureManager,
		uint256 _requiredVoteCount,
		uint256 _withdrawalDelaySeconds
	)
		external
		payable
		returns (address)
	;

	/**
	* @notice Set pause
	* @dev [restriction] IIglooFiGovernance AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [call-internal]
	* @param pause {bool}
	*/
	function setPause(bool pause)
		external
	;

	/**
	* @notice Update fee
	* @dev [restriction] IIglooFiGovernance AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [update] `_fee`
	* @param newFee {uint256}
	*/
	function updateFee(uint256 newFee)
		external
	;

	/**
	* @notice Transfer Ether to the treasury
	* @dev [restriction] IIglooFiGovernance AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [transfer] to `treasury`
	* @param transferTo {uint256}
	*/
	function transferFunds(address transferTo)
		external
	;
}