// contracts/Governance.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


/*** [IMPORT] ***/

contract Vaults {	
	/*** [STATE VARIABLES] ***/
	
	struct Vault {
		mapping(address => uint8) voterWeight;
		address[] acceptedTokens;
		uint256 withdrawMinutesDelay;
	}


	/*** [STATE VARIABLES] ***/
	mapping(address => Vault) vaults;


	/*** [CONSTRUCTOR] ***/
	
	constructor () {}
}