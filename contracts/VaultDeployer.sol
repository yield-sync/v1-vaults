// contracts/Vault.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [IMPORT] Internal */
import "./interface/ICardinalProtocolGovernance.sol";
import "./Vault.sol";


/**
* @title VaultDeployer
* @author harpoonjs.eth
* @notice This contract deploys the vaults on behalf of a user
*/
contract VaultDeployer {
	/* [EVENT] */
	event VaultDeployed (
		address indexed admin
	);


	/* [STATE-VARIABLES] */
	address public cardinalProtocol;

	uint256 public vaultId;
	uint256 public fee;

	// Vault Id => Vault Address
	mapping(uint256 => address) public vaults;


	/* [CONSTRUCTOR] */
	constructor (address _cardinalProtocol)
	{
		cardinalProtocol = _cardinalProtocol;

		vaultId = 0;
	}


	/** [RECIEVE] */
	receive ()
		external
		payable
	{
		revert(
			"Sending Ether directly to this contract is disabled"
		);
	}


	/** [FALLBACK] */
	fallback ()
		external
		payable
	{
		revert(
			"Sending Ether directly to this contract is disabled"
		);
	}


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
		returns (address)
	{
		Vault deployedContract;

		// Deploy the Vault contract and assign it to the vault state variable
		deployedContract = new Vault(
			admin,
			requiredSignatures,
			withdrawalDelayMinutes,
			voters
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