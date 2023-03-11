// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { SignatureManager } from "../SignatureManager.sol";


contract MockSignatureManager is SignatureManager {
	constructor (address _iglooFiGovernance, address _iglooFiV1VaultRecord)
		SignatureManager(_iglooFiGovernance, _iglooFiV1VaultRecord)
	{}
}
