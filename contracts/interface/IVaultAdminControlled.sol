// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [import-internal] */
import "./IVault.sol";


/**
* @title IVIVaultAdminControlledult
*/
interface IVaultAdminControlled is
	IVault
{
	/* [event] */
	/**
	* @dev Emits when `requiredApproveVotes` are updated
	*/
	event UpdatedRequiredApproveVotes (
		uint256 requiredApproveVotes
	);

	/**
	* @dev Emits when an address is added to VOTER_ROLE on `AccessControlEnumerable`
	*/
	event VoterAdded (
		address addedVoter
	);

	/**
	* @dev Emits when an address is removed from VOTER_ROLE on `AccessControlEnumerable`
	*/
	event VoterRemoved (
		address addedVoter
	);

	/**
	* @dev Emits when `withdrawalDelayMinutes` is updated
	*/
	event UpdatedWithdrawalDelayMinutes (
		uint256 withdrawalDelayMinutes
	);


	/**
	* @notice Update the required approved votes
	*
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	*
	* @dev [update] `requiredApproveVotes`
	*
	* @param newRequiredApproveVotes {uint256}
	*
	* @return {uint256} New `requiredApproveVotes`
	*
	* Emits: `UpdatedRequiredApproveVotes`
	*/
	function updateRequiredApproveVotes(uint256 newRequiredApproveVotes)
		external
		returns (uint256)
	;

	/**
	* @notice Assign VOTER_ROLE to an address on AccessControlEnumerable
	*
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	*
	* @dev [add] address to VOTER_ROLE on `AccessControlEnumerable`
	*
	* @param targetAddress {address}
	*
	* @return {address} Voter added
	*
	* Emits: `VoterAdded`
	*/
	function addVoter(address targetAddress)
		external
		returns (address)
	;

	/**
	* @notice Remove a voter
	*
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	*
	* @dev [remove] address with VOTER_ROLE on `AccessControlEnumerable`
	*
	* @param voter {address} Address of the voter to remove
	*
	* @return {address} Removed voter
	*
	* Emits: `VoterRemoved`
	*/	
	function removeVoter(address voter)
		external
		returns (address)
	;

	/**
	* @notice Update `withdrawalDelayMinutes`
	*
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	*
	* @dev [update] `withdrawalDelayMinutes` to new value
	*
	* @param newWithdrawalDelayMinutes {uint256}
	*
	* @return {uint256} New `withdrawalDelayMinutes`
	*
	* Emits: `UpdatedWithdrawalDelayMinutes`
	*/
	function updateWithdrawalDelayMinutes(uint256 newWithdrawalDelayMinutes)
		external
		returns (uint256)
	;

	/**
	* @notice
	*
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	*
	* @dev [update] WithdrawalRequest within `_withdrawalRequest`
	*
	* @param newLatestSignificantApproveVoteTime {uint256}
	*
	* @return {uint256} `withdrawalRequestId`
	* @return {uint256} `newLatestSignificantApproveVoteTime`
	*
	* Emits: `UpdatedWithdrawalRequestLastSignificantApproveVote`
	*/
	function updateWithdrawalRequestLatestSignificantApproveVoteTime(
		uint256 withdrawalRequestId,
		uint256 newLatestSignificantApproveVoteTime
	)
		external
		returns (uint256, uint256)
	;

	/**
	* @notice Delete WithdrawalRequest & all associated values
	*
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	*
	* @dev [call][internal] {_deleteWithdrawalRequest}
	*
	* @param withdrawalRequestId {uint256}
	* @return {bool} Status
	*
	* Emits: `DeletedWithdrawalRequest`
	*/
	function deleteWithdrawalRequest(uint256 withdrawalRequestId)
		external
		returns (uint256)
	;
}