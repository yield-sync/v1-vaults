// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { YieldSyncV1TransferRequestProtocol } from "../YieldSyncV1TransferRequestProtocol.sol";


contract MockTransferRequestProtocol is YieldSyncV1TransferRequestProtocol {
	constructor (address _YieldSyncV1VaultAccessControl, address _YieldSyncV1VaultFactory)
		YieldSyncV1TransferRequestProtocol(_YieldSyncV1VaultAccessControl, _YieldSyncV1VaultFactory)
	{}
}
