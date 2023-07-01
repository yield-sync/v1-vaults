// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


struct MessageHashData {
	bytes signature;
	address signer;
	address[] signedMembers;
	uint256 signatureCount;
}


interface ISignatureManager
{
	/**
	* @notice YieldSyncGovernance Contract Address
	* @dev [view-address]
	* @return {address}
	*/
	function YieldSyncGovernance()
		external
		view
		returns (address)
	;

	/**
	* @notice YieldSyncV1VaultAccessControl Contract Address
	* @dev [view-address]
	* @return {address}
	*/
	function YieldSyncV1VaultAccessControl()
		external
		view
		returns (address)
	;

	/**
	* @notice Getter for `_vaultMessageHashes`
	* @dev [view][mapping]
	* @param yieldSyncV1Vault {address}
	* @return {bytes32[]}
	*/
	function vaultMessageHashes(address yieldSyncV1Vault)
		external
		view
		returns (bytes32[] memory)
	;

	/**
	* @notice Getter for `_vaultMessageHashData`
	* @dev [view][mapping]
	* @param yieldSyncV1Vault {address}
	* @param messageHash {bytes32}
	* @return {MessageHashData}
	*/
	function vaultMessageHashData(address yieldSyncV1Vault, bytes32 messageHash)
		external
		view
		returns (MessageHashData memory)
	;


	/**
	* @notice Sign a Message Hash
	* @dev [create] `_vaultMessageHashData` value
	* @param yieldSyncV1Vault {address}
	* @param messageHash {bytes32}
	* @param signature {bytes}
	*/
	function signMessageHash(address yieldSyncV1Vault, bytes32 messageHash, bytes memory signature)
		external
	;


	/**
	* @notice Set pause
	* @dev [restriction] `IYieldSyncGovernance` AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [call-internal]
	* @param pause {bool}
	*/
	function updatePause(bool pause)
		external
	;
}
