// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IAccessControlEnumerable } from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

import { IYieldSyncV1Vault, WithdrawalRequest } from "../interface/IYieldSyncV1Vault.sol";


contract MockAdmin is Ownable {
	modifier validWithdrawalRequest(address yieldSyncV1VaultAddress, uint256 withdrawalRequestId) {
		require(
			IYieldSyncV1Vault(payable(yieldSyncV1VaultAddress)).withdrawalRequest(
				withdrawalRequestId
			).creator != address(0),
			"No WithdrawalRequest found"
		);

		_;
	}


	function updateWithdrawalRequestLatestRelevantApproveVoteTime(
		address yieldSyncV1VaultAddress,
		uint256 withdrawalRequestId,
		bool arithmaticSign,
		uint256 timeInSeconds
	)
		public
		validWithdrawalRequest(yieldSyncV1VaultAddress, withdrawalRequestId)
	{
		WithdrawalRequest memory wR = IYieldSyncV1Vault(payable(yieldSyncV1VaultAddress)).withdrawalRequest(
			withdrawalRequestId
		);

		if (arithmaticSign)
		{
			// [update] WithdrawalRequest within `_withdrawalRequest`
			wR.latestRelevantApproveVoteTime += (timeInSeconds * 1 seconds);
		}
		else
		{
			// [update] WithdrawalRequest within `_withdrawalRequest`
			wR.latestRelevantApproveVoteTime -= (timeInSeconds * 1 seconds);
		}

		IYieldSyncV1Vault(payable(yieldSyncV1VaultAddress)).updateWithdrawalRequest(withdrawalRequestId, wR);
	}
}
