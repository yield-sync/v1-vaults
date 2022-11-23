// contracts/Governance.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


contract Vaults {	
	/* [STRUCT] */
	
	struct WithdrawalRequest {
		address requester;

		address[] tokens;

		uint256[] amounts;
	}
	
	struct Vault {
		uint256 id;

		uint256 withdrawMinutesDelay;
		
		address[] acceptedTokens;
		
		WithdrawalRequest[] withdrawalRequests;
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
	 * @notice Creates a vault.
	 * @param acceptedTokens_ Array of accepted tokens (pass empty array to accept ALL tokens)
	*/
	function createVault(address[] memory acceptedTokens_) public {
		// [INIT]
		address[] memory _acceptedTokens = acceptedTokens_; 
		WithdrawalRequest[] memory _withdrawalRequests;

		// [CREATE] Vault
		vaults[vaultIdIncrement] = Vault({
			id: vaultIdIncrement,
			withdrawMinutesDelay: 10,
			acceptedTokens: _acceptedTokens,
			withdrawalRequests: _withdrawalRequests
		});

		// [MAP] Voter Weight
		voterWeight[vaultIdIncrement][msg.sender] = 100;

		// [INCREMENT]
		vaultIdIncrement++;
	}
}