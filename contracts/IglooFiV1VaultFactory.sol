// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [import] */
import { console } from "hardhat/console.sol";
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
	/* [state-variable] */
	// [address][public][to-be-constant]
	address public override IGLOO_FI;

	/* [uint256][internal] */
	uint256 internal _vaultId;

	/* [uint256][public] */
	uint256 public override fee;

	// [mapping][internal]
	// Vault Id => Contract address
	mapping (uint256 => address) internal _vaultAddress;


	/* [constructor] */
	constructor (address iglooFi)
	{
		IGLOO_FI = iglooFi;

		_vaultId = 0;
		fee = 0;
	}


	/* [recieve] */
	receive ()
		external
		payable
	{}


	/* [fallback] */
	fallback ()
		external
		payable
	{}


	/* [modifier] */
	modifier onlyIFGAdmin() {
		require(
			IIglooFiGovernance(IGLOO_FI).hasRole(
				IIglooFiGovernance(IGLOO_FI).governanceRoles("DEFAULT_ADMIN_ROLE"),
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
		address admin,
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
		deployedContract = new IglooFiV1Vault(
			admin,
			_requiredVoteCount,
			_withdrawalDelaySeconds
		);

		// Register vault
		_vaultAddress[_vaultId] = address(deployedContract);

		// [increment] vaultId
		_vaultId++;

		// [emit]
		emit VaultDeployed(address(deployedContract));

		// [return]
		return address(deployedContract);
	}


	/// @inheritdoc IIglooFiV1VaultFactory
	function togglePause()
		public
		override
		onlyIFGAdmin()
	{
		if (!paused())
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
		onlyIFGAdmin()
		returns (uint256)
	{
		fee = newFee;

		emit UpdatedFee(fee);

		return (fee);
	}

	/// @inheritdoc IIglooFiV1VaultFactory
	function transferFunds(address transferTo)
		public
		override
		whenNotPaused()
		onlyIFGAdmin()
	{
		require(transferTo != address(0), "!transferTo");

		// [transfer]
		(bool success, ) = transferTo.call{value: address(this).balance}("");

		require(success, "transferFunds Failed");
	}
}