// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


import { IIglooFiGovernance } from "@igloo-fi/v1-sdk/contracts/interface/IIglooFiGovernance.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

import { IIglooFiV1VaultFactory } from "./interface/IIglooFiV1VaultFactory.sol";
import { IglooFiV1Vault } from "./IglooFiV1Vault.sol";


/**
* @title IglooFiV1VaultFactory
*/
contract IglooFiV1VaultFactory is
	Pausable,
	IIglooFiV1VaultFactory
{
	// [address][public]
	address public override iglooFiGovernance;
	// [address][public]
	address public signatureManager;

	/* [uint256][internal] */
	uint256 internal _vaultIdTracker;

	/* [uint256][public] */
	uint256 public override fee;

	// [mapping][internal]
	// Vault Id => Contract address
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
	{}


	fallback ()
		external
		payable
	{}


	modifier onlyIglooFiGovernanceAdmin() {
		require(
			IIglooFiGovernance(iglooFiGovernance).hasRole(
				IIglooFiGovernance(iglooFiGovernance).governanceRoles("DEFAULT_ADMIN_ROLE"),
				msg.sender
			),
			"!auth"
		);

		_;
	}


	/// @inheritdoc IIglooFiV1VaultFactory
	function vaultAddress(uint256 vaultId)
		public
		view
		override
		returns (address)
	{
		return _vaultAddress[vaultId];
	}


	/// @inheritdoc IIglooFiV1VaultFactory
	function deployVault(
		address _admin,
		uint256 _requiredVoteCount,
		uint256 _withdrawalDelaySeconds
	)
		public
		payable
		override
		whenNotPaused()
		returns (address)
	{
		require(msg.value >= fee, "!msg.value");

		IglooFiV1Vault deployedContract;

		// [deploy] A vault contract
		deployedContract = new IglooFiV1Vault(_admin, signatureManager, _requiredVoteCount, _withdrawalDelaySeconds);

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
	function updateFee(uint256 newFee)
		public
		override
		onlyIglooFiGovernanceAdmin()
	{
		fee = newFee;

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


	/// @inheritdoc IIglooFiV1VaultFactory
	function updateSignatureManager(address _signatureManager)
		public
		override
		whenNotPaused()
		onlyIglooFiGovernanceAdmin()
	{
		signatureManager = _signatureManager;
	}
}