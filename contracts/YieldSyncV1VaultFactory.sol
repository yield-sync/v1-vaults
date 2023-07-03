// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IAccessControlEnumerable } from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

import { ITransferRequestProtocol } from "./interface/ITransferRequestProtocol.sol";
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


	address public override immutable YieldSyncGovernance;
	address public override immutable YieldSyncV1VaultAccessControl;

	address public override defaultSignatureManager;
	address public override transferRequestProtocol;

	bool public override transferEtherLocked;

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
		transferEtherLocked = false;

		fee = 0;
		yieldSyncV1VaultIdTracker = 0;

		YieldSyncGovernance = _YieldSyncGovernance;
		YieldSyncV1VaultAccessControl = _YieldSyncV1VaultAccessControl;
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
		address _transferRequestProtocol,
		bool useDefaultSignatureManager,
		bool useDefaultTransferRequestProtocol
	)
		public
		payable
		override
		returns (address)
	{
		require(transferRequestProtocol != address(0), "!transferRequestProtocol");

		require(msg.value >= fee, "!msg.value");

		YieldSyncV1Vault deployedContract = new YieldSyncV1Vault(
			YieldSyncV1VaultAccessControl,
			admins,
			members,
			useDefaultTransferRequestProtocol ? transferRequestProtocol : _transferRequestProtocol,
			useDefaultSignatureManager ? defaultSignatureManager : signatureManager
		);

		yieldSyncV1VaultAddress_yieldSyncV1VaultId[address(deployedContract)] = yieldSyncV1VaultIdTracker;
		yieldSyncV1VaultId_yieldSyncV1VaultAddress[yieldSyncV1VaultIdTracker] = address(deployedContract);

		ITransferRequestProtocol(transferRequestProtocol).initializeTransferRequestProtocol(
			msg.sender,
			address(deployedContract)
		);

		yieldSyncV1VaultIdTracker++;

		emit DeployedYieldSyncV1Vault(address(deployedContract));

		return address(deployedContract);
	}


	function setTransferRequestProtocol(address _transferRequestProtocol)
		public
		only_YieldSyncGovernance_DEFAULT_ADMIN_ROLE()
	{
		transferRequestProtocol = _transferRequestProtocol;
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
