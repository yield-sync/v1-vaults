// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IIglooFiV1Vault } from "@igloo-fi/v1-sdk/contracts/interface/IIglooFiV1Vault.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

import { IIglooFiV1VaultRecord } from "./interface/IIglooFiV1VaultRecord.sol";


/**
* @title IglooFiV1VaultRecord
*/
contract IglooFiV1VaultRecord is
	Pausable,
	IIglooFiV1VaultRecord
{
	// [address]
	address public iglooFiGovernance;

	// [mapping]
	// iglooFiV1VaultId => iglooFiV1VaultAddress
	mapping (address => uint256) public iglooFiV1VaultAddressToId;
	// iglooFiV1VaultAddress => iglooFiV1VaultId
	mapping (uint256 => address) public iglooFiV1VaultIdToAddress;
	// iglooFiV1VaultAddress => voters[]
	mapping (address => address[]) internal _iglooFiV1VaultVoters;
	// Voter => iglooFiV1VaultAddress[]
	mapping (address => address[]) internal _voterIglooFiV1Vaults;
	
	
	constructor (address _iglooFiGovernance)
	{
		_pause();

		iglooFiGovernance = _iglooFiGovernance;
	}


	modifier onlyIglooFiV1Vault(address _iglooFiV1VaultAddress)
	{
		require(
			iglooFiV1VaultIdToAddress[iglooFiV1VaultAddressToId[_iglooFiV1VaultAddress]] == msg.sender,
			"!_iglooFiV1VaultAddress"
		);

		_;
	}


	function iglooFiV1VaultVoters(address iglooFiV1VaultAddress)
		public
		view
		returns (address[] memory)
	{
		return _iglooFiV1VaultVoters[iglooFiV1VaultAddress];
	}

	function voterIglooFiV1Vaults(address voter)
		public
		view
		returns (address[] memory)
	{
		return _voterIglooFiV1Vaults[voter];
	}


	function addVoter(address _iglooFiV1VaultAddress, address voter)
		public
		override
		onlyIglooFiV1Vault(_iglooFiV1VaultAddress)
	{
		// [update] `iglooFiV1VaultVoters`
		_iglooFiV1VaultVoters[_iglooFiV1VaultAddress].push(voter);

		// [update] `voterIglooFiV1Vaults`
		_voterIglooFiV1Vaults[voter].push(_iglooFiV1VaultAddress);
	}

	function removeVoter(address _iglooFiV1VaultAddress, address voter)
		public
		override
		onlyIglooFiV1Vault(_iglooFiV1VaultAddress)
	{
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