// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Import the OpenZeppelin contract library
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/ownership/MultiSig.sol";

// Define the multisig vault contract
contract MultisigVault is Ownable, MultiSig {
	// Use the SafeMath library for all arithmetic operations
	using SafeMath for uint256;

	// Define the number of required signatures for transactions
	uint256 public requiredSignatures;

	// Define the maximum number of signatures allowed for transactions
	uint256 public maxSignatures;

	// Define the time limit for transactions (in seconds)
	uint256 public transactionTimeLimit;

	// Define the contract's balance of Ether
	uint256 public balance;

	// Define the contract's balance of ERC20 tokens
	mapping (address => uint256) public tokenBalances;

	// Define an event for successful transactions
	event TransactionSuccess(
		address indexed from,
		address indexed to,
		uint256 value,
		bytes data
	);

	// Define a constructor to initialize the contract's parameters
	constructor(
		uint256 _requiredSignatures,
		uint256 _maxSignatures,
		uint256 _transactionTimeLimit
	) public {
		// Set the required signatures and maximum signatures
		requiredSignatures = _requiredSignatures;
		maxSignatures = _maxSignatures;

		// Set the transaction time limit
		transactionTimeLimit = _transactionTimeLimit;

		// Set the contract's owner to the address of the first signer
		ownable_constructor(signers[0]);
	}

	// Define a function to deposit Ether into the contract
	function deposit() public payable {
		// Update the contract's balance of Ether
		balance = balance.add(msg.value);
	}

	// Define a function to deposit ERC20 tokens into the contract
	function depositToken(address _token, uint256 _amount) public {
		// Verify that the caller has the required allowance for the token transfer
		ERC20(_token).transferFrom(msg.sender, address(this), _amount);

		// Update the contract's balance of the ERC20 token
		tokenBalances[_token] = tokenBalances[_token].add(_amount);
	}

	// Define a function to submit a transaction proposal
	function submitTransaction(
	address _to,
	uint256 _value,
	bytes memory _data
	) public {
		// Verify that the value of the transaction is not greater than the contract's balance of Ether
		require(balance >= _value);

		// Verify that the transaction is valid and does not exceed the time limit
		require(validTransaction(_to, _value, _data));

		// Create a transaction ID and submit the transaction proposal
		bytes32 transactionId
		= multiSig_submitTransaction(_to, _value, _data);

		// If the transaction is successfully submitted, emit an event
		if (transactionId != bytes32(0)) {
			emit TransactionSubmitted(transactionId);
		}
	}

	// Define a function to verify the validity of a transaction proposal
	function validTransaction(address _to, uint256 _value, bytes memory _data)
		public
		view
		returns (bool)
	{
		// Verify that the transaction is not exceeding the time limit
		uint256 transactionTime = now.add(transactionTimeLimit);
		require(multiSig_transactionTime(_to, _value, _data) <= transactionTime);

		// Return true if the transaction is valid
		return true;
	}

	// Define a function to execute a transaction proposal
	function executeTransaction(
	bytes32 _transactionId,
	address _to,
	uint256 _value,
	bytes memory _data
	) public
	{
		// Verify that the caller has the required number of signatures to execute the transaction
		require(multiSig_isConfirmed(_transactionId));

		// Verify that the transaction is valid and does not exceed the time limit
		require(validTransaction(_to, _value, _data));

		// Execute the transaction and transfer the Ether and/or ERC20 tokens
		if (_to == address(this)) {
			// Deposit Ether and/or ERC20 tokens into the contract
			if (_value > 0) {
			balance = balance.add(_value);
			}
			if (_data.length > 0) {
			// Parse the data as an ERC20 token transfer
			(address token, uint256 amount) = _data;
			tokenBalances[token] = tokenBalances[token].add(amount);
			}
		} else {
			// Withdraw Ether and/or ERC20 tokens from the contract
			if (_value > 0) {
			require(_to.call.value(_value)(_data));
			}
			if (_data.length > 0) {
			// Parse the data as an ERC20 token transfer
			(address token, uint256 amount) = _data;
			require(ERC20(token).transferFrom(address(this), _to, amount));
			}
		}

		// Emit an event to indicate that the transaction was successful
		emit TransactionSuccess(msg.sender, _to, _value, _data);
	}
}