// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IIglooFiGovernance } from "@igloo-fi/v1-sdk/contracts/interface/IIglooFiGovernance.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

import { IglooFiV1Vault } from "./IglooFiV1Vault.sol";
import { IIglooFiV1VaultFactory } from "./interface/IIglooFiV1VaultFactory.sol";


/**
* @title IglooFiV1VaultFactory
*/
contract IglooFiV1VaultFactory is
	Pausable,
	IIglooFiV1VaultFactory
{
	// [address][public]
	address public override iglooFiGovernance;
	address public override defaultSignatureManager;

	// [uint256][public]
	uint256 public override fee;

	// [uint256][internal]
	uint256 internal _vaultIdTracker;

	// [mapping][internal]
	// iglooFiV1VaultId => iglooFiV1VaultAddress
	mapping (uint256 => address) internal _vaultAddress;


	constructor (address _iglooFiGovernance)
	{
		_pause();

		iglooFiGovernance = _iglooFiGovernance;

		_vaultIdTracker = 0;
		
		fee = 0;
	}


	receive ()
		external
		payable
		override
	{}


	fallback ()
		external
		payable
		override
	{}


	modifier onlyIglooFiGovernanceAdmin() {
		require(
			IIglooFiGovernance(iglooFiGovernance).hasRole(
				IIglooFiGovernance(iglooFiGovernance).governanceRoles("DEFAULT_ADMIN_ROLE"),
				_msgSender()
			),
			"!auth"
		);

		_;
	}


	/// @inheritdoc IIglooFiV1VaultFactory
	function vaultAddress(uint256 iglooFiV1VaultAddress)
		public
		view
		override
		returns (address)
	{
		return _vaultAddress[iglooFiV1VaultAddress];
	}


	/// @inheritdoc IIglooFiV1VaultFactory
	function deployVault(
		address admin,
		address signatureManager,
		bool useDefaultSignatureManager,
		uint256 requiredVoteCount,
		uint256 withdrawalDelaySeconds
	)
		public
		payable
		override
		whenNotPaused()
		returns (address)
	{
		require(msg.value >= fee, "!msg.value");

		// [deploy] A vault contract
		IglooFiV1Vault deployedContract = new IglooFiV1Vault(
			admin,
			useDefaultSignatureManager ? defaultSignatureManager : signatureManager,
			requiredVoteCount,
			withdrawalDelaySeconds
		);

		// Register vault
		_vaultAddress[_vaultIdTracker] = address(deployedContract);

		// [increment] vaultId
		_vaultIdTracker++;

		// [emit]
		emit VaultDeployed(address(deployedContract));

		// [return]
		return address(deployedContract);
	}


	/// @inheritdoc IIglooFiV1VaultFactory
	function setPause(bool pause)
		public
		override
		onlyIglooFiGovernanceAdmin()
	{
		if (pause)
		{
			// [call-internal]
			_pause();
		}
		else
		{
			// [call-internal]
			_unpause();
		}
	}


	/// @inheritdoc IIglooFiV1VaultFactory
	function updateDefaultSignatureManager(address _defaultSignatureManager)
		public
		override
		whenNotPaused()
		onlyIglooFiGovernanceAdmin()
	{
		defaultSignatureManager = _defaultSignatureManager;

		emit UpdatedDefaultSignatureManager(defaultSignatureManager);
	}

	/// @inheritdoc IIglooFiV1VaultFactory
	function updateFee(uint256 _fee)
		public
		override
		onlyIglooFiGovernanceAdmin()
	{
		fee = _fee;

		emit UpdatedFee(fee);
	}

	/// @inheritdoc IIglooFiV1VaultFactory
	function transferFunds(address transferTo)
		public
		override
		whenNotPaused()
		onlyIglooFiGovernanceAdmin()
	{
		// [transfer]
		(bool success, ) = transferTo.call{value: address(this).balance}("");

		require(success, "Failed");
	}
}