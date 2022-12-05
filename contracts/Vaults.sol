// contracts/Vault.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [IMPORT] */
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';


contract Vaults {
	/* [USING] */
	using SafeERC20 for IERC20;

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
	mapping (uint256 => Vault) vaults;
	
	// Vault Id => (Address => Voter Weight)
	mapping (uint256 => mapping (address => uint8)) voterWeight;

	// 
	mapping (uint256 => mapping (address => uint256)) tokenBalance;


	/* [CONSTRUCTOR] */
	
	constructor () {
		vaultIdIncrement = 0;
	}

	receive () external payable {}

	/**
	 * @notice Creates a Vault and sets the voter weight of msg.sender to 100
	 * @param acceptedTokens Array of accepted tokens (pass empty array to accept ALL tokens)
	 * @param withdrawMinutesDelay Withdrawal delay (in minutes)
	*/
	function createVault(
		address[] memory acceptedTokens,
		uint8 withdrawMinutesDelay
	) public {
		// [INIT]
		QueuedWithdrawal[] memory initialQueuedWithdrawal;

		// [CREATE] Vault
		vaults[vaultIdIncrement] = Vault({
			id: vaultIdIncrement,
			strictDeposits: false,
			withdrawMinutesDelay: withdrawMinutesDelay,
			acceptedTokens: acceptedTokens,
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
	function depositTokens(
		uint256 vaultId,
		address tokenAddress,
		uint256 amount
	) public payable {
		// Approve transfer amount
        IERC20(tokenAddress).safeApprove(address(this), amount);

		// Transfer amount from msg.sender to this contract
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);

		// Update vault token balance
		tokenBalance[vaultId][tokenAddress] += amount;
	}


	/**
	 * @notice CREATE a queued withdrawl from vault
	*/
	function createQueuedWithdrawal() public {}


	/**
	 * @notice DELETE a queued withdrawal from vault
	*/
	function cancelQueuedWithdrawal() public {}


	/**
	 * @notice Withdraw tokens (instantaneous)
	*/
	function withdrawTokens() public {}

	
	/**
	 * @notice Change voter weight
	*/
	function changeVoterWeight() public {}
}