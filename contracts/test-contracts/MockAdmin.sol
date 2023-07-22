// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IAccessControlEnumerable } from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

import { IYieldSyncV1Vault } from "../interface/IYieldSyncV1Vault.sol";
import {
	IYieldSyncV1ATransferRequestProtocol,
	TransferRequest,
	TransferRequestPoll
} from "../interface/IYieldSyncV1ATransferRequestProtocol.sol";


contract MockAdmin is Ownable {
	modifier validTransferRequest(
		address yieldSyncV1ATransferRequestProtocol,
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId
	) {
		require(
			IYieldSyncV1ATransferRequestProtocol(
				yieldSyncV1ATransferRequestProtocol
			).yieldSyncV1VaultAddress_transferRequestId_transferRequest(
				yieldSyncV1VaultAddress,
				transferRequestId
			).creator != address(0),
			"No TransferRequest found"
		);

		_;
	}


	function yieldSyncV1VaultAddress_transferRequestId_transferRequestPollUpdatelatestForVoteTime(
		address yieldSyncV1ATransferRequestProtocol,
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId,
		bool arithmaticSign,
		uint256 timeInSeconds
	)
		public
		validTransferRequest(yieldSyncV1ATransferRequestProtocol, yieldSyncV1VaultAddress, transferRequestId)
	{
		TransferRequestPoll memory transferRequestPoll = IYieldSyncV1ATransferRequestProtocol(
			yieldSyncV1ATransferRequestProtocol
		).yieldSyncV1VaultAddress_transferRequestId_transferRequestPoll(
			yieldSyncV1VaultAddress,
			transferRequestId
		);

		if (arithmaticSign)
		{
			// [update] TransferRequest within `_transferRequest`
			transferRequestPoll.latestForVoteTime += (timeInSeconds * 1 seconds);
		}
		else
		{
			// [update] TransferRequest within `_transferRequest`
			transferRequestPoll.latestForVoteTime -= (timeInSeconds * 1 seconds);
		}

		IYieldSyncV1ATransferRequestProtocol(
			yieldSyncV1ATransferRequestProtocol
		).yieldSyncV1VaultAddress_transferRequestId_transferRequestPollUpdate(
			yieldSyncV1VaultAddress,
			transferRequestId,
			transferRequestPoll
		);
	}
}
