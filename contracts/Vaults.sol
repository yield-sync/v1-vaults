// contracts/Governance.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


/*** [IMPORT] ***/

contract Vaults {	
	/*** [STATE VARIABLES] ***/
	
	struct Vault {
		uint256 id;
		address[] acceptedTokens;
		uint256 withdrawMinutesDelay;
	}


	struct withdrawalRequest {
		address requester;
	}


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