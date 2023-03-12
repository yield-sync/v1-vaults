// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { SignatureManager } from "../SignatureManager.sol";


contract MockSignatureManager is SignatureManager {
	constructor (address _yieldSyncGovernance, address _yieldSyncV1VaultRecord)
		SignatureManager(_yieldSyncGovernance, _yieldSyncV1VaultRecord)
	{}
}
