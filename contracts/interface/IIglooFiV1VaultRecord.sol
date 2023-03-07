// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


/**
* @title ISignatureManager
*/
interface IIglooFiV1VaultRecord
{
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