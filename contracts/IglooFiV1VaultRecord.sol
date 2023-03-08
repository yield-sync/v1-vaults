// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IIglooFiV1Vault } from "@igloo-fi/v1-sdk/contracts/interface/IIglooFiV1Vault.sol";

import { IIglooFiV1VaultFactory } from "./interface/IIglooFiV1VaultFactory.sol";
import { IIglooFiV1VaultRecord } from "./interface/IIglooFiV1VaultRecord.sol";


struct Access {
	bool admin;
	bool member;
}


/**
* @title IglooFiV1VaultRecord
*/
contract IglooFiV1VaultRecord is
	IIglooFiV1VaultRecord
{
	address public iglooFiV1VaultFactory;

	// [mapping]
	// admin => iglooFiV1Vaults
	mapping (address => address[]) internal _admin_iglooFiV1Vaults;
	// iglooFiV1Vault => admins
	mapping (address => address[]) internal _iglooFiV1Vault_admins;
	// iglooFiV1Vault => members
	mapping (address => address[]) internal _iglooFiV1Vault_members;
	// member => iglooFiV1Vaults
	mapping (address => address[]) internal _member_iglooFiV1Vaults;
	// participant => (iglooFiV1Vault => access)
	mapping (address => mapping (address => Access)) internal _participant_iglooFiV1Vault_access;


	constructor (address _iglooFiV1VaultFactory)
	{
		iglooFiV1VaultFactory = _iglooFiV1VaultFactory;
	}


	/// @inheritdoc IIglooFiV1VaultRecord
	function admin_iglooFiV1Vaults(address admin)
		public
		view
		override
		returns (address[] memory)
	{
		return _admin_iglooFiV1Vaults[admin];
	}

	/// @inheritdoc IIglooFiV1VaultRecord
	function iglooFiV1Vault_admins(address iglooFiV1Vault)
		public
		view
		override
		returns (address[] memory)
	{
		return _iglooFiV1Vault_admins[iglooFiV1Vault];
	}

	/// @inheritdoc IIglooFiV1VaultRecord
	function iglooFiV1Vault_members(address iglooFiV1Vault)
		public
		view
		override
		returns (address[] memory)
	{
		return _iglooFiV1Vault_members[iglooFiV1Vault];
	}

	/// @inheritdoc IIglooFiV1VaultRecord
	function member_iglooFiV1Vaults(address member)
		public
		view
		override
		returns (address[] memory)
	{
		return _member_iglooFiV1Vaults[member];
	}

	/// @inheritdoc IIglooFiV1VaultRecord
	function participant_iglooFiV1Vault_access(address participant, address iglooFiV1Vault)
		public
		view
		override
		returns (bool admin, bool member)
	{
		admin = _participant_iglooFiV1Vault_access[participant][iglooFiV1Vault].admin;
		member = _participant_iglooFiV1Vault_access[participant][iglooFiV1Vault].member;
	}


	/// @inheritdoc IIglooFiV1VaultRecord
	function addMember(address _iglooFiV1Vault, address member)
		public
		override
	{
		require(_iglooFiV1Vault == msg.sender, "!_iglooFiV1Vault");

		_member_iglooFiV1Vaults[member].push(_iglooFiV1Vault);

		_iglooFiV1Vault_members[_iglooFiV1Vault].push(member);

		_participant_iglooFiV1Vault_access[member][_iglooFiV1Vault] = Access({
			admin: false,
			member: true
		});
	}

	/// @inheritdoc IIglooFiV1VaultRecord
	function removeMember(address _iglooFiV1Vault, address member)
		public
		override
	{
		require(_iglooFiV1Vault == msg.sender, "!_iglooFiV1VaultAddress");

		// [update] _member_iglooFiV1Vaults
		for (uint256 i = 0; i < _member_iglooFiV1Vaults[member].length; i++)
		{
			if (_member_iglooFiV1Vaults[member][i] == member)
			{
				_member_iglooFiV1Vaults[member][i] = _member_iglooFiV1Vaults[member][
					_member_iglooFiV1Vaults[member].length - 1
				];

				_member_iglooFiV1Vaults[member].pop();

				break;
			}
		}

		// [update] _iglooFiV1Vault_members
		for (uint256 i = 0; i < _iglooFiV1Vault_members[_iglooFiV1Vault].length; i++)
		{
			if (_iglooFiV1Vault_members[_iglooFiV1Vault][i] == member)
			{
				_iglooFiV1Vault_members[_iglooFiV1Vault][i] = _iglooFiV1Vault_members[_iglooFiV1Vault][
					_iglooFiV1Vault_members[_iglooFiV1Vault].length - 1
				];

				_iglooFiV1Vault_members[_iglooFiV1Vault].pop();

				break;
			}
		}

		_participant_iglooFiV1Vault_access[member][_iglooFiV1Vault] = Access({
			admin: _participant_iglooFiV1Vault_access[member][_iglooFiV1Vault].admin,
			member: false
		});
	}
}