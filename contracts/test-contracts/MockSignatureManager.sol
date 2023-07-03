// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { YieldSyncV1SignatureProtocol } from "../YieldSyncV1SignatureProtocol.sol";


contract MockSignatureManager is YieldSyncV1SignatureProtocol {
	constructor (address _yieldSyncGovernance, address _YieldSyncV1VaultAccessControl)
		YieldSyncV1SignatureProtocol(_yieldSyncGovernance, _YieldSyncV1VaultAccessControl)
	{}
}
