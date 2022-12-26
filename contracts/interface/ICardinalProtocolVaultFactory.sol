// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/**
* @title ICardinalProtocolVaultFactory
*/
interface ICardinalProtocolVaultFactory
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