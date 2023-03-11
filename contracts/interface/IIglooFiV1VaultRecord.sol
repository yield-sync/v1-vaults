// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


/**
* @title ISignatureManager
*/
interface IIglooFiV1VaultRecord
{
	/**
	* @notice
	* @dev [!restriction]
	* @dev [view]
	* @param admin {address}
	* @return {address[]}
	*/
	function admin_iglooFiV1Vaults(address admin)
		external
		view
		returns (address[] memory)
	;

	/**
	* @notice Getter for `_iglooFiV1Vault_admins`
	* @dev [!restriction]
	* @dev [view]
	* @param iglooFiV1Vault {address}
	* @return {address[]}
	*/
	function iglooFiV1Vault_admins(address iglooFiV1Vault)
		external
		view
		returns (address[] memory)
	;

	/**
	* @notice Getter for `_iglooFiV1Vault_members`
	* @dev [!restriction]
	* @dev [view]
	* @param iglooFiV1Vault {address}
	* @return {address[]}
	*/
	function iglooFiV1Vault_members(address iglooFiV1Vault)
		external
		view
		returns (address[] memory)
	;

	/**
	* @notice Getter for `_member_iglooFiV1Vaults`
	* @dev [!restriction]
	* @dev [view]
	* @param member {address}
	* @return {address[]}
	*/
	function member_iglooFiV1Vaults(address member)
		external
		view
		returns (address[] memory)
	;

	/**
	* @notice Getter for `_participant_iglooFiV1Vault_access`
	* @dev [!restriction]
	* @dev [view]
	* @param participant {address}
	* @param iglooFiV1Vault {address}
	* @return admin {bool}
	* @return member {bool}
	*/
	function participant_iglooFiV1Vault_access(address participant, address iglooFiV1Vault)
		external
		view
		returns (bool admin, bool member)
	;


	/**
	* @notice Add Admin
	* @dev [!restriction]
	* @dev [update] `_admin_iglooFiV1Vaults`
	*      [update] `_iglooFiV1Vault_admins`
	*      [update] `participant_iglooFiV1Vault_access`
	* @param _iglooFiV1Vault {address}
	* @param admin {address}
	*/
	function addAdmin(address _iglooFiV1Vault, address admin)
		external
	;

	/**
	* @notice Remove Admin
	* @dev [!restriction]
	* @dev [update] `_admin_iglooFiV1Vaults`
	*      [update] `_iglooFiV1Vault_admins`
	*      [update] `participant_iglooFiV1Vault_access`
	* @param _iglooFiV1Vault {address}
	* @param admin {address}
	*/
	function removeAdmin(address _iglooFiV1Vault, address admin)
		external
	;


	/**
	* @notice Add Member
	* @dev [!restriction]
	* @dev [update] `_member_iglooFiV1Vaults`
	*      [update] `_iglooFiV1Vault_members`
	*      [update] `participant_iglooFiV1Vault_access`
	* @param _iglooFiV1Vault {address}
	* @param member {address}
	*/
	function addMember(address _iglooFiV1Vault, address member)
		external
	;

	/**
	* @notice Remove Member
	* @dev [!restriction]
	* @dev [update] `_member_iglooFiV1Vaults`
	*      [update] `_iglooFiV1Vault_members`
	*      [update] `participant_iglooFiV1Vault_access`
	* @param _iglooFiV1Vault {address}
	* @param member {address}
	*/
	function removeMember(address _iglooFiV1Vault, address member)
		external
	;
}
