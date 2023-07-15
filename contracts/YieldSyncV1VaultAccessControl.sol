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
	mapping (address admin => address[] yieldSyncV1VaultsAddresses) internal _admin_yieldSyncV1VaultsAddresses;
	mapping (address member => address[] yieldSyncV1VaultsAddresses) internal _member_yieldSyncV1VaultsAddresses;
	mapping (address yieldSyncV1VaultAddress => address[] admins) internal _yieldSyncV1VaultAddress_admins;
	mapping (address yieldSyncV1VaultAddress => address[] members) internal _yieldSyncV1VaultAddress_members;

	mapping (
		address yieldSyncV1VaultAddress => mapping (address participant => Access access)
	) internal _yieldSyncV1VaultAddress_participant_access;


	modifier contractYieldSyncV1Vault(address yieldSyncV1VaultAddress)
	{
		require(yieldSyncV1VaultAddress == msg.sender, "!yieldSyncV1VaultAddress");

		_;
	}


	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function admin_yieldSyncV1VaultsAddresses(address admin)
		public
		view
		override
		returns (address[] memory)
	{
		return _admin_yieldSyncV1VaultsAddresses[admin];
	}

		/// @inheritdoc IYieldSyncV1VaultAccessControl
	function member_yieldSyncV1VaultsAddresses(address member)
		public
		view
		override
		returns (address[] memory)
	{
		return _member_yieldSyncV1VaultsAddresses[member];
	}

	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function yieldSyncV1VaultAddress_admins(address yieldSyncV1Vault)
		public
		view
		override
		returns (address[] memory)
	{
		return _yieldSyncV1VaultAddress_admins[yieldSyncV1Vault];
	}

	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function yieldSyncV1VaultAddress_members(address yieldSyncV1Vault)
		public
		view
		override
		returns (address[] memory)
	{
		return _yieldSyncV1VaultAddress_members[yieldSyncV1Vault];
	}

	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function yieldSyncV1VaultAddress_participant_access(address yieldSyncV1VaultAddress, address participant)
		public
		view
		override
		returns (bool admin, bool member)
	{
		admin = _yieldSyncV1VaultAddress_participant_access[yieldSyncV1VaultAddress][participant].admin;
		member = _yieldSyncV1VaultAddress_participant_access[yieldSyncV1VaultAddress][participant].member;
	}


	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function adminAdd(address yieldSyncV1VaultAddress, address target)
		public
		override
		contractYieldSyncV1Vault(yieldSyncV1VaultAddress)
	{
		require(!_yieldSyncV1VaultAddress_participant_access[yieldSyncV1VaultAddress][target].admin, "Already admin");

		_admin_yieldSyncV1VaultsAddresses[target].push(yieldSyncV1VaultAddress);

		_yieldSyncV1VaultAddress_admins[yieldSyncV1VaultAddress].push(target);

		_yieldSyncV1VaultAddress_participant_access[yieldSyncV1VaultAddress][target] = Access({
			member: _yieldSyncV1VaultAddress_participant_access[yieldSyncV1VaultAddress][target].member,
			admin: true
		});
	}

	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function adminRemove(address yieldSyncV1VaultAddress, address admin)
		public
		override
		contractYieldSyncV1Vault(yieldSyncV1VaultAddress)
	{
		require(_yieldSyncV1VaultAddress_participant_access[yieldSyncV1VaultAddress][admin].admin, "Not admin");

		// [update] _admin_yieldSyncV1Vaults
		for (uint256 i = 0; i < _admin_yieldSyncV1VaultsAddresses[admin].length; i++)
		{
			if (_admin_yieldSyncV1VaultsAddresses[admin][i] == yieldSyncV1VaultAddress)
			{
				_admin_yieldSyncV1VaultsAddresses[admin][i] = _admin_yieldSyncV1VaultsAddresses[admin][
					_admin_yieldSyncV1VaultsAddresses[admin].length - 1
				];

				_admin_yieldSyncV1VaultsAddresses[admin].pop();

				break;
			}
		}

		// [update] _yieldSyncV1VaultAddress_admins
		for (uint256 i = 0; i < _yieldSyncV1VaultAddress_admins[yieldSyncV1VaultAddress].length; i++)
		{
			if (_yieldSyncV1VaultAddress_admins[yieldSyncV1VaultAddress][i] == admin)
			{
				_yieldSyncV1VaultAddress_admins[yieldSyncV1VaultAddress][i] = _yieldSyncV1VaultAddress_admins[
					yieldSyncV1VaultAddress
				][
					_yieldSyncV1VaultAddress_admins[yieldSyncV1VaultAddress].length - 1
				];

				_yieldSyncV1VaultAddress_admins[yieldSyncV1VaultAddress].pop();

				break;
			}
		}

		_yieldSyncV1VaultAddress_participant_access[yieldSyncV1VaultAddress][admin] = Access({
			admin: false,
			member: _yieldSyncV1VaultAddress_participant_access[yieldSyncV1VaultAddress][admin].member
		});
	}

	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function memberAdd(address yieldSyncV1VaultAddress, address target)
		public
		override
		contractYieldSyncV1Vault(yieldSyncV1VaultAddress)
	{
		require(!_yieldSyncV1VaultAddress_participant_access[yieldSyncV1VaultAddress][target].member, "Already member");

		_member_yieldSyncV1VaultsAddresses[target].push(yieldSyncV1VaultAddress);

		_yieldSyncV1VaultAddress_members[yieldSyncV1VaultAddress].push(target);

		_yieldSyncV1VaultAddress_participant_access[yieldSyncV1VaultAddress][target] = Access({
			admin:  _yieldSyncV1VaultAddress_participant_access[yieldSyncV1VaultAddress][target].admin,
			member: true
		});
	}

	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function memberRemove(address yieldSyncV1VaultAddress, address member)
		public
		override
		contractYieldSyncV1Vault(yieldSyncV1VaultAddress)
	{
		require(_yieldSyncV1VaultAddress_participant_access[yieldSyncV1VaultAddress][member].member, "Not member");

		// [update] _member_yieldSyncV1Vaults
		for (uint256 i = 0; i < _member_yieldSyncV1VaultsAddresses[member].length; i++)
		{
			if (_member_yieldSyncV1VaultsAddresses[member][i] == yieldSyncV1VaultAddress)
			{
				_member_yieldSyncV1VaultsAddresses[member][i] = _member_yieldSyncV1VaultsAddresses[member][
					_member_yieldSyncV1VaultsAddresses[member].length - 1
				];

				_member_yieldSyncV1VaultsAddresses[member].pop();

				break;
			}
		}

		// [update] _yieldSyncV1VaultAddress_members
		for (uint256 i = 0; i < _yieldSyncV1VaultAddress_members[yieldSyncV1VaultAddress].length; i++)
		{
			if (_yieldSyncV1VaultAddress_members[yieldSyncV1VaultAddress][i] == member)
			{
				_yieldSyncV1VaultAddress_members[yieldSyncV1VaultAddress][i] = _yieldSyncV1VaultAddress_members[
					yieldSyncV1VaultAddress
				][
					_yieldSyncV1VaultAddress_members[yieldSyncV1VaultAddress].length - 1
				];

				_yieldSyncV1VaultAddress_members[yieldSyncV1VaultAddress].pop();

				break;
			}
		}

		_yieldSyncV1VaultAddress_participant_access[yieldSyncV1VaultAddress][member] = Access({
			admin: _yieldSyncV1VaultAddress_participant_access[yieldSyncV1VaultAddress][member].admin,
			member: false
		});
	}
}
