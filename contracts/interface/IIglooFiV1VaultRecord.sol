// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


/**
* @title ISignatureManager
*/
interface IIglooFiV1VaultRecord
{
	/**
	* @notice IglooFiV1Vault Address to Id
	* @dev [!restriction]
	* @dev [view-mapping]
	* @param iglooFiV1VaultId {address}
	* @return {uint256}
	function iglooFiV1VaultAddressToId(address iglooFiV1VaultId)
		external
		returns (uint256)
	;
	*/

	/**
	* @notice IglooFiV1Vault Id to Address
	* @dev [!restriction]
	* @dev [view-mapping]
	* @param iglooFiV1VaultAddress {address}
	* @return {address}
	function iglooFiV1VaultIdToAddress(uint256 iglooFiV1VaultAddress)
		external
		returns (address)
	;
	*/


	/**
	* @notice iglooFiV1Vault's Voters
	* @dev [!restriction]
	* @dev [view]
	* @param iglooFiV1VaultId {address}
	* @return {address[]}
	*/
	function iglooFiV1VaultVoters(address iglooFiV1VaultId)
		external
		view
		returns (address[] memory)
	;

	/**
	* @notice Voter's IglooFiV1Vaults
	* @dev [!restriction]
	* @dev [view]
	* @param iglooFiV1VaultId {address}
	* @return {address[]}
	*/
	function voterIglooFiV1Vaults(address iglooFiV1VaultId)
		external
		view
		returns (address[] memory)
	;


	/**
	* @notice Add Voter
	* @dev [!restriction]
	* @dev [update] `iglooFiV1VaultVoters`
	*      [update] `voterIglooFiV1Vaults`
	* @param _iglooFiV1VaultAddress {address}
	* @param voter {address}
	*/
	function addVoter(address _iglooFiV1VaultAddress, address voter)
		external
	;

	/**
	* @notice Remove Voter
	* @dev [!restriction]
	* @dev [update] `iglooFiV1VaultVoters`
	*      [update] `voterIglooFiV1Vaults`
	* @param _iglooFiV1VaultAddress {address}
	* @param voter {address}
	*/
	function removeVoter(address _iglooFiV1VaultAddress, address voter)
		external
	;
}