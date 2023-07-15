// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


interface IYieldSyncV1VaultAccessControl
{
	/**
	* @notice Getter for `_admin_yieldSyncV1VaultsAddresses`
	* @dev [view]
	* @param admin {address}
	* @return {address[]}
	*/
	function admin_yieldSyncV1VaultsAddresses(address admin)
		external
		view
		returns (address[] memory)
	;

	/**
	* @notice Getter for `_member_yieldSyncV1VaultsAddresses`
	* @dev [view]
	* @param member {address}
	* @return {address[]}
	*/
	function member_yieldSyncV1VaultsAddresses(address member)
		external
		view
		returns (address[] memory)
	;

	/**
	* @notice Getter for `_yieldSyncV1VaultAddress_admins`
	* @dev [view]
	* @param yieldSyncV1VaultAddress {address}
	* @return {address[]}
	*/
	function yieldSyncV1VaultAddress_admins(address yieldSyncV1VaultAddress)
		external
		view
		returns (address[] memory)
	;

	/**
	* @notice Getter for `_yieldSyncV1VaultAddress_members`
	* @dev [view]
	* @param yieldSyncV1VaultAddress {address}
	* @return {address[]}
	*/
	function yieldSyncV1VaultAddress_members(address yieldSyncV1VaultAddress)
		external
		view
		returns (address[] memory)
	;

	/**
	* @notice Getter for `_yieldSyncV1VaultAddress_participant_access`
	* @dev [view]
	* @param participant {address}
	* @param yieldSyncV1VaultAddress {address}
	* @return admin {bool}
	* @return member {bool}
	*/
	function yieldSyncV1VaultAddress_participant_access(address yieldSyncV1VaultAddress, address participant)
		external
		view
		returns (bool admin, bool member)
	;


	/**
	* @notice Add Admin
	* @dev [update] `_admin_yieldSyncV1Vaults`
	*      [update] `_yieldSyncV1VaultAddress_admins`
	*      [update] `yieldSyncV1VaultAddress_participant_access`
	* @param yieldSyncV1VaultAddress {address}
	* @param admin {address}
	*/
	function adminAdd(address yieldSyncV1VaultAddress, address admin)
		external
	;

	/**
	* @notice Remove Admin
	* @dev [update] `_admin_yieldSyncV1Vaults`
	*      [update] `_yieldSyncV1VaultAddress_admins`
	*      [update] `yieldSyncV1VaultAddress_participant_access`
	* @param yieldSyncV1VaultAddress {address}
	* @param admin {address}
	*/
	function adminRemove(address yieldSyncV1VaultAddress, address admin)
		external
	;


	/**
	* @notice Add Member
	* @dev [update] `_member_yieldSyncV1Vaults`
	*      [update] `_yieldSyncV1VaultAddress_members`
	*      [update] `yieldSyncV1VaultAddress_participant_access`
	* @param yieldSyncV1VaultAddress {address}
	* @param member {address}
	*/
	function memberAdd(address yieldSyncV1VaultAddress, address member)
		external
	;

	/**
	* @notice Remove Member
	* @dev [update] `_member_yieldSyncV1Vaults`
	*      [update] `_yieldSyncV1VaultAddress_members`
	*      [update] `yieldSyncV1VaultAddress_participant_access`
	* @param yieldSyncV1VaultAddress {address}
	* @param member {address}
	*/
	function memberRemove(address yieldSyncV1VaultAddress, address member)
		external
	;
}
