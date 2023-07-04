// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { YieldSyncV1SignatureProtocol } from "../YieldSyncV1SignatureProtocol.sol";


contract MockSignatureProtocol is YieldSyncV1SignatureProtocol {
	constructor (address yieldSyncGovernance, address YieldSyncV1VaultAccessControl)
		YieldSyncV1SignatureProtocol(yieldSyncGovernance, YieldSyncV1VaultAccessControl)
	{}
}
