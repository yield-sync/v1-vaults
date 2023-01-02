// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [import] */
// [!local]
import "hardhat/console.sol";
import "@igloo-fi/v1-sdk/contracts/interface/IIglooFiGovernance.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
// [local]
import "./interface/IIglooFiV1VaultFactory.sol";
import "./IglooFiV1Vault.sol";


/**
* @title Igloo Fi V1 Vault Factory
*/
contract IglooFiV1VaultFactory is
	Pausable,
	IIglooFiV1VaultFactory
{
	/* [state-variable] */
	// [address][public][constant]
	address public IGLOO_FI;

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
		_fee = 0;
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


	/// @inheritdoc IIglooFiV1VaultFactory
	function fee()
		public
		view
		returns (uint256)
	{
		return _fee;
	}


	/// @inheritdoc IIglooFiV1VaultFactory
	function vaultAddress(uint256 vaultId)
		public
		view
		returns (address)
	{
		return _vaultAddress[vaultId];
	}


	/// @inheritdoc IIglooFiV1VaultFactory
	function deployVault(
		address admin,
		address[] memory voters,
		string memory name,
		uint256 requiredApproveVotes,
		uint256 withdrawalDelayMinutes
	)
		public
		payable
		whenNotPaused()
		returns (address)
	{
		require(msg.value >= _fee, "!msg.value");

		IglooFiV1Vault deployedContract;

		// [deploy] A vault contract
		deployedContract = new IglooFiV1Vault(
			admin,
			voters,
			name,
			requiredApproveVotes,
			withdrawalDelayMinutes
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


	/// @inheritdoc IIglooFiV1VaultFactory
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

	/// @inheritdoc IIglooFiV1VaultFactory
	function updateFee(uint256 newFee)
		public
		authLevelS()
	{
		_fee = newFee;
	}

	/// @inheritdoc IIglooFiV1VaultFactory
	function updateTreasury(address _treasury)
		public
		whenNotPaused()
		authLevelS()
	{
		treasury = _treasury;
	}

	/// @inheritdoc IIglooFiV1VaultFactory
	function transferFunds()
		public
		whenNotPaused()
		authLevelS()
	{
		// [transfer]
		(bool success, ) = treasury.call{value: address(this).balance}("");

		require(success, "Unable to send value, recipient may have reverted");
	}
}