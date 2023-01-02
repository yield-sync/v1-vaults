// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [import] */
// [!local]
import "@igloo-fi/v1-sdk/contracts/interface/IIglooFiGovernance.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
// [local]
import "./interface/IIglooFiV1VaultFactory.sol";
import "./IglooFiV1Vault.sol";


/**
* @title Igloo Fi V1 Vault Factory
*/
contract IglooFiV1VaultFactory is
	Pausable,
	IIglooFiVaultFactory
{
	/* [using] */
	using Address for address payable;


	/* [state-variable] */
	// [address][public][constant]
	address public constant IGLOO_FI;

	// [address][public]
	address public treasury;

	/* [uint256][internal] */
	uint256 internal _vaultId;
	uint256 internal _fee;

	// [mapping][internal]
	// Vault Id => Contract address
	mapping (uint256 => address) internal _vaultAddress;


	/* [constructor] */
	constructor (address iglooFi)
	{
		IGLOO_FI = iglooFi;

		_vaultId = 0;
		_vaultFee = 0;
	}


	/* [recieve] */
	receive ()
		external
		payable
	{}


	/* [fallback] */
	fallback ()
		external
		payable
	{}


	/* [modifier] */
	modifier authLevelS() {
		require(
			IIglooFiGovernance(IGLOO_FI).hasRole(
				IIglooFiGovernance(IGLOO_FI).S(),
				msg.sender
			),
			"!auth"
		);

		_;
	}


	/** @inheritdoc IIglooFiV1VaultFactory */
	function fee()
		public
		view
		returns (uint256)
	{
		return _fee;
	}


	/** @inheritdoc IIglooFiV1VaultFactory */
	function vaultAddress(uint256 vaultId)
		public
		view
		returns (address)
	{
		return _vaultAddress[vaultId];
	}


	/** @inheritdoc IIglooFiV1VaultFactory */
	function deployVault(
		address admin,
		address[] memory voters,
		uint256 requiredApproveVotes,
		uint256 withdrawalDelayMinutes,
		string memory name
	)
		public
		payable
		whenNotPaused()
		returns (address)
	{
		require(msg.value >= _fee, "!msg.value");

		Vault deployedContract;

		// [deploy] A vault contract
		deployedContract = new Vault(
			admin,
			voters,
			requiredApproveVotes,
			withdrawalDelayMinutes,
			name
		);

		// Register vault
		_vaultAddress[_vaultId] = address(deployedContract);

		// [increment] vaultId
		_vaultId++;

		// [emit]
		emit VaultDeployed(address(deployedContract));

		// [return]
		return address(deployedContract);
	}


	/** @inheritdoc IIglooFiV1VaultFactory */
	function togglePause()
		public
		authLevelS()
	{
		if (!paused())
		{
			// [call-internal]
			_pause();
		}
		else
		{
			// [call-internal]
			_unpause();
		}
	}

	/** @inheritdoc IIglooFiV1VaultFactory */
	function updateFee(uint256 newFee)
		public
		authLevelS()
	{
		_fee = newFee;
	}

	/** @inheritdoc IIglooFiV1VaultFactory */
	function updateTreasury(address _treasury)
		public
		whenNotPaused()
		authLevelS()
	{
		treasury = _treasury;
	}

	/** @inheritdoc IIglooFiV1VaultFactory */
	function transferFunds()
		public
		whenNotPaused()
		authLevelS()
	{
		// [transfer]
		treasury.sendValue(w.amount);
	}
}