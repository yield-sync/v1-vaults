// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IIglooFiGovernance } from "@igloo-fi/v1-sdk/contracts/interface/IIglooFiGovernance.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

import { IIglooFiV1Vault } from "@igloo-fi/v1-sdk/contracts/interface/IIglooFiV1Vault.sol";


/**
* @title IglooFiV1VaultRecord
*/
contract IglooFiV1VaultRecord is
	Pausable
{
	// [address]
	address public iglooFiGovernance;

	// [mapping]
	// iglooFiV1VaultId => iglooFiV1VaultAddress
	mapping (address => uint256) internal _iglooFiV1VaultAddressToId;
	mapping (uint256 => address) internal _iglooFiV1VaultIdToAddress;
	// iglooFiV1VaultAddress => Voters[]
	mapping (address => address[]) public iglooFiV1VaultVoters;
	// Voter => iglooFiV1VaultAddress[]
	mapping (address => address[]) public voterIglooFiV1Vaults;
	
	
	constructor (address _iglooFiGovernance)
	{
		_pause();

		iglooFiGovernance = _iglooFiGovernance;
	}


	modifier onlyIglooFiV1Vault(address _iglooFiV1VaultAddress)
	{
		require(
			_iglooFiV1VaultIdToAddress[_iglooFiV1VaultAddressToId[_iglooFiV1VaultAddress]] == msg.sender,
			"!_iglooFiV1VaultAddress"
		);

		_;
	}


	function iglooFiV1VaultAddressToId(address iglooFiV1VaultAddress)
		public
		view
		returns (uint256)
	{
		return _iglooFiV1VaultAddressToId[iglooFiV1VaultAddress];
	}

	function iglooFiV1VaultIdToAddress(uint256 iglooFiV1VaultId)
		public
		view
		returns (address)
	{
		return _iglooFiV1VaultIdToAddress[iglooFiV1VaultId];
	}


	function addVoter(address _iglooFiV1VaultAddress, address voter)
		public
		onlyIglooFiV1Vault(_iglooFiV1VaultAddress)
	{
		// [update] iglooFiV1VaultVoters
		iglooFiV1VaultVoters[_iglooFiV1VaultAddress].push(voter);

		// [update] voterIglooFiV1Vaults
		voterIglooFiV1Vaults[voter].push(_iglooFiV1VaultAddress);
	}

	function removeVoter(address _iglooFiV1VaultAddress, address voter)
		public
		onlyIglooFiV1Vault(_iglooFiV1VaultAddress)
	{
		// [update] iglooFiV1VaultVoters
		for (uint256 i = 0; i < iglooFiV1VaultVoters[_iglooFiV1VaultAddress].length; i++)
		{
			if (iglooFiV1VaultVoters[_iglooFiV1VaultAddress][i] == voter)
			{
				iglooFiV1VaultVoters[_iglooFiV1VaultAddress][i] = iglooFiV1VaultVoters[_iglooFiV1VaultAddress][
					iglooFiV1VaultVoters[_iglooFiV1VaultAddress].length - 1
				];

				iglooFiV1VaultVoters[_iglooFiV1VaultAddress].pop();

				break;
			}
		}

		// [update] voterIglooFiV1Vaults
		for (uint256 i = 0; i < voterIglooFiV1Vaults[voter].length; i++)
		{
			if (voterIglooFiV1Vaults[voter][i] == voter)
			{
				voterIglooFiV1Vaults[voter][i] = voterIglooFiV1Vaults[voter][voterIglooFiV1Vaults[voter].length - 1];
				
				iglooFiV1VaultVoters[voter].pop();

				break;
			}
		}
	}
}