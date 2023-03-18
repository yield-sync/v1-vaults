// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IYieldSyncV1Vault } from "@yield-sync/v1-sdk/contracts/interface/IYieldSyncV1Vault.sol";

import { IYieldSyncV1VaultRecord } from "./interface/IYieldSyncV1VaultRecord.sol";


struct Access {
	bool admin;
	bool member;
}


/**
* @title YieldSyncV1VaultRecord
*/
contract YieldSyncV1VaultRecord is
	IYieldSyncV1VaultRecord
{
	// [mapping]
	mapping (address admin => address[] yieldSyncV1Vaults) internal _admin_yieldSyncV1Vaults;
	mapping (address yieldSyncV1Vault  => address[] admins) internal _yieldSyncV1Vault_admins;
	mapping (address yieldSyncV1Vault => address[] members) internal _yieldSyncV1Vault_members;
	mapping (address member => address[] yieldSyncV1Vaults) internal _member_yieldSyncV1Vaults;
	mapping (
		address participant => mapping (address yieldSyncV1Vault => Access access)
	) internal _participant_yieldSyncV1Vault_access;


	/// @inheritdoc IYieldSyncV1VaultRecord
	function admin_yieldSyncV1Vaults(address admin)
		public
		view
		override
		returns (address[] memory)
	{
		return _admin_yieldSyncV1Vaults[admin];
	}

	/// @inheritdoc IYieldSyncV1VaultRecord
	function yieldSyncV1Vault_admins(address yieldSyncV1Vault)
		public
		view
		override
		returns (address[] memory)
	{
		return _yieldSyncV1Vault_admins[yieldSyncV1Vault];
	}

	/// @inheritdoc IYieldSyncV1VaultRecord
	function yieldSyncV1Vault_members(address yieldSyncV1Vault)
		public
		view
		override
		returns (address[] memory)
	{
		return _yieldSyncV1Vault_members[yieldSyncV1Vault];
	}

	/// @inheritdoc IYieldSyncV1VaultRecord
	function member_yieldSyncV1Vaults(address member)
		public
		view
		override
		returns (address[] memory)
	{
		return _member_yieldSyncV1Vaults[member];
	}

	/// @inheritdoc IYieldSyncV1VaultRecord
	function participant_yieldSyncV1Vault_access(address participant, address yieldSyncV1Vault)
		public
		view
		override
		returns (bool admin, bool member)
	{
		admin = _participant_yieldSyncV1Vault_access[participant][yieldSyncV1Vault].admin;
		member = _participant_yieldSyncV1Vault_access[participant][yieldSyncV1Vault].member;
	}


	/// @inheritdoc IYieldSyncV1VaultRecord
	function addAdmin(address _yieldSyncV1Vault, address admin)
		public
		override
	{
		require(_yieldSyncV1Vault == msg.sender, "!_yieldSyncV1Vault");

		require(!_participant_yieldSyncV1Vault_access[admin][_yieldSyncV1Vault].admin, "Already admin");

		_admin_yieldSyncV1Vaults[admin].push(_yieldSyncV1Vault);

		_yieldSyncV1Vault_admins[_yieldSyncV1Vault].push(admin);

		_participant_yieldSyncV1Vault_access[admin][_yieldSyncV1Vault] = Access({
			member: _participant_yieldSyncV1Vault_access[admin][_yieldSyncV1Vault].member,
			admin: true
		});
	}

	/// @inheritdoc IYieldSyncV1VaultRecord
	function removeAdmin(address _yieldSyncV1Vault, address admin)
		public
		override
	{
		require(_yieldSyncV1Vault == msg.sender, "!_yieldSyncV1VaultAddress");

		// [update] _admin_yieldSyncV1Vaults
		for (uint256 i = 0; i < _admin_yieldSyncV1Vaults[admin].length; i++)
		{
			if (_admin_yieldSyncV1Vaults[admin][i] == _yieldSyncV1Vault)
			{
				_admin_yieldSyncV1Vaults[admin][i] = _admin_yieldSyncV1Vaults[admin][
					_admin_yieldSyncV1Vaults[admin].length - 1
				];

				_admin_yieldSyncV1Vaults[admin].pop();

				break;
			}
		}

		// [update] _yieldSyncV1Vault_admins
		for (uint256 i = 0; i < _yieldSyncV1Vault_admins[_yieldSyncV1Vault].length; i++)
		{
			if (_yieldSyncV1Vault_admins[_yieldSyncV1Vault][i] == admin)
			{
				_yieldSyncV1Vault_admins[_yieldSyncV1Vault][i] = _yieldSyncV1Vault_admins[_yieldSyncV1Vault][
					_yieldSyncV1Vault_admins[_yieldSyncV1Vault].length - 1
				];

				_yieldSyncV1Vault_admins[_yieldSyncV1Vault].pop();

				break;
			}
		}

		_participant_yieldSyncV1Vault_access[admin][_yieldSyncV1Vault] = Access({
			admin: false,
			member: _participant_yieldSyncV1Vault_access[admin][_yieldSyncV1Vault].member
		});
	}


	/// @inheritdoc IYieldSyncV1VaultRecord
	function addMember(address _yieldSyncV1Vault, address member)
		public
		override
	{
		require(_yieldSyncV1Vault == msg.sender, "!_yieldSyncV1Vault");

		require(!_participant_yieldSyncV1Vault_access[member][_yieldSyncV1Vault].member, "Already member");

		_member_yieldSyncV1Vaults[member].push(_yieldSyncV1Vault);

		_yieldSyncV1Vault_members[_yieldSyncV1Vault].push(member);

		_participant_yieldSyncV1Vault_access[member][_yieldSyncV1Vault] = Access({
			admin:  _participant_yieldSyncV1Vault_access[member][_yieldSyncV1Vault].admin,
			member: true
		});
	}

	/// @inheritdoc IYieldSyncV1VaultRecord
	function removeMember(address _yieldSyncV1Vault, address member)
		public
		override
	{
		require(_yieldSyncV1Vault == msg.sender, "!_yieldSyncV1VaultAddress");

		// [update] _member_yieldSyncV1Vaults
		for (uint256 i = 0; i < _member_yieldSyncV1Vaults[member].length; i++)
		{
			if (_member_yieldSyncV1Vaults[member][i] == _yieldSyncV1Vault)
			{
				_member_yieldSyncV1Vaults[member][i] = _member_yieldSyncV1Vaults[member][
					_member_yieldSyncV1Vaults[member].length - 1
				];

				_member_yieldSyncV1Vaults[member].pop();

				break;
			}
		}

		// [update] _yieldSyncV1Vault_members
		for (uint256 i = 0; i < _yieldSyncV1Vault_members[_yieldSyncV1Vault].length; i++)
		{
			if (_yieldSyncV1Vault_members[_yieldSyncV1Vault][i] == member)
			{
				_yieldSyncV1Vault_members[_yieldSyncV1Vault][i] = _yieldSyncV1Vault_members[_yieldSyncV1Vault][
					_yieldSyncV1Vault_members[_yieldSyncV1Vault].length - 1
				];

				_yieldSyncV1Vault_members[_yieldSyncV1Vault].pop();

				break;
			}
		}

		_participant_yieldSyncV1Vault_access[member][_yieldSyncV1Vault] = Access({
			admin: _participant_yieldSyncV1Vault_access[member][_yieldSyncV1Vault].admin,
			member: false
		});
	}
}
