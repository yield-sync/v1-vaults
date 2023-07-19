// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { YieldSyncV1ASignatureProtocol } from "../YieldSyncV1ASignatureProtocol.sol";


contract MockSignatureProtocol is YieldSyncV1ASignatureProtocol {
	constructor (address yieldSyncGovernance, address YieldSyncV1VaultAccessControl)
		YieldSyncV1ASignatureProtocol(yieldSyncGovernance, YieldSyncV1VaultAccessControl)
	{}
}
