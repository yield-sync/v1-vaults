// contracts/Governance.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


/*** [IMPORT] ***/

contract Vaults {	
	/*** [STRUCTS] ***/
	
	struct WithdrawalRequest {
		address requester;

		address[] tokens;

		uint256[] amounts;
	}
	
	struct Vault {
		uint256 withdrawMinutesDelay;
		
		address[] acceptedTokens;
		
		WithdrawalRequest[] withdrawalRequests;

		mapping(address => uint8) voterWeight;
	}


	/*** [STATE VARIABLES] ***/

	mapping(address => Vault) vaults;


	/*** [CONSTRUCTOR] ***/
	
	constructor () {}
}