// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { YieldSyncV1ATransferRequestProtocol } from "../YieldSyncV1ATransferRequestProtocol.sol";


contract MockTransferRequestProtocol is YieldSyncV1ATransferRequestProtocol {
	constructor (address _YieldSyncV1VaultAccessControl, address _YieldSyncV1VaultFactory)
		YieldSyncV1ATransferRequestProtocol(_YieldSyncV1VaultAccessControl, _YieldSyncV1VaultFactory)
	{}
}
