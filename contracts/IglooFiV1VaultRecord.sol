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
	// iglooFiV1VaultAddress => voters
	mapping (address => address[]) internal _iglooFiV1VaultVoters;
	// Voter => iglooFiV1VaultAddress
	mapping (address => address[]) internal _voterIglooFiV1Vaults;

	mapping (address => mapping (address => Access)) internal participant_vault_access;
	mapping (address => address[]) internal _member_vaults;
	mapping (address => address[]) internal _admin_vaults;
	mapping (address => address[]) internal _vault_members;
	mapping (address => address[]) internal _vault_admins;


	constructor (address _iglooFiV1VaultFactory)
	{
		iglooFiV1VaultFactory = _iglooFiV1VaultFactory;
	}


	/// @inheritdoc IIglooFiV1VaultRecord
	function iglooFiV1VaultVoters(address iglooFiV1VaultAddress)
		public
		view
		returns (address[] memory)
	{
		return _iglooFiV1VaultVoters[iglooFiV1VaultAddress];
	}

	/// @inheritdoc IIglooFiV1VaultRecord
	function voterIglooFiV1Vaults(address voter)
		public
		view
		returns (address[] memory)
	{
		return _voterIglooFiV1Vaults[voter];
	}


	// @inheritdoc
	function getsVaultsVoterAndAdminOf()
		public
		view
		returns (address[] memory)
	{
		address[] memory vaults = new address[](
			IIglooFiV1VaultFactory(payable(iglooFiV1VaultFactory)).vaultIdTracker()
		);
		
		for (uint256 i = 0; i < IIglooFiV1VaultFactory(payable(iglooFiV1VaultFactory)).vaultIdTracker(); i++)
		{
			if (true)
			{
				vaults[i] = IIglooFiV1VaultFactory(payable(iglooFiV1VaultFactory)).iglooFiV1VaultIdToAddress(i);
			}
		}

		return vaults;
	}


	/// @inheritdoc IIglooFiV1VaultRecord
	function addVoter(address _iglooFiV1VaultAddress, address voter)
		public
		override
	{
		require(_iglooFiV1VaultAddress == msg.sender, "!_iglooFiV1VaultAddress");

		// [update] `iglooFiV1VaultVoters`
		_iglooFiV1VaultVoters[_iglooFiV1VaultAddress].push(voter);

		// [update] `voterIglooFiV1Vaults`
		_voterIglooFiV1Vaults[voter].push(_iglooFiV1VaultAddress);
	}

	/// @inheritdoc IIglooFiV1VaultRecord
	function removeVoter(address _iglooFiV1VaultAddress, address voter)
		public
		override
	{
		require(_iglooFiV1VaultAddress == msg.sender, "!_iglooFiV1VaultAddress");

		// [update] iglooFiV1VaultVoters
		for (uint256 i = 0; i < _iglooFiV1VaultVoters[_iglooFiV1VaultAddress].length; i++)
		{
			if (_iglooFiV1VaultVoters[_iglooFiV1VaultAddress][i] == voter)
			{
				_iglooFiV1VaultVoters[_iglooFiV1VaultAddress][i] = _iglooFiV1VaultVoters[_iglooFiV1VaultAddress][
					_iglooFiV1VaultVoters[_iglooFiV1VaultAddress].length - 1
				];

				_iglooFiV1VaultVoters[_iglooFiV1VaultAddress].pop();

				break;
			}
		}

		// [update] voterIglooFiV1Vaults
		for (uint256 i = 0; i < _voterIglooFiV1Vaults[voter].length; i++)
		{
			if (_voterIglooFiV1Vaults[voter][i] == voter)
			{
				_voterIglooFiV1Vaults[voter][i] = _voterIglooFiV1Vaults[voter][_voterIglooFiV1Vaults[voter].length - 1];
				
				_voterIglooFiV1Vaults[voter].pop();

				break;
			}
		}
	}
}