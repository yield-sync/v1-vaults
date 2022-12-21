// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [import] */
import "@cardinal-protocol/v1-sdk/contracts/interface/ICardinalProtocolGovernance.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/* [import-Internal] */
import "./interface/IVaultDeployer.sol";
import "./Vault.sol";


/**
* @title VaultDeployer
*/
contract VaultDeployer is
	Pausable,
	IVaultDeployer
{
	/* [state-variable][constant] */
	address public CARDINAL_PROTOCOL;

	/* [state-variable] */
	uint256 public vaultId;
	uint256 public fee;

	// Vault Id => Vault Address
	mapping(uint256 => address) public vaults;


	/* [constructor] */
	constructor (address _cardinalProtocol)
	{
		CARDINAL_PROTOCOL = _cardinalProtocol;

		vaultId = 0;
		fee = 0;
	}


	/* [recieve] */
	receive ()
		external
		payable
	{
		revert(
			"Sending Ether directly to this contract is disabled"
		);
	}


	/* [fallback] */
	fallback ()
		external
		payable
	{
		revert(
			"Sending Ether directly to this contract is disabled"
		);
	}


	/* [modifier] */
	modifier authLevel_s() {
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
	* @notice Toggle pause
	* @dev [restriction] AccessControl: DEFAULT_ADMIN_ROLE
	* @dev [update] pause
	*/
	function togglePause()
		public
		authLevel_s()
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
	* @dev [restriction] AccessControl: DEFAULT_ADMIN_ROLE
	* @dev [update] fee
	* @param _fee {uint256} Fee to be set
	*/
	function setFee(uint256 _fee)
		public
		authLevel_s()
		whenPaused()
	{
		fee = _fee;
	}


	/**
	* @notice Creates a Vault
	* @dev [!restriction]
	* @dev [create]
	* @param admin {address} Admin of the deployed contract
	* @param requiredSignatures {uint256} Required signatures for actions
	* @param withdrawalDelayMinutes {uint256} Withdrawal delay minutes
	* @param voters {address[]} Addresses of voter accounts
	*/
	function deploy(
		address admin,
		uint256 requiredSignatures,
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
			admin,
			requiredSignatures,
			withdrawalDelayMinutes,
			voters
		);

		// Store the address of the newly deployed Vault contract
		vaults[vaultId] = address(deployedContract);

		// [increment] vaultId
		vaultId++;

		// [emit]
		emit VaultDeployed(address(deployedContract), admin);

		return address(deployedContract);
	}
}