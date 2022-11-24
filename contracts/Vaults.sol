// contracts/Governance.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


contract Vaults {
	/* [STRUCT] */
	
	struct QueuedWithdrawal {
		address requester;

		address[] tokens;

		uint256[] amounts;
	}
	
	struct Vault {
		uint256 id;

		bool strictDeposits;

		uint8 withdrawMinutesDelay;
		
		address[] acceptedTokens;
		
		QueuedWithdrawal[] queuedWithdrawal;
	}


	/* [STATE-VARIABLE] */

	uint256 vaultIdIncrement;

	// Vault IOd => Vault
	mapping(uint256 => Vault) vaults;
	
	// Vault Id => (Address => Voter Weight)
	mapping(uint256 => mapping(address => uint8)) voterWeight;


	/* [CONSTRUCTOR] */
	
	constructor () {
		vaultIdIncrement = 0;
	}

	/**
	 * @notice Creates a Vault and sets the voter weight of msg.sender to 100
	 * @param acceptedTokens_ Array of accepted tokens (pass empty array to accept ALL tokens)
	 * @param withdrawMinutesDelay_ Withdrawal delay (in minutes)
	*/
	function createVault(
		address[] memory acceptedTokens_,
		uint8 withdrawMinutesDelay_
	) public {
		// [INIT]
		QueuedWithdrawal[] memory initialQueuedWithdrawal;

		// [CREATE] Vault
		vaults[vaultIdIncrement] = Vault({
			id: vaultIdIncrement,
			strictDeposits: false,
			withdrawMinutesDelay: withdrawMinutesDelay_,
			acceptedTokens: acceptedTokens_,
			queuedWithdrawal: initialQueuedWithdrawal
		});

		// [MAP] Voter Weight
		voterWeight[vaultIdIncrement][msg.sender] = 100;

		// [INCREMENT]
		vaultIdIncrement++;
	}

	/**
	 * @notice Deposit funds into vault
	*/
	function depositTokens() public {}


	/**
	 * @notice Create a queued withdrawl from vault
	*/
	function createQueuedWithdrawal() public {}


	/**
	 * @notice Delete a queued withdrawal from vault
	*/
	function deleteQueuedWithdrawal() public {}


	/**
	 * @notice
	*/
	function withdrawTokens() public {}

	
	/**
	 * @notice
	*/
	function changeVoterWeight() public {}
}