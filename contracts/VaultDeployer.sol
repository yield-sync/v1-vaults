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
	/* [STATE-VARIABLES] */
	uint256 vaultIdIncrement;


	/* [CONSTRUCTOR] */
	constructor ()
	{
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		
		vaultIdIncrement = 0;
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
	*/
	function createVault(
	)
		public
	{
		// [INCREMENT]
		vaultIdIncrement++;
	}
}