// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IIglooFiV1Vault, WithdrawalRequest } from "../interface/IIglooFiV1Vault.sol";


contract MockIglooFiV1VaultAdmin {
	mapping (address => bool) public adminOverIglooFiV1Vault;


	modifier validWithdrawalRequest(address iglooFiV1Vault, uint256 withdrawalRequestId) {
		// [require] WithdrawalRequest exists
		require(
			IIglooFiV1Vault(payable(iglooFiV1Vault)).withdrawalRequest(withdrawalRequestId).creator != address(0),
			"No WithdrawalRequest found"
		);
		
		_;

		_;
	}


	function updateWithdrawalRequestLatestRelevantApproveVoteTime(
		address iglooFiV1Vault,
		uint256 withdrawalRequestId,
		bool arithmaticSign,
		uint256 timeInSeconds
	)
		public
		validWithdrawalRequest(iglooFiV1Vault, withdrawalRequestId)
	{
		WithdrawalRequest memory wR = IIglooFiV1Vault(payable(iglooFiV1Vault)).withdrawalRequest(withdrawalRequestId);

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


		IIglooFiV1Vault(payable(iglooFiV1Vault)).updateWithdrawalRequest(withdrawalRequestId, wR);
	}
}