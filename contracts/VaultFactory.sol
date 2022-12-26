// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [import] */
import "@cardinal-protocol/v1-sdk/contracts/interface/ICardinalProtocolGovernance.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interface/IVaultFactory.sol";
import "./VaultAdminControlled.sol";


/**
* @title VaultFactory
*/
contract VaultFactory is
	Pausable,
	IVaultFactory
{
	/* [state-variable][constant] */
	address public CARDINAL_PROTOCOL;

	/* [state-variable] */
	uint256 public fee;

	uint256 internal _vaultId;

	// Vault Id => Vault Address
	mapping (uint256 => address) _vaultAddress;


	/* [constructor] */
	constructor (address _cardinalProtocol)
	{
		CARDINAL_PROTOCOL = _cardinalProtocol;

		fee = 0;

		_vaultId = 0;
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
			ICardinalProtocolGovernance(CARDINAL_PROTOCOL).hasRole(
				ICardinalProtocolGovernance(CARDINAL_PROTOCOL).S(),
				msg.sender
			),
			"!auth"
		);

		_;
	}


	/**
	* @notice Get the address of vault with the given Id
	*
	* @dev [getter]
	*
	* @param vaultId {uint256}
	*
	* @return {address} Vault
	*/
	function vaultAddresses(uint256 vaultId)
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
		require(msg.value >= fee, "!msg.value");

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
	* @notice Set fee for deploying a vault
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [update] fee
	* @param _fee {uint256} Fee to be set
	*/
	function setFee(uint256 _fee)
		public
		authLevelS()
		whenPaused()
	{
		fee = _fee;
	}
}