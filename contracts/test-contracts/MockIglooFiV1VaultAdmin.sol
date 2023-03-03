// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


contract MockIglooFiV1VaultAdmin {
	modifier validWithdrawalRequest(uint256 withdrawalRequest) {
		_;
	}

	function updateWithdrawalRequestLatestRelevantApproveVoteTime(
		uint256 withdrawalRequestId,
		bool arithmaticSign,
		uint256 timeInSeconds
	)
		public
		pure
		validWithdrawalRequest(withdrawalRequestId)
	{
		if (arithmaticSign)
		{
			(timeInSeconds * 1 seconds);
		}
		else
		{
			(timeInSeconds * 1 seconds);
		}
	}
}