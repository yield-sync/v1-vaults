// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [import] */
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/* [import-internal] */
import "./interface/IVaultAdminControlled.sol";
import "./Vault.sol";


contract VaultAdminControlled is
	Vault,
	IVaultAdminControlled
{
	/* [USING] */
	using SafeERC20 for IERC20;


	/* [constructor] */
	constructor (
		address admin,
		uint256 requiredApproveVotes_,
		uint256 withdrawalDelayMinutes_,
		address[] memory voters
	)
		Vault(requiredApproveVotes_, withdrawalDelayMinutes_, voters)
	{
		// Set up the default admin role
		_setupRole(DEFAULT_ADMIN_ROLE, admin);
	}


	/* [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE */

	/// @inheritdoc IVaultAdminControlled
	function updateRequiredApproveVotes(uint256 newRequiredApproveVotes)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (bool, uint256)
	{
		// [require] `newRequiredApproveVotes` <= VOTER_ROLE Member Count
		require(
			newRequiredApproveVotes <= getRoleMemberCount(VOTER_ROLE),
			"Invalid `newRequiredApproveVotes`"
		);

		// [update]
		requiredApproveVotes = newRequiredApproveVotes;

		// [emit]
		emit UpdatedRequiredApproveVotes(requiredApproveVotes);

		return (true, requiredApproveVotes);
	}

	/// @inheritdoc IVaultAdminControlled
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

	/// @inheritdoc IVaultAdminControlled
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

	/// @inheritdoc IVaultAdminControlled
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

	/// @inheritdoc IVaultAdminControlled
	function updateWithdrawalRequestLatestSignificantApproveVoteMade(
		uint256 withdrawalRequestId,
		uint256 latestSignificantApproveVoteMade
	)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		validWithdrawalRequest(withdrawalRequestId)
		returns (uint256, uint256)
	{
		_withdrawalRequest[
			withdrawalRequestId
		].latestSignificantApproveVoteMade = latestSignificantApproveVoteMade;

		return (withdrawalRequestId, latestSignificantApproveVoteMade);
	}

	/// @inheritdoc IVaultAdminControlled
	function deleteWithdrawalRequest(uint256 withdrawalRequestId)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		validWithdrawalRequest(withdrawalRequestId)
		returns (uint256)
	{
		// [call][internal]
		_deleteWithdrawalRequest(withdrawalRequestId);

		return withdrawalRequestId;
	}
}
