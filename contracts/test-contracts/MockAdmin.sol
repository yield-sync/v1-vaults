// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IAccessControlEnumerable } from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

import { IYieldSyncV1Vault, TransferRequest } from "../interface/IYieldSyncV1Vault.sol";


contract MockAdmin is Ownable {
	modifier validTransferRequest(address yieldSyncV1VaultAddress, uint256 transferRequestId) {
		require(
			IYieldSyncV1Vault(payable(yieldSyncV1VaultAddress)).transferRequestId_transferRequest(
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
		TransferRequest memory wR = IYieldSyncV1Vault(payable(yieldSyncV1VaultAddress)).transferRequestId_transferRequest(
			transferRequestId
		);

		if (arithmaticSign)
		{
			// [update] TransferRequest within `_transferRequest`
			wR.latestRelevantForVoteTime += (timeInSeconds * 1 seconds);
		}
		else
		{
			// [update] TransferRequest within `_transferRequest`
			wR.latestRelevantForVoteTime -= (timeInSeconds * 1 seconds);
		}

		IYieldSyncV1Vault(payable(yieldSyncV1VaultAddress)).updateTransferRequest(transferRequestId, wR);
	}
}
