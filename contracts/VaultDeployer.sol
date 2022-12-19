// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [import] */
import "@cardinal-protocol/v1-sdk/contracts/interface/ICardinalProtocolGovernance.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/* [import] Internal */
import "./Vault.sol";


/**
* @title VaultDeployer
* @author harpoonjs.eth
* @notice This contract deploys the vaults on behalf of a user
*/
contract VaultDeployer is
	Pausable
{
	/* [EVENT] */
	event VaultDeployed (
		address indexed admin
	);


	/* [state-variable] */
	address public cardinalProtocol;

	uint256 public vaultId;
	uint256 public fee;

	// Vault Id => Vault Address
	mapping(uint256 => address) public vaults;


	/* [constructor] */
	constructor (address _cardinalProtocol)
	{
		cardinalProtocol = _cardinalProtocol;

		vaultId = 0;
	}


	/** [recieve] */
	receive ()
		external
		payable
	{
		revert(
			"Sending Ether directly to this contract is disabled"
		);
	}


	/** [fallback] */
	fallback ()
		external
		payable
	{
		revert(
			"Sending Ether directly to this contract is disabled"
		);
	}


	/** [modifier] */
	modifier authLevel_s() {
		require(
			ICardinalProtocolGovernance(cardinalProtocol).hasRole(
				ICardinalProtocolGovernance(cardinalProtocol).S(),
				msg.sender
			),
			"!auth"
		);

		_;
	}


	/**
	* %%%%%%%%%%%%%
	* %%% ADMIN %%%
	* %%%%%%%%%%%%%
	*/

	/**
	* @notice Set fee for deploying a vault
	* @param _fee {uint256} Fee to be set
	*/
	function setFee(uint256 _fee)
		public
		authLevel_s()
	{
		fee = _fee;
	}

	/**
	* %%%%%%%%%%%%%%%%%%%%%%
	* %%% NO ROLE NEEDED %%%
	* %%%%%%%%%%%%%%%%%%%%%%
	*/

	/**
	* @notice Creates a Vault
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
		whenNotPaused()
		returns (address)
	{
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
		emit VaultDeployed(admin);

		return address(deployedContract);
	}
}