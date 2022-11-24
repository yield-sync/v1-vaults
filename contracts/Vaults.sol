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
	 * @notice Creates a Vault and sets the voter weight of msg.sender to 100
	 * @param acceptedTokens_ Array of accepted tokens (pass empty array to accept ALL tokens)
	*/
	function createVault(address[] memory acceptedTokens_) public {
		// [INIT]
		WithdrawalRequest[] memory initialiWithdrawlRequests;

		// [CREATE] Vault
		vaults[vaultIdIncrement] = Vault({
			id: vaultIdIncrement,
			withdrawMinutesDelay: 10,
			acceptedTokens: acceptedTokens_,
			withdrawalRequests: initialiWithdrawlRequests
		});

		// [MAP] Voter Weight
		voterWeight[vaultIdIncrement][msg.sender] = 100;

		// [INCREMENT]
		vaultIdIncrement++;
	}

	/**
	 * @notice
	 */
	function depositTokens() public {}


	/**
	 * @notice
	 */
	function createWithdrawalRequest() public {}


	/**
	 * @notice
	 */
	function cancelWithdrawalRequest() public {}


	/**
	 * @notice
	 */
	function withdrawTokens() public {}

	
	/**
	 * @notice
	 */
	function changeVoterWeight() public {}


	/**
	 * @notice
	 */
	function withdrawMinutesDelay() public {}
}