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


contract MockAdmin is Ownable
{
	modifier validTransferRequest(
		address _yieldSyncV1ATransferRequestProtocol,
		address _yieldSyncV1Vault,
		uint256 _transferRequestId
	)
	{
		require(
			IYieldSyncV1ATransferRequestProtocol(
				_yieldSyncV1ATransferRequestProtocol
			).yieldSyncV1Vault_transferRequestId_transferRequest(
				_yieldSyncV1Vault,
				_transferRequestId
			).creator != address(0),
			"No TransferRequest found"
		);

		_;
	}


	function yieldSyncV1Vault_transferRequestId_transferRequestPollUpdatelatestForVoteTime(
		address _yieldSyncV1ATransferRequestProtocol,
		address _yieldSyncV1Vault,
		uint256 _transferRequestId,
		bool _arithmaticSign,
		uint256 _timeInSeconds
	)
		public
		validTransferRequest(_yieldSyncV1ATransferRequestProtocol, _yieldSyncV1Vault, _transferRequestId)
	{
		TransferRequestPoll memory transferRequestPoll = IYieldSyncV1ATransferRequestProtocol(
			_yieldSyncV1ATransferRequestProtocol
		).yieldSyncV1Vault_transferRequestId_transferRequestPoll(
			_yieldSyncV1Vault,
			_transferRequestId
		);

		if (_arithmaticSign)
		{
			transferRequestPoll.latestForVoteTime += (_timeInSeconds * 1 seconds);
		}
		else
		{
			transferRequestPoll.latestForVoteTime -= (_timeInSeconds * 1 seconds);
		}

		IYieldSyncV1ATransferRequestProtocol(
			_yieldSyncV1ATransferRequestProtocol
		).yieldSyncV1Vault_transferRequestId_transferRequestPollAdminUpdate(
			_yieldSyncV1Vault,
			_transferRequestId,
			transferRequestPoll
		);
	}
}
