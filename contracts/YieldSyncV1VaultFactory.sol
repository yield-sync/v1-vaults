// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IAccessControlEnumerable } from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

import { IYieldSyncV1VaultFactory } from "./interface/IYieldSyncV1VaultFactory.sol";
import { YieldSyncV1Vault } from "./YieldSyncV1Vault.sol";


contract YieldSyncV1VaultFactory is
	IYieldSyncV1VaultFactory
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
	address public immutable override YieldSyncV1VaultAccessControl;

	bool public override etherTransferLocked;

	uint256 public override fee;
	uint256 public override yieldSyncV1VaultIdTracker;

	mapping (
		address yieldSyncV1VaultAddress => uint256 yieldSyncV1VaultId
	) public override yieldSyncV1VaultAddress_yieldSyncV1VaultId;

	mapping (
		uint256 yieldSyncV1VaultId => address yieldSyncV1VaultAddress
	) public override yieldSyncV1VaultId_yieldSyncV1VaultAddress;


	constructor (address _YieldSyncGovernance, address _YieldSyncV1VaultAccessControl)
	{
		etherTransferLocked = false;

		fee = 0;
		yieldSyncV1VaultIdTracker = 0;

		YieldSyncGovernance = _YieldSyncGovernance;
		YieldSyncV1VaultAccessControl = _YieldSyncV1VaultAccessControl;
	}


	modifier contractYieldSyncGovernance(bytes32 role)
	{
		require(IAccessControlEnumerable(YieldSyncGovernance).hasRole(role, msg.sender), "!auth");

		_;
	}


	/// @inheritdoc IYieldSyncV1VaultFactory
	function deployYieldSyncV1Vault(
		address signatureProtocol,
		address transferRequestProtocol,
		address[] memory admins,
		address[] memory members
	)
		public
		payable
		override
		returns (address deployedYieldSyncV1VaultAddress)
	{
		require(msg.value >= fee, "!msg.value");

		YieldSyncV1Vault deployedYieldSyncV1Vault = new YieldSyncV1Vault(
			msg.sender,
			signatureProtocol,
			transferRequestProtocol,
			YieldSyncV1VaultAccessControl,
			admins,
			members
		);

		yieldSyncV1VaultAddress_yieldSyncV1VaultId[address(deployedYieldSyncV1Vault)] = yieldSyncV1VaultIdTracker;
		yieldSyncV1VaultId_yieldSyncV1VaultAddress[yieldSyncV1VaultIdTracker] = address(deployedYieldSyncV1Vault);

		yieldSyncV1VaultIdTracker++;

		emit DeployedYieldSyncV1Vault(address(deployedYieldSyncV1Vault));

		return address(deployedYieldSyncV1Vault);
	}

	/// @inheritdoc IYieldSyncV1VaultFactory
	function feeUpdate(uint256 _fee)
		public
		override
		contractYieldSyncGovernance(bytes32(0))
	{
		fee = _fee;
	}

	/// @inheritdoc IYieldSyncV1VaultFactory
	function etherTransfer(address to)
		public
		override
		contractYieldSyncGovernance(bytes32(0))
	{
		require(!etherTransferLocked, "etherTransferLocked");

		etherTransferLocked = true;

		// [transfer]
		(bool success, ) = to.call{value: address(this).balance}("");

		etherTransferLocked = false;

		require(success, "Failed");
	}
}
