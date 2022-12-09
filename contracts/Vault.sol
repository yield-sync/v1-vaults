// contracts/Vault.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [IMPORT] */
// /access
import "@openzeppelin/contracts/access/AccessControl.sol";
// /token
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';


contract Vaults is AccessControl {
	/* [USING] */
	using SafeERC20 for IERC20;


	/* [STRUCT] */
	struct RequestedWithdrawal {
		address to;
		
		address token;

		uint256 amounts;

		uint256 voteCount;
	}

	struct QueuedWithdrawal {
		address to;
		
		address token;

		uint256 amounts;
	}


	/* [STATE-VARIABLE] */
	uint256 public requiredSignatures;
	
	// Vault Id => (Address => Voter Weight)
	mapping (address => uint8) _voterWeight;
	// ERC20 Contract Address => Balance
	mapping (address => uint256) _tokenBalance;


	/* [CONSTRUCTOR] */
	constructor (uint256 _requiredSignatures)
	{
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		
		_voterWeight[msg.sender] = 100;

		requiredSignatures = _requiredSignatures;
	}


	/* [RECIEVE] */
	receive ()
		external payable
	{}


	/**
	 * @notice Deposit funds into vault
	*/
	function depositTokens(
		address tokenAddress,
		uint256 amount
	)
		public payable
	{
		// Transfer amount from msg.sender to this contract
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);

		// Update vault token balance
		_tokenBalance[tokenAddress] += amount;
	}


	/**
	 * @notice CREATE a queued withdrawl from vault
	*/
	function createQueuedWithdrawal()
		public
	{}

	/**
	 * @notice DELETE a queued withdrawal from vault
	*/
	function cancelQueuedWithdrawal()
		public
	{}

	/**
	 * @notice Withdraw tokens (instantaneous)
	*/
	function withdrawTokens()
		public
	{}

	/**
	 * @notice Change voter weight
	*/
	function changeVoterWeight()
		public
	{}
}