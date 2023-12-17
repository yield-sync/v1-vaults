// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IAccessControlEnumerable } from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

import { IYieldSyncV1VaultDeployer } from "./interface/IYieldSyncV1VaultDeployer.sol";
import { YieldSyncV1Vault } from "./YieldSyncV1Vault.sol";


contract YieldSyncV1VaultDeployer is
	IYieldSyncV1VaultDeployer
{
	receive ()
		external
		payable
		override
	{}


	fallback ()
		external
		payable
		override
	{}


	address public immutable override YieldSyncGovernance;
	address public immutable override YieldSyncV1VaultRegistry;

	uint256 public override fee;
	uint256 public override yieldSyncV1VaultIdTracker;

	mapping (address yieldSyncV1Vault => uint256 yieldSyncV1VaultId) public override yieldSyncV1Vault_yieldSyncV1VaultId;

	mapping (uint256 yieldSyncV1VaultId => address yieldSyncV1Vault) public override yieldSyncV1VaultId_yieldSyncV1Vault;


	constructor (address _YieldSyncGovernance, address _YieldSyncV1VaultRegistry)
	{
		fee = 0;
		yieldSyncV1VaultIdTracker = 0;

		YieldSyncGovernance = _YieldSyncGovernance;
		YieldSyncV1VaultRegistry = _YieldSyncV1VaultRegistry;
	}


	modifier contractYieldSyncGovernance(bytes32 _role)
	{
		require(IAccessControlEnumerable(YieldSyncGovernance).hasRole(_role, msg.sender), "!auth");

		_;
	}


	/// @inheritdoc IYieldSyncV1VaultDeployer
	function deployYieldSyncV1Vault(
		address _signatureProtocol,
		address _transferRequestProtocol,
		address[] memory _admins,
		address[] memory _members
	)
		public
		payable
		override
		returns (address yieldSyncV1Vault_)
	{
		require(fee <= msg.value, "fee > msg.value");

		yieldSyncV1Vault_ = address(
			new YieldSyncV1Vault(
				msg.sender,
				_signatureProtocol,
				_transferRequestProtocol,
				YieldSyncV1VaultRegistry,
				_admins,
				_members
			)
		);

		yieldSyncV1Vault_yieldSyncV1VaultId[yieldSyncV1Vault_] = yieldSyncV1VaultIdTracker;
		yieldSyncV1VaultId_yieldSyncV1Vault[yieldSyncV1VaultIdTracker] = yieldSyncV1Vault_;

		yieldSyncV1VaultIdTracker++;

		emit DeployedYieldSyncV1Vault(yieldSyncV1Vault_);
	}

	/// @inheritdoc IYieldSyncV1VaultDeployer
	function etherTransfer(address _to)
		public
		override
		contractYieldSyncGovernance(bytes32(0))
	{
		(bool success, ) = _to.call{value: address(this).balance}("");

		require(success, "etherTransfer failed");
	}

	/// @inheritdoc IYieldSyncV1VaultDeployer
	function feeUpdate(uint256 _fee)
		public
		override
		contractYieldSyncGovernance(bytes32(0))
	{
		fee = _fee;
	}
}
