// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [import] */
import "@igloo-fi/v1-sdk/contracts/interface/IIglooFiGovernance.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interface/IIglooFiV1VaultFactory.sol";
import "./IglooFiV1Vault.sol";


/**
* @title Igloo Fi V1 Vault Factory
*/
contract IglooFiV1VaultFactory is
	Pausable,
	IIglooFiVaultFactory
{
	/* [state-variable][constant] */
	address public constant IGLOO_FI;

	/* [state-variable] */
	uint256 internal _vaultId;
	uint256 internal _vaultFee;

	// Vault Id => Address
	mapping (uint256 => address) internal _vaultAddress;


	/* [constructor] */
	constructor (address iglooFi)
	{
		IGLOO_FI = iglooFi;

		_vaultId = 0;
		_vaultFee = 0;
	}


	/* [recieve] */
	receive ()
		external
		payable
	{
		revert("Sending Ether directly to this contract is disabled");
	}


	/* [fallback] */
	fallback ()
		external
		payable
	{
		revert("Sending Ether directly to this contract is disabled");
	}


	/* [modifier] */
	modifier authLevelS() {
		require(
			IIglooFiGovernance(IGLOO_FI).hasRole(
				IIglooFiGovernance(IGLOO_FI).S(),
				msg.sender
			),
			"!auth"
		);

		_;
	}


	/**
	* @notice Get vault deployment fee
	*
	* @dev [!restriction]
	*
	* @dev [view]
	*
	* @return {uint256}
	*/
	function vaultFee()
		public
		view
		returns (uint256)
	{
		return _vaultFee;
	}


	/**
	* @notice Get vault address
	*
	* @dev [!restriction]
	*
	* @dev [view]
	*
	* @param vaultId {uint256}
	*
	* @return {uint256}
	*/
	function vaultAddress(uint256 vaultId)
		public
		view
		returns (address)
	{
		return _vaultAddress[vaultId];
	}


	/**
	* @notice Creates a Vault
	*
	* @dev [!restriction]
	*
	* @dev [create]
	*
	* @param requiredApproveVotes {uint256}
	* @param withdrawalDelayMinutes {uint256}
	* @param voters {address[]} Addresses to be assigned VOTER_ROLE
	*/
	function deployVault(
		uint256 requiredApproveVotes,
		uint256 withdrawalDelayMinutes,
		address[] memory voters
	)
		public
		payable
		whenNotPaused()
		returns (address)
	{
		require(msg.value >= _vaultFee, "!msg.value");

		Vault deployedContract;

		// [deploy] A vault contract
		deployedContract = new Vault(
			requiredApproveVotes,
			withdrawalDelayMinutes,
			voters
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


	/**
	* @notice Toggle pause
	*
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	*
	* @dev [update] pause
	*/
	function togglePause()
		public
		authLevelS()
	{
		if (!paused())
		{
			_pause();
		}
		else
		{
			_unpause();
		}
	}

	/**
	* @notice Set fee for Vault.sol deployment
	*
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	*
	* @dev [update] fee
	*
	* @param _fee {uint256} Fee to be set
	*/
	function setFeeVault(uint256 _fee)
		public
		authLevelS()
		whenPaused()
	{
		_vaultFee = _fee;
	}
}