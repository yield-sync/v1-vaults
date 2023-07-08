// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IAccessControlEnumerable } from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

import { IYieldSyncV1Vault } from "../interface/IYieldSyncV1Vault.sol";
import {
	IYieldSyncV1TransferRequestProtocol,
	TransferRequest,
	TransferRequestVote
} from "../interface/IYieldSyncV1TransferRequestProtocol.sol";


contract MockAdmin is Ownable {
	modifier validTransferRequest(
		address yieldSyncV1TransferRequestProtocol,
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId
	) {
		require(
			IYieldSyncV1TransferRequestProtocol(
				yieldSyncV1TransferRequestProtocol
			).yieldSyncV1Vault_transferRequestId_transferRequest(
				yieldSyncV1VaultAddress,
				transferRequestId
			).creator != address(0),
			"No TransferRequest found"
		);

		_;
	}


	function yieldSyncV1Vault_transferRequestId_transferRequestVoteUpdateLatestRelevantForVoteTime(
		address yieldSyncV1TransferRequestProtocol,
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId,
		bool arithmaticSign,
		uint256 timeInSeconds
	)
		public
		validTransferRequest(yieldSyncV1TransferRequestProtocol, yieldSyncV1VaultAddress, transferRequestId)
	{
		TransferRequestVote memory transferRequestVote = IYieldSyncV1TransferRequestProtocol(
			yieldSyncV1TransferRequestProtocol
		).yieldSyncV1Vault_transferRequestId_transferRequestVote(
			yieldSyncV1VaultAddress,
			transferRequestId
		);

		if (arithmaticSign)
		{
			// [update] TransferRequest within `_transferRequest`
			transferRequestVote.latestRelevantForVoteTime += (timeInSeconds * 1 seconds);
		}
		else
		{
			// [update] TransferRequest within `_transferRequest`
			transferRequestVote.latestRelevantForVoteTime -= (timeInSeconds * 1 seconds);
		}

		IYieldSyncV1TransferRequestProtocol(
			yieldSyncV1TransferRequestProtocol
		).yieldSyncV1Vault_transferRequestId_transferRequestVoteUpdate(
			yieldSyncV1VaultAddress,
			transferRequestId,
			transferRequestVote
		);
	}
}
