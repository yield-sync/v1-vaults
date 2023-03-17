// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IYieldSyncGovernance } from "@yield-sync/v1-sdk/contracts/interface/IYieldSyncGovernance.sol";

import { YieldSyncV1Vault } from "./YieldSyncV1Vault.sol";
import { IYieldSyncV1VaultFactory } from "./interface/IYieldSyncV1VaultFactory.sol";


/**
* @title YieldSyncV1VaultFactory
*/
contract YieldSyncV1VaultFactory is
	IYieldSyncV1VaultFactory
{
	// [address]
	address public override defaultSignatureManager;
	address public override yieldSyncGovernance;
	address public override yieldSyncV1VaultRecord;

	// [uint256]
	uint256 public override fee;
	uint256 public override yieldSyncV1VaultIdTracker;

	// [mapping]
	mapping (
		address yieldSyncV1VaultAddress => uint256 yieldSyncV1VaultId
	) public override yieldSyncV1VaultAddress_yieldSyncV1VaultId;
	mapping (
		uint256 yieldSyncV1VaultId => address yieldSyncV1VaultAddress
	) public override yieldSyncV1VaultId_yieldSyncV1VaultAddress;


	constructor (address _yieldSyncGovernance, address _yieldSyncV1VaultRecord)
	{
		yieldSyncGovernance = _yieldSyncGovernance;
		yieldSyncV1VaultRecord = _yieldSyncV1VaultRecord;

		fee = 0;
		yieldSyncV1VaultIdTracker = 0;
	}


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


	modifier onlyYieldSyncGovernanceAdmin()
	{
		require(
			IYieldSyncGovernance(yieldSyncGovernance).hasRole(
				IYieldSyncGovernance(yieldSyncGovernance).roleString_roleHash("DEFAULT_ADMIN_ROLE"),
				msg.sender
			),
			"!auth"
		);

		_;
	}


	/// @inheritdoc IYieldSyncV1VaultFactory
	function deployYieldSyncV1Vault(
		address[] memory admins,
		address[] memory members,
		address signatureManager,
		bool useDefaultSignatureManager,
		uint256 againstVoteCountRequired,
		uint256 forVoteCountRequired,
		uint256 withdrawalDelaySeconds
	)
		public
		payable
		override
		returns (address)
	{
		require(msg.value >= fee, "!msg.value");

		YieldSyncV1Vault deployedContract = new YieldSyncV1Vault(
			yieldSyncV1VaultRecord,
			admins,
			members,
			useDefaultSignatureManager ? defaultSignatureManager : signatureManager,
			againstVoteCountRequired,
			forVoteCountRequired,
			withdrawalDelaySeconds
		);

		yieldSyncV1VaultAddress_yieldSyncV1VaultId[address(deployedContract)] = yieldSyncV1VaultIdTracker;
		yieldSyncV1VaultId_yieldSyncV1VaultAddress[yieldSyncV1VaultIdTracker] = address(deployedContract);

		yieldSyncV1VaultIdTracker++;

		emit DeployedYieldSyncV1Vault(address(deployedContract));

		return address(deployedContract);
	}


	/// @inheritdoc IYieldSyncV1VaultFactory
	function updateDefaultSignatureManager(address _defaultSignatureManager)
		public
		override
		onlyYieldSyncGovernanceAdmin()
	{
		defaultSignatureManager = _defaultSignatureManager;

		emit UpdatedDefaultSignatureManager(defaultSignatureManager);
	}

	/// @inheritdoc IYieldSyncV1VaultFactory
	function updateFee(uint256 _fee)
		public
		override
		onlyYieldSyncGovernanceAdmin()
	{
		fee = _fee;

		emit UpdatedFee(fee);
	}

	/// @inheritdoc IYieldSyncV1VaultFactory
	function transferEther(address to)
		public
		override
		onlyYieldSyncGovernanceAdmin()
	{
		// [transfer]
		(bool success, ) = to.call{value: address(this).balance}("");

		require(success, "Failed");
	}
}
