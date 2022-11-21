// contracts/Governance.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


/* [IMPORT] */

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

	uint256 vaultId;
	mapping(address => Vault) vaults;
	mapping(uint256 => uint8) voterWeight;


	/* [CONSTRUCTOR] */
	
	constructor () {
		vaultId = 0;
	}

	/**
	 * @notice Create a Vault
	 * @param acceptedTokens_ Array of accepted tokens (pass empty array to accept ALL tokens)
	*/
	function createVault(address[] memory acceptedTokens_) public {
		// [INIT]
		address[] memory _acceptedTokens = acceptedTokens_; 
		WithdrawalRequest[] memory _withdrawalRequests;

		// [CREATE] Vault
		Vault memory createdVault = Vault({
			id: vaultId,
			withdrawMinutesDelay: 10,
			acceptedTokens: _acceptedTokens,
			withdrawalRequests: _withdrawalRequests
		});

		// [MAP]
		vaults[msg.sender] = createdVault;

		// [INCREMENT]
		vaultId++;
	}
}