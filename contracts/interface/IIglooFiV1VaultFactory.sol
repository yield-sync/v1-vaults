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
	* @dev [view]
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
	* @param requiredApproveVotes {uint256}
	* @param withdrawalDelayMinutes {uint256}
	* @param voters {address[]} Addresses to be assigned VOTER_ROLE
	*/
	function deployVault(
		address admin,
		address[] memory voters,
		uint256 requiredApproveVotes,
		uint256 withdrawalDelayMinutes,
		string memory name
	)
		external
		payable
		returns (address)
	;

	/**
	* @notice Toggle pause
	*
	* @dev [restriction] AccessControlEnumerable → S
	* @dev [call-internal]
	*/
	function togglePause()
		external
	;

	/**
	* @notice Update fee
	*
	* @dev [restriction] AccessControlEnumerable → S
	* @dev [update] `_fee`
	*
	* @param newFee {uint256}
	*/
	function updateFee(uint256 newFee)
		external
	;

	/**
	* @notice Update treasury
	*
	* @dev [restriction] AccessControlEnumerable → S
	* @dev [update] `treasury`
	*
	* @param _treasury {address}
	*/
	function updateTreasury(address _treasury)
		external
	;

	/**
	* @notice Transfer Ether to the treasury
	*
	* @dev [restriction] AccessControlEnumerable → S
	* @dev [transfer] to treasury
	*/
	function transferFunds()
		external
	;
}