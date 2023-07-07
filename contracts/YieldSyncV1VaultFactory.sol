// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IAccessControlEnumerable } from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

import { ISignatureProtocol } from "./interface/ISignatureProtocol.sol";
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

	address public override defaultSignatureProtocol;
	address public override defaultTransferRequestProtocol;

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


	modifier contract_YieldSyncGovernance(bytes32 role)
	{
		require(IAccessControlEnumerable(YieldSyncGovernance).hasRole(role, msg.sender), "!auth");

		_;
	}


	/// @inheritdoc IYieldSyncV1VaultFactory
	function deployYieldSyncV1Vault(
		address signatureProtocol,
		address transferRequestProtocol,
		address[] memory admins,
		address[] memory members,
		bool useDefaultSignatureProtocol,
		bool useDefaultTransferRequestProtocol
	)
		public
		payable
		override
		returns (address)
	{
		require(
			defaultTransferRequestProtocol != address(0) || !useDefaultTransferRequestProtocol,
			"!transferRequestProtocol && useDefaultTransferRequestProtocol"
		);

		require(msg.value >= fee, "!msg.value");

		YieldSyncV1Vault deployedYieldSyncV1Vault = new YieldSyncV1Vault(
			YieldSyncV1VaultAccessControl,
			useDefaultTransferRequestProtocol ? defaultTransferRequestProtocol : transferRequestProtocol,
			useDefaultSignatureProtocol ? defaultSignatureProtocol : signatureProtocol,
			admins,
			members
		);

		yieldSyncV1VaultAddress_yieldSyncV1VaultId[address(deployedYieldSyncV1Vault)] = yieldSyncV1VaultIdTracker;
		yieldSyncV1VaultId_yieldSyncV1VaultAddress[yieldSyncV1VaultIdTracker] = address(deployedYieldSyncV1Vault);

		ITransferRequestProtocol(defaultTransferRequestProtocol).yieldSyncV1VaultInitialize(
			msg.sender,
			address(deployedYieldSyncV1Vault)
		);

		if (defaultSignatureProtocol != address(0))
		{
			ISignatureProtocol(defaultSignatureProtocol).initializeYieldSyncV1Vault(
				msg.sender,
				address(deployedYieldSyncV1Vault)
			);
		}

		yieldSyncV1VaultIdTracker++;

		emit DeployedYieldSyncV1Vault(address(deployedYieldSyncV1Vault));

		return address(deployedYieldSyncV1Vault);
	}


	/// @inheritdoc IYieldSyncV1VaultFactory
	function defaultTransferRequestProtocol__update(address _defaultTransferRequestProtocol)
		public
		override
		contract_YieldSyncGovernance(bytes32(0))
	{
		defaultTransferRequestProtocol = _defaultTransferRequestProtocol;
	}


	/// @inheritdoc IYieldSyncV1VaultFactory
	function defaultSignatureProtocol__update(address _defaultSignatureProtocol)
		public
		override
		contract_YieldSyncGovernance(bytes32(0))
	{
		defaultSignatureProtocol = _defaultSignatureProtocol;
	}

	/// @inheritdoc IYieldSyncV1VaultFactory
	function fee__update(uint256 _fee)
		public
		override
		contract_YieldSyncGovernance(bytes32(0))
	{
		fee = _fee;
	}

	/// @inheritdoc IYieldSyncV1VaultFactory
	function transferEther(address to)
		public
		override
		contract_YieldSyncGovernance(bytes32(0))
	{
		require(!transferEtherLocked, "transferEtherLocked");

		transferEtherLocked = true;

		// [transfer]
		(bool success, ) = to.call{value: address(this).balance}("");

		transferEtherLocked = false;

		require(success, "Failed");
	}
}
