// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/**
* @title IVaultFactory
*/
interface IVaultFactory
{
	/**
	* @notice
	* @dev [event]
	*/
	event VaultDeployed (
		address indexed VaultAddress,
		address indexed admin
	);
}