// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [import-internal] */
import "./interface/IVaultAdminControlled.sol";
import "./Vault.sol";


contract VaultAdminControlled is
	Vault,
	IVaultAdminControlled
{
	constructor (
		address admin,
		uint256 requiredSignatures_,
		uint256 withdrawalDelayMinutes_,
		address[] memory voters
	)
		Vault(
			requiredSignatures_,
			withdrawalDelayMinutes_,
			voters
		)
	{
		// Set up the default admin role
		_setupRole(DEFAULT_ADMIN_ROLE, admin);
	}

	//bool paused;
	//bool accelerated;


	/* [restriction][AccessControlEnumerable] DEFAULT_ADMIN_ROLE */
	// @inheritdoc IVaultAdminControlled
	function updateRequiredSignatures(uint256 newRequiredSignatures)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (bool, uint256)
	{
		// [require] `newRequiredSignatures` <= VOTER_ROLE Member Count
		require(
			newRequiredSignatures <= getRoleMemberCount(VOTER_ROLE),
			"Invalid `newRequiredSignatures`"
		);

		// [update]
		requiredSignatures = newRequiredSignatures;

		// [emit]
		emit UpdatedRequiredSignatures(requiredSignatures);

		return (true, requiredSignatures);
	}

	// @inheritdoc IVaultAdminControlled
	function addVoter(address voter)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (bool, address)
	{
		// [add] Voter to `AccessControl._roles` as VOTER_ROLE
		_setupRole(VOTER_ROLE, voter);

		// [emit]
		emit VoterAdded(voter);

		return (true, voter);
	}

	// @inheritdoc IVaultAdminControlled
	function removeVoter(address voter)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (bool, address)
	{
		// [remove] Voter with VOTER_ROLE from `AccessControl._roles`
		_revokeRole(VOTER_ROLE, voter);

		// [emit]
		emit VoterRemoved(voter);

		return (true, voter);
	}

	// @inheritdoc IVaultAdminControlled
	function updateWithdrawalDelayMinutes(uint256 newWithdrawalDelayMinutes)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (bool, uint256)
	{
		// [require] newWithdrawalDelayMinutes is greater than 0
		require(newWithdrawalDelayMinutes >= 0, "Invalid newWithdrawalDelayMinutes");

		// [update] `withdrawalDelayMinutes` to new value
		withdrawalDelayMinutes = newWithdrawalDelayMinutes;

		// [emit]
		emit UpdatedWithdrawalDelayMinutes(withdrawalDelayMinutes);

		return (true, withdrawalDelayMinutes);
	}

	// @inheritdoc IVaultAdminControlled
	function toggleWithdrawalRequestPause(uint256 withdrawalRequestId)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		validWithdrawalRequest(withdrawalRequestId)
		returns (bool, uint256)
	{
		// [update] `_withdrawalRequest`
		_withdrawalRequest[withdrawalRequestId].paused = !_withdrawalRequest[
			withdrawalRequestId
		].paused;

		// [emit]
		emit ToggledWithdrawalRequestPause(
			_withdrawalRequest[withdrawalRequestId].paused
		);

		return (true, withdrawalRequestId);
	}

	// @inheritdoc IVaultAdminControlled
	function deleteWithdrawalRequest(uint256 withdrawalRequestId)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		validWithdrawalRequest(withdrawalRequestId)
		returns (bool)
	{
		// [call][internal]
		_deleteWithdrawalRequest(withdrawalRequestId);

		// [emit]
		emit DeletedWithdrawalRequest(withdrawalRequestId);

		return true;
	}


	function processWithdrawalRequests(uint256 withdrawalRequestId)
		public
		override(Vault, IVault)
		returns (bool)
	{
		// [require] Required signatures to be met
		require(
			_withdrawalRequest[withdrawalRequestId].forVoteCount >= requiredSignatures,
			"Not enough signatures"
		);

		// [calculate] Time passed
		uint256 timePassed = block.timestamp - _withdrawalRequest[withdrawalRequestId].lastImpactfulVoteTime;

		// [require] WithdrawalRequest time delay passed OR accelerated
		require(
			timePassed >= SafeMath.mul(withdrawalDelayMinutes, 60) ||
			_withdrawalRequest[withdrawalRequestId].accelerated,
			"Not enough time has passed"
		);

		// [require] WithdrawalRequest NOT paused
		require(_withdrawalRequest[withdrawalRequestId].paused == false, "Paused");

		// [call][internal]
		_processWithdrawalRequests(withdrawalRequestId);

		return true;
	}
}
