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
	* @dev Emits when a `treasury` is updated
	*/
	event UpdatedTreasury(
		address treasury
	);


	/**
	* @notice CONSTANT Address of Igloo Fi Governance contract
	*
	* @dev [!restriction]
	* @dev [view-address]
	*
	* @return {address}
	*/
	function IGLOO_FI()
		external
		view
		returns (address)
	;
	
	/**
	* @notice Address of treasury
	*
	* @dev [!restriction]
	* @dev [view-address]
	*
	* @return {address}
	*/
	function treasury()
		external
		view
		returns (address)
	;

	/**
	* @notice Get vault deployment fee
	*
	* @dev [!restriction]
	* @dev [view-uint256]
	*
	* @return {uint256}
	*/
	function fee()
		external
		view
		returns (uint256)
	;

	/**
	* @notice Get vault address
	*
	* @dev [!restriction]
	* @dev [view]
	*
	* @param vaultId {uint256}
	*
	* @return {uint256}
	*/
	function vaultAddress(uint256 vaultId)
		external
		view
		returns (address)
	;

	/**
	* @notice Creates a Vault
	*
	* @dev [!restriction]
	* @dev [create]
	*
	* @param admin {address}
	* @param requiredApproveVotes {uint256}
	* @param withdrawalDelaySeconds {uint256}
	*/
	function deployVault(
		address admin,
		uint256 requiredApproveVotes,
		uint256 withdrawalDelaySeconds
	)
		external
		payable
		returns (address)
	;

	/**
	* @notice Toggle pause
	*
	* @dev [restriction] IIglooFiGovernance AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [call-internal]
	*/
	function togglePause()
		external
	;

	/**
	* @notice Update fee
	*
	* @dev [restriction] IIglooFiGovernance AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [update] `_fee`
	*
	* @param newFee {uint256}
	*/
	function updateFee(uint256 newFee)
		external
		returns (uint256)
	;

	/**
	* @notice Update treasury
	*
	* @dev [restriction] IIglooFiGovernance AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [update] `treasury`
	*
	* @param _treasury {address}
	*/
	function updateTreasury(address _treasury)
		external
		returns (address)
	;

	/**
	* @notice Transfer Ether to the treasury
	*
	* @dev [restriction] IIglooFiGovernance AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [transfer] to `treasury`
	*/
	function transferFunds()
		external
	;
}