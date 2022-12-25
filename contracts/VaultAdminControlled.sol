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


	/* [state-variable] */
	mapping (uint256 => WithdrawalRequestAdminData) _withdrawalRequestAdminData;


	/* [constructor] */
	constructor (
		address admin,
		uint256 requiredForVotes_,
		uint256 withdrawalDelayMinutes_,
		address[] memory voters
	)
		Vault(requiredForVotes_, withdrawalDelayMinutes_, voters)
	{
		// Set up the default admin role
		_setupRole(DEFAULT_ADMIN_ROLE, admin);
	}


	/* [restriction][internal] */

	/**
	* @notice Delete `WithdrawalRequest` and related values
	*
	* @dev [restriction][internal]
	*
	* @dev [override]
	*      [super] `_deleteWithdrawalRequest`
	*      [delete] `_withdrawalRequestAdminData` value
	*
	* @param withdrawalRequestId {uint256}
	*
	* Emits: `DeletedWithdrawalRequest`
	*/
	function _deleteWithdrawalRequest(uint256 withdrawalRequestId)
		override(Vault)
		internal
	{
		// [super]
		super._deleteWithdrawalRequest(withdrawalRequestId);

		// [delete] `_withdrawalRequestAdminData` value
		delete _withdrawalRequestAdminData[withdrawalRequestId];
	}
	

	/* [restriction][AccessControlEnumerable] VOTER_ROLE */

	/**
	* @dev [override]
	*/
	function createWithdrawalRequest(
		address to,
		address tokenAddress,
		uint256 amount
	)
		override(Vault, IVault)
		public
		onlyRole(VOTER_ROLE)
		returns (uint256)
	{
		// [super]
		uint256 withdrawalRequestId = super.createWithdrawalRequest(
			to,
			tokenAddress,
			amount
		);

		// [add] `_withdrawalRequestAdminData` value
		_withdrawalRequestAdminData[withdrawalRequestId] = WithdrawalRequestAdminData({
			paused: false,
			accelerated: false
		});

		return withdrawalRequestId;
	}

	/**
	* @dev [override]
	*/
	function processWithdrawalRequests(uint256 withdrawalRequestId)
		override(Vault, IVault)
		public
	{
		// Temporary variable
		WithdrawalRequest memory w = _withdrawalRequest[withdrawalRequestId];

		// [require] Required signatures to be met
		require(
			w.forVoteCount >= requiredForVotes,
			"Not enough signatures"
		);

		// [require] WithdrawalRequest time delay passed OR accelerated
		require(
			block.timestamp - w.lastImpactfulVoteTime >= SafeMath.mul(withdrawalDelayMinutes, 60) || _withdrawalRequestAdminData[withdrawalRequestId].accelerated,
			"Not enough time has passed & not accelerated"
		);

		// [require] WithdrawalRequest NOT paused
		require(!_withdrawalRequestAdminData[withdrawalRequestId].paused, "Paused");
		
		// [ERC20-transfer] Specified amount of tokens to recipient
		IERC20(w.token).safeTransfer(w.to, w.amount);

		// [decrement] `_tokenBalance`
		_tokenBalance[_withdrawalRequest[withdrawalRequestId].token] -= w.amount;

		// [emit]
		emit TokensWithdrawn(msg.sender, w.to, w.amount);

		// [call]
		_deleteWithdrawalRequest(withdrawalRequestId);
	}


	/* [restriction][AccessControlEnumerable] DEFAULT_ADMIN_ROLE */

	// @inheritdoc IVaultAdminControlled
	function updateRequiredForVotes(uint256 newRequiredForVotes)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (bool, uint256)
	{
		// [require] `newRequiredForVotes` <= VOTER_ROLE Member Count
		require(
			newRequiredForVotes <= getRoleMemberCount(VOTER_ROLE),
			"Invalid `newRequiredForVotes`"
		);

		// [update]
		requiredForVotes = newRequiredForVotes;

		// [emit]
		emit UpdatedRequiredForVotes(requiredForVotes);

		return (true, requiredForVotes);
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
		// [update] `_withdrawalRequestPaused`
		_withdrawalRequestAdminData[withdrawalRequestId].paused = !_withdrawalRequestAdminData[
			withdrawalRequestId
		].paused;

		// [emit]
		emit ToggledWithdrawalRequestPaused(
			_withdrawalRequestAdminData[withdrawalRequestId].paused
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

		return true;
	}
}
