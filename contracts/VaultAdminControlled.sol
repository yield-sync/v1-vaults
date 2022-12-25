// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [import] */
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/* [import-internal] */
import "./interface/IVaultAdminControlled.sol";
import "./Vault.sol";


/**
* @title VaultAdminControlled
*/
contract VaultAdminControlled is
	Vault,
	IVaultAdminControlled
{
	/* [using] */
	using SafeERC20 for IERC20;


	/* [constructor] */
	constructor (
		address admin,
		uint256 _requiredApproveVotes,
		uint256 _withdrawalDelayMinutes,
		address[] memory voters
	)
		Vault(_requiredApproveVotes, _withdrawalDelayMinutes, voters)
	{
		// Set up DEFAULT_ADMIN_ROLE
		_setupRole(DEFAULT_ADMIN_ROLE, admin);
	}


	/* [function] */
	/// @inheritdoc IVaultAdminControlled
	function updateRequiredApproveVotes(uint256 newRequiredApproveVotes)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (uint256)
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

		return (requiredApproveVotes);
	}

	/// @inheritdoc IVaultAdminControlled
	function addVoter(address targetAddress)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (address)
	{
		// [add] address to VOTER_ROLE on `AccessControlEnumerable`
		_setupRole(VOTER_ROLE, targetAddress);

		// [emit]
		emit VoterAdded(targetAddress);

		return targetAddress;
	}

	/// @inheritdoc IVaultAdminControlled
	function removeVoter(address voter)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (address)
	{
		// [remove] address with VOTER_ROLE on `AccessControlEnumerable`
		_revokeRole(VOTER_ROLE, voter);

		// [emit]
		emit VoterRemoved(voter);

		return voter;
	}

	/// @inheritdoc IVaultAdminControlled
	function updateWithdrawalDelayMinutes(uint256 newWithdrawalDelayMinutes)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (uint256)
	{
		// [require] newWithdrawalDelayMinutes is greater than OR equal to 0
		require(newWithdrawalDelayMinutes >= 0, "Invalid newWithdrawalDelayMinutes");

		// [update] `withdrawalDelayMinutes`
		withdrawalDelayMinutes = newWithdrawalDelayMinutes;

		// [emit]
		emit UpdatedWithdrawalDelayMinutes(withdrawalDelayMinutes);

		return withdrawalDelayMinutes;
	}

	/// @inheritdoc IVaultAdminControlled
	function updateWithdrawalRequestLatestSignificantApproveVoteTime(
		uint256 withdrawalRequestId,
		uint256 latestSignificantApproveVoteTime
	)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		validWithdrawalRequest(withdrawalRequestId)
		returns (uint256, uint256)
	{
		// [update] WithdrawalRequest within `_withdrawalRequest`
		_withdrawalRequest[
			withdrawalRequestId
		].latestSignificantApproveVoteTime = latestSignificantApproveVoteTime;

		return (withdrawalRequestId, latestSignificantApproveVoteTime);
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
