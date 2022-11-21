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


	/*** [STATE VARIABLES] ***/
	uint256 vaultId;
	mapping(address => Vault) vaults;
	mapping(uint256 => uint8) voterWeight;


	/*** [CONSTRUCTOR] ***/
	
	constructor () {
		vaultId = 0;
	}

	function createVault() public {
		address[] memory acceptedTokens; 

		// [CREATE] Vault
		Vault memory createdVault = Vault({
			id: vaultId,
			acceptedTokens: acceptedTokens,
			withdrawMinutesDelay: 10
		});

		// [MAP]
		vaults[msg.sender] = createdVault;

		// [INCREMENT]
		vaultId++;
	}
}