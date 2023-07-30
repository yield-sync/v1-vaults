// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IYieldSyncV1Vault } from "@yield-sync/v1-sdk/contracts/interface/IYieldSyncV1Vault.sol";

import { IYieldSyncV1VaultAccessControl } from "./interface/IYieldSyncV1VaultAccessControl.sol";


struct Access
{
	bool admin;
	bool member;
}


contract YieldSyncV1VaultAccessControl is
	IYieldSyncV1VaultAccessControl
{
	mapping (address admin => address[] yieldSyncV1Vaults) internal _admin_yieldSyncV1Vaults;
	mapping (address member => address[] yieldSyncV1Vaults) internal _member_yieldSyncV1Vaults;
	mapping (address yieldSyncV1Vault => address[] admins) internal _yieldSyncV1Vault_admins;
	mapping (address yieldSyncV1Vault => address[] members) internal _yieldSyncV1Vault_members;

	mapping (
		address yieldSyncV1Vault => mapping (address participant => Access access)
	) internal _yieldSyncV1Vault_participant_access;


	modifier contractYieldSyncV1Vault(address yieldSyncV1Vault)
	{
		require(yieldSyncV1Vault == msg.sender, "!yieldSyncV1Vault");

		_;
	}


	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function admin_yieldSyncV1Vaults(address admin)
		public
		view
		override
		returns (address[] memory)
	{
		return _admin_yieldSyncV1Vaults[admin];
	}

		/// @inheritdoc IYieldSyncV1VaultAccessControl
	function member_yieldSyncV1Vaults(address member)
		public
		view
		override
		returns (address[] memory)
	{
		return _member_yieldSyncV1Vaults[member];
	}

	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function yieldSyncV1Vault_admins(address yieldSyncV1Vault)
		public
		view
		override
		returns (address[] memory)
	{
		return _yieldSyncV1Vault_admins[yieldSyncV1Vault];
	}

	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function yieldSyncV1Vault_members(address yieldSyncV1Vault)
		public
		view
		override
		returns (address[] memory)
	{
		return _yieldSyncV1Vault_members[yieldSyncV1Vault];
	}

	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function yieldSyncV1Vault_participant_access(address yieldSyncV1Vault, address participant)
		public
		view
		override
		returns (bool admin, bool member)
	{
		admin = _yieldSyncV1Vault_participant_access[yieldSyncV1Vault][participant].admin;
		member = _yieldSyncV1Vault_participant_access[yieldSyncV1Vault][participant].member;
	}


	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function adminAdd(address yieldSyncV1Vault, address target)
		public
		override
		contractYieldSyncV1Vault(yieldSyncV1Vault)
	{
		require(!_yieldSyncV1Vault_participant_access[yieldSyncV1Vault][target].admin, "Already admin");

		_admin_yieldSyncV1Vaults[target].push(yieldSyncV1Vault);

		_yieldSyncV1Vault_admins[yieldSyncV1Vault].push(target);

		_yieldSyncV1Vault_participant_access[yieldSyncV1Vault][target] = Access({
			member: _yieldSyncV1Vault_participant_access[yieldSyncV1Vault][target].member,
			admin: true
		});
	}

	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function adminRemove(address yieldSyncV1Vault, address admin)
		public
		override
		contractYieldSyncV1Vault(yieldSyncV1Vault)
	{
		require(_yieldSyncV1Vault_participant_access[yieldSyncV1Vault][admin].admin, "Not admin");

		// [update] _admin_yieldSyncV1Vaults
		for (uint256 i = 0; i < _admin_yieldSyncV1Vaults[admin].length; i++)
		{
			if (_admin_yieldSyncV1Vaults[admin][i] == yieldSyncV1Vault)
			{
				_admin_yieldSyncV1Vaults[admin][i] = _admin_yieldSyncV1Vaults[admin][
					_admin_yieldSyncV1Vaults[admin].length - 1
				];

				_admin_yieldSyncV1Vaults[admin].pop();

				break;
			}
		}

		// [update] _yieldSyncV1Vault_admins
		for (uint256 i = 0; i < _yieldSyncV1Vault_admins[yieldSyncV1Vault].length; i++)
		{
			if (_yieldSyncV1Vault_admins[yieldSyncV1Vault][i] == admin)
			{
				_yieldSyncV1Vault_admins[yieldSyncV1Vault][i] = _yieldSyncV1Vault_admins[yieldSyncV1Vault][
					_yieldSyncV1Vault_admins[yieldSyncV1Vault].length - 1
				];

				_yieldSyncV1Vault_admins[yieldSyncV1Vault].pop();

				break;
			}
		}

		_yieldSyncV1Vault_participant_access[yieldSyncV1Vault][admin] = Access({
			admin: false,
			member: _yieldSyncV1Vault_participant_access[yieldSyncV1Vault][admin].member
		});
	}

	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function memberAdd(address yieldSyncV1Vault, address target)
		public
		override
		contractYieldSyncV1Vault(yieldSyncV1Vault)
	{
		require(!_yieldSyncV1Vault_participant_access[yieldSyncV1Vault][target].member, "Already member");

		_member_yieldSyncV1Vaults[target].push(yieldSyncV1Vault);

		_yieldSyncV1Vault_members[yieldSyncV1Vault].push(target);

		_yieldSyncV1Vault_participant_access[yieldSyncV1Vault][target] = Access({
			admin: _yieldSyncV1Vault_participant_access[yieldSyncV1Vault][target].admin,
			member: true
		});
	}

	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function memberRemove(address yieldSyncV1Vault, address member)
		public
		override
		contractYieldSyncV1Vault(yieldSyncV1Vault)
	{
		require(_yieldSyncV1Vault_participant_access[yieldSyncV1Vault][member].member, "Not member");

		// [update] _member_yieldSyncV1Vaults
		for (uint256 i = 0; i < _member_yieldSyncV1Vaults[member].length; i++)
		{
			if (_member_yieldSyncV1Vaults[member][i] == yieldSyncV1Vault)
			{
				_member_yieldSyncV1Vaults[member][i] = _member_yieldSyncV1Vaults[member][
					_member_yieldSyncV1Vaults[member].length - 1
				];

				_member_yieldSyncV1Vaults[member].pop();

				break;
			}
		}

		// [update] _yieldSyncV1Vault_members
		for (uint256 i = 0; i < _yieldSyncV1Vault_members[yieldSyncV1Vault].length; i++)
		{
			if (_yieldSyncV1Vault_members[yieldSyncV1Vault][i] == member)
			{
				_yieldSyncV1Vault_members[yieldSyncV1Vault][i] = _yieldSyncV1Vault_members[yieldSyncV1Vault][
					_yieldSyncV1Vault_members[yieldSyncV1Vault].length - 1
				];

				_yieldSyncV1Vault_members[yieldSyncV1Vault].pop();

				break;
			}
		}

		_yieldSyncV1Vault_participant_access[yieldSyncV1Vault][member] = Access({
			admin: _yieldSyncV1Vault_participant_access[yieldSyncV1Vault][member].admin,
			member: false
		});
	}
}
