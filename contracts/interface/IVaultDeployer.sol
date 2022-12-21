// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/**
* @title IVaultDeployer
*/
interface IVaultDeployer
{
	/**
	* @notice Emits when a Vault is created and deployed
	* @dev [event]
	*/
	event VaultDeployed (
		address indexed VaultAddress,
		address indexed admin
	);
}