// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IAccessControlEnumerable } from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

import { YieldSyncV1Vault } from "./YieldSyncV1Vault.sol";
import { IYieldSyncV1VaultFactory } from "./interface/IYieldSyncV1VaultFactory.sol";


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


	// [address]
	address public override immutable YieldSyncGovernance;
	address public override immutable YieldSyncV1VaultRecord;
	address public override defaultSignatureManager;

	// [bool]
	bool public override transferEtherLocked;

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


	constructor (address _YieldSyncGovernance, address _YieldSyncV1VaultRecord)
	{
		YieldSyncGovernance = _YieldSyncGovernance;
		YieldSyncV1VaultRecord = _YieldSyncV1VaultRecord;

		transferEtherLocked = false;

		fee = 0;
		yieldSyncV1VaultIdTracker = 0;
	}


	modifier only_YieldSyncGovernance_DEFAULT_ADMIN_ROLE()
	{
		require(IAccessControlEnumerable(YieldSyncGovernance).hasRole(bytes32(0), msg.sender), "!auth");

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
			YieldSyncV1VaultRecord,
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
		only_YieldSyncGovernance_DEFAULT_ADMIN_ROLE()
	{
		defaultSignatureManager = _defaultSignatureManager;
	}

	/// @inheritdoc IYieldSyncV1VaultFactory
	function updateFee(uint256 _fee)
		public
		override
		only_YieldSyncGovernance_DEFAULT_ADMIN_ROLE()
	{
		fee = _fee;
	}

	/// @inheritdoc IYieldSyncV1VaultFactory
	function transferEther(address to)
		public
		override
		only_YieldSyncGovernance_DEFAULT_ADMIN_ROLE()
	{
		require(!transferEtherLocked, "transferEtherLocked");

		transferEtherLocked = true;

		// [transfer]
		(bool success, ) = to.call{value: address(this).balance}("");

		transferEtherLocked = false;

		require(success, "Failed");
	}
}
