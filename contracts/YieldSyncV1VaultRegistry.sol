// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IYieldSyncV1Vault } from "@yield-sync/v1-sdk/contracts/interface/IYieldSyncV1Vault.sol";

import { IYieldSyncV1VaultRegistry } from "./interface/IYieldSyncV1VaultRegistry.sol";


struct Access
{
	bool admin;
	bool member;
}


contract YieldSyncV1VaultRegistry is
	IYieldSyncV1VaultRegistry
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


	/// @inheritdoc IYieldSyncV1VaultRegistry
	function admin_yieldSyncV1Vaults(address _admin)
		public
		view
		override
		returns (address[] memory yieldSyncV1Vaults_)
	{
		return _admin_yieldSyncV1Vaults[_admin];
	}

	/// @inheritdoc IYieldSyncV1VaultRegistry
	function member_yieldSyncV1Vaults(address _member)
		public
		view
		override
		returns (address[] memory yieldSyncV1Vaults_)
	{
		return _member_yieldSyncV1Vaults[_member];
	}

	/// @inheritdoc IYieldSyncV1VaultRegistry
	function yieldSyncV1Vault_admins(address _yieldSyncV1Vault)
		public
		view
		override
		returns (address[] memory admins_)
	{
		return _yieldSyncV1Vault_admins[_yieldSyncV1Vault];
	}

	/// @inheritdoc IYieldSyncV1VaultRegistry
	function yieldSyncV1Vault_members(address _yieldSyncV1Vault)
		public
		view
		override
		returns (address[] memory members_)
	{
		return _yieldSyncV1Vault_members[_yieldSyncV1Vault];
	}

	/// @inheritdoc IYieldSyncV1VaultRegistry
	function yieldSyncV1Vault_participant_access(address _yieldSyncV1Vault, address _participant)
		public
		view
		override
		returns (bool admin_, bool member_)
	{
		admin_ = _yieldSyncV1Vault_participant_access[_yieldSyncV1Vault][_participant].admin;
		member_ = _yieldSyncV1Vault_participant_access[_yieldSyncV1Vault][_participant].member;
	}


	/// @inheritdoc IYieldSyncV1VaultRegistry
	function adminAdd(address _yieldSyncV1Vault, address _target)
		public
		override
		contractYieldSyncV1Vault(_yieldSyncV1Vault)
	{
		require(!_yieldSyncV1Vault_participant_access[_yieldSyncV1Vault][_target].admin, "Already admin");

		_admin_yieldSyncV1Vaults[_target].push(_yieldSyncV1Vault);

		_yieldSyncV1Vault_admins[_yieldSyncV1Vault].push(_target);

		_yieldSyncV1Vault_participant_access[_yieldSyncV1Vault][_target] = Access({
			member: _yieldSyncV1Vault_participant_access[_yieldSyncV1Vault][_target].member,
			admin: true
		});
	}

	/// @inheritdoc IYieldSyncV1VaultRegistry
	function adminRemove(address _yieldSyncV1Vault, address _admin)
		public
		override
		contractYieldSyncV1Vault(_yieldSyncV1Vault)
	{
		require(_yieldSyncV1Vault_participant_access[_yieldSyncV1Vault][_admin].admin, "Not admin");

		for (uint256 i = 0; i < _admin_yieldSyncV1Vaults[_admin].length; i++)
		{
			if (_admin_yieldSyncV1Vaults[_admin][i] == _yieldSyncV1Vault)
			{
				_admin_yieldSyncV1Vaults[_admin][i] = _admin_yieldSyncV1Vaults[_admin][
					_admin_yieldSyncV1Vaults[_admin].length - 1
				];

				_admin_yieldSyncV1Vaults[_admin].pop();

				break;
			}
		}

		for (uint256 i = 0; i < _yieldSyncV1Vault_admins[_yieldSyncV1Vault].length; i++)
		{
			if (_yieldSyncV1Vault_admins[_yieldSyncV1Vault][i] == _admin)
			{
				_yieldSyncV1Vault_admins[_yieldSyncV1Vault][i] = _yieldSyncV1Vault_admins[_yieldSyncV1Vault][
					_yieldSyncV1Vault_admins[_yieldSyncV1Vault].length - 1
				];

				_yieldSyncV1Vault_admins[_yieldSyncV1Vault].pop();

				break;
			}
		}

		_yieldSyncV1Vault_participant_access[_yieldSyncV1Vault][_admin] = Access({
			admin: false,
			member: _yieldSyncV1Vault_participant_access[_yieldSyncV1Vault][_admin].member
		});
	}

	/// @inheritdoc IYieldSyncV1VaultRegistry
	function memberAdd(address _yieldSyncV1Vault, address _target)
		public
		override
		contractYieldSyncV1Vault(_yieldSyncV1Vault)
	{
		require(!_yieldSyncV1Vault_participant_access[_yieldSyncV1Vault][_target].member, "Already member");

		_member_yieldSyncV1Vaults[_target].push(_yieldSyncV1Vault);

		_yieldSyncV1Vault_members[_yieldSyncV1Vault].push(_target);

		_yieldSyncV1Vault_participant_access[_yieldSyncV1Vault][_target] = Access({
			admin: _yieldSyncV1Vault_participant_access[_yieldSyncV1Vault][_target].admin,
			member: true
		});
	}

	/// @inheritdoc IYieldSyncV1VaultRegistry
	function memberRemove(address _yieldSyncV1Vault, address _member)
		public
		override
		contractYieldSyncV1Vault(_yieldSyncV1Vault)
	{
		require(_yieldSyncV1Vault_participant_access[_yieldSyncV1Vault][_member].member, "Not member");

		for (uint256 i = 0; i < _member_yieldSyncV1Vaults[_member].length; i++)
		{
			if (_member_yieldSyncV1Vaults[_member][i] == _yieldSyncV1Vault)
			{
				_member_yieldSyncV1Vaults[_member][i] = _member_yieldSyncV1Vaults[_member][
					_member_yieldSyncV1Vaults[_member].length - 1
				];

				_member_yieldSyncV1Vaults[_member].pop();

				break;
			}
		}

		for (uint256 i = 0; i < _yieldSyncV1Vault_members[_yieldSyncV1Vault].length; i++)
		{
			if (_yieldSyncV1Vault_members[_yieldSyncV1Vault][i] == _member)
			{
				_yieldSyncV1Vault_members[_yieldSyncV1Vault][i] = _yieldSyncV1Vault_members[_yieldSyncV1Vault][
					_yieldSyncV1Vault_members[_yieldSyncV1Vault].length - 1
				];

				_yieldSyncV1Vault_members[_yieldSyncV1Vault].pop();

				break;
			}
		}

		_yieldSyncV1Vault_participant_access[_yieldSyncV1Vault][_member] = Access({
			admin: _yieldSyncV1Vault_participant_access[_yieldSyncV1Vault][_member].admin,
			member: false
		});
	}
}
