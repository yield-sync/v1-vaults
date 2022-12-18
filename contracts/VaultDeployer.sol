// contracts/Vault.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [IMPORT] */
// /access
import "@openzeppelin/contracts/access/AccessControl.sol";
// /token
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/* [IMPORT] */
import "./Vault.sol";


/**
 * @title VaultDeployer
 * @author harpoonjs.eth
 * @notice This contract deploys the vaults on behalf of a user
*/
contract VaultDeployer is AccessControl {
	/* [EVENT] */
	event VaultDeployed (
		address indexed admin
	);


	/* [STATE-VARIABLES] */
	uint public vaultId;

	// Vault Id => Vault Address
	mapping(uint => address) public vaults;


	/* [CONSTRUCTOR] */
	constructor ()
	{
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		
		vaultId = 0;
	}


	/* [RECIEVE] */
	receive ()
		external
		payable
	{}


	/* [FALLBACK] */
	fallback ()
		external
		payable
	{}


	/**
	 * @notice Creates a Vault and sets the voter weight of msg.sender to 100
	 * @param requiredSignatures_ number of required signatures to make a withdrawal
	 * @param withdrawalDelayMinutes_ number of minutes to delay a withdrawal
	 * @param voters_ addresses of voter accounts
	*/
	function deploy(
		address admin,
		uint256 requiredSignatures_,
		uint256 withdrawalDelayMinutes_,
		address[] memory voters_
	)
		public
		returns (address)
	{
		Vault deployedContract;

		// Deploy the Vault contract and assign it to the vault state variable
		deployedContract = new Vault(
			admin,
			requiredSignatures_,
			withdrawalDelayMinutes_,
			voters_
		);

		// Store the address of the newly deployed Vault contract in the vaults mapping
		vaults[vaultId] = address(deployedContract);

		// Increment the vaultId variable
		vaultId++;

		// [EMIT]
		emit VaultDeployed(admin);

		return address(deployedContract);
	}
}