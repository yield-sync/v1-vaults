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
	mapping (address yieldSyncV1Vault  => address[] admins) internal _yieldSyncV1Vault_admins;
	mapping (address yieldSyncV1Vault => address[] members) internal _yieldSyncV1Vault_members;
	
	mapping (
		address yieldSyncV1Vault => mapping (address participant => Access access)
	) internal _yieldSyncV1Vault_participant_access;


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
	function member_yieldSyncV1Vaults(address member)
		public
		view
		override
		returns (address[] memory)
	{
		return _member_yieldSyncV1Vaults[member];
	}

	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function yieldSyncV1Vault_participant_access(address yieldSyncV1VaultAddress, address participant)
		public
		view
		override
		returns (bool admin, bool member)
	{
		admin = _yieldSyncV1Vault_participant_access[yieldSyncV1VaultAddress][participant].admin;
		member = _yieldSyncV1Vault_participant_access[yieldSyncV1VaultAddress][participant].member;
	}


	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function addAdmin(address yieldSyncV1VaultAddress, address admin)
		public
		override
	{
		require(yieldSyncV1VaultAddress == msg.sender, "!yieldSyncV1Vault");

		require(!_yieldSyncV1Vault_participant_access[yieldSyncV1VaultAddress][admin].admin, "Already admin");

		_admin_yieldSyncV1Vaults[admin].push(yieldSyncV1VaultAddress);

		_yieldSyncV1Vault_admins[yieldSyncV1VaultAddress].push(admin);

		_yieldSyncV1Vault_participant_access[yieldSyncV1VaultAddress][admin] = Access({
			member: _yieldSyncV1Vault_participant_access[yieldSyncV1VaultAddress][admin].member,
			admin: true
		});
	}

	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function removeAdmin(address yieldSyncV1VaultAddress, address admin)
		public
		override
	{
		require(yieldSyncV1VaultAddress == msg.sender, "!_yieldSyncV1VaultAddress");

		// [update] _admin_yieldSyncV1Vaults
		for (uint256 i = 0; i < _admin_yieldSyncV1Vaults[admin].length; i++)
		{
			if (_admin_yieldSyncV1Vaults[admin][i] == yieldSyncV1VaultAddress)
			{
				_admin_yieldSyncV1Vaults[admin][i] = _admin_yieldSyncV1Vaults[admin][
					_admin_yieldSyncV1Vaults[admin].length - 1
				];

				_admin_yieldSyncV1Vaults[admin].pop();

				break;
			}
		}

		// [update] _yieldSyncV1Vault_admins
		for (uint256 i = 0; i < _yieldSyncV1Vault_admins[yieldSyncV1VaultAddress].length; i++)
		{
			if (_yieldSyncV1Vault_admins[yieldSyncV1VaultAddress][i] == admin)
			{
				_yieldSyncV1Vault_admins[yieldSyncV1VaultAddress][i] = _yieldSyncV1Vault_admins[
					yieldSyncV1VaultAddress
				][
					_yieldSyncV1Vault_admins[yieldSyncV1VaultAddress].length - 1
				];

				_yieldSyncV1Vault_admins[yieldSyncV1VaultAddress].pop();

				break;
			}
		}

		_yieldSyncV1Vault_participant_access[yieldSyncV1VaultAddress][admin] = Access({
			admin: false,
			member: _yieldSyncV1Vault_participant_access[yieldSyncV1VaultAddress][admin].member
		});
	}


	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function addMember(address yieldSyncV1VaultAddress, address member)
		public
		override
	{
		require(yieldSyncV1VaultAddress == msg.sender, "!yieldSyncV1Vault");

		require(!_yieldSyncV1Vault_participant_access[yieldSyncV1VaultAddress][member].member, "Already member");

		_member_yieldSyncV1Vaults[member].push(yieldSyncV1VaultAddress);

		_yieldSyncV1Vault_members[yieldSyncV1VaultAddress].push(member);

		_yieldSyncV1Vault_participant_access[yieldSyncV1VaultAddress][member] = Access({
			admin:  _yieldSyncV1Vault_participant_access[yieldSyncV1VaultAddress][member].admin,
			member: true
		});
	}

	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function removeMember(address yieldSyncV1VaultAddress, address member)
		public
		override
	{
		require(yieldSyncV1VaultAddress == msg.sender, "!_yieldSyncV1VaultAddress");

		// [update] _member_yieldSyncV1Vaults
		for (uint256 i = 0; i < _member_yieldSyncV1Vaults[member].length; i++)
		{
			if (_member_yieldSyncV1Vaults[member][i] == yieldSyncV1VaultAddress)
			{
				_member_yieldSyncV1Vaults[member][i] = _member_yieldSyncV1Vaults[member][
					_member_yieldSyncV1Vaults[member].length - 1
				];

				_member_yieldSyncV1Vaults[member].pop();

				break;
			}
		}

		// [update] _yieldSyncV1Vault_members
		for (uint256 i = 0; i < _yieldSyncV1Vault_members[yieldSyncV1VaultAddress].length; i++)
		{
			if (_yieldSyncV1Vault_members[yieldSyncV1VaultAddress][i] == member)
			{
				_yieldSyncV1Vault_members[yieldSyncV1VaultAddress][i] = _yieldSyncV1Vault_members[
					yieldSyncV1VaultAddress
				][
					_yieldSyncV1Vault_members[yieldSyncV1VaultAddress].length - 1
				];

				_yieldSyncV1Vault_members[yieldSyncV1VaultAddress].pop();

				break;
			}
		}

		_yieldSyncV1Vault_participant_access[yieldSyncV1VaultAddress][member] = Access({
			admin: _yieldSyncV1Vault_participant_access[yieldSyncV1VaultAddress][member].admin,
			member: false
		});
	}
}
