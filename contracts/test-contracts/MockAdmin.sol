// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IAccessControlEnumerable } from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

import { IYieldSyncV1Vault } from "../interface/IYieldSyncV1Vault.sol";
import { IYieldSyncV1VaultTransferRequest, TransferRequest } from "../interface/IYieldSyncV1VaultTransferRequest.sol";


contract MockAdmin is Ownable {
	modifier validTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId) {
		require(
			IYieldSyncV1VaultTransferRequest(
				yieldSyncV1VaultAddress
			).yieldSyncV1Vault_transferRequestId_transferRequest(
				yieldSyncV1VaultAddress,
				transferRequestId
			).creator != address(0),
			"No TransferRequest found"
		);

		_;
	}


	function updateTransferRequestLatestRelevantForVoteTime(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId,
		bool arithmaticSign,
		uint256 timeInSeconds
	)
		public
		validTransferRequest(yieldSyncV1VaultAddress, transferRequestId)
	{
		TransferRequest memory transferRequest = IYieldSyncV1VaultTransferRequest(
			yieldSyncV1VaultAddress
		).yieldSyncV1Vault_transferRequestId_transferRequest(
			yieldSyncV1VaultAddress,
			transferRequestId
		);

		if (arithmaticSign)
		{
			// [update] TransferRequest within `_transferRequest`
			transferRequest.latestRelevantForVoteTime += (timeInSeconds * 1 seconds);
		}
		else
		{
			// [update] TransferRequest within `_transferRequest`
			transferRequest.latestRelevantForVoteTime -= (timeInSeconds * 1 seconds);
		}

		IYieldSyncV1VaultTransferRequest(payable(yieldSyncV1VaultAddress)).updateTransferRequest(
			yieldSyncV1VaultAddress,
			transferRequestId,
			transferRequest
		);
	}
}
