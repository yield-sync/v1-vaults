// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { ISignatureProtocol, MessageHashData } from "./ISignatureProtocol.sol";
import { IYieldSyncV1VaultRegistry } from "./IYieldSyncV1VaultRegistry.sol";


struct MessageHashVote
{
	address[] signedMembers;
	uint256 signatureCount;
}


interface IYieldSyncV1ASignatureProtocol is
	ISignatureProtocol
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
	* @notice YieldSyncV1VaultRegistry Interfaced
	* @dev [view-address]
	* @return {IYieldSyncV1VaultRegistry}
	*/
	function YieldSyncV1VaultRegistry()
		external
		view
		returns (IYieldSyncV1VaultRegistry)
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
	* @notice Getter for `_yieldSyncV1Vault_signaturesRequired`
	* @dev [view][mapping]
	* @param purposer {address}
	* @return {YieldSyncV1VaultProperty}
	*/
	function yieldSyncV1Vault_signaturesRequired(address purposer)
		external
		returns (uint256)
	;

	/**
	* @notice Getter for `_yieldSyncV1Vault_messageHash_messageHashData`
	* @dev [view][mapping]
	* @param yieldSyncV1Vault {address}
	* @param messageHash {bytes32}
	* @return {MessageHashData}
	*/
	function yieldSyncV1Vault_messageHash_messageHashData(address yieldSyncV1Vault, bytes32 messageHash)
		external
		view
		returns (MessageHashData memory)
	;

	/**
	* @notice Getter for `_yieldSyncV1Vault_messageHash_messageHashVote`
	* @dev [view][mapping]
	* @param yieldSyncV1Vault {address}
	* @param messageHash {bytes32}
	* @return {MessageHashData}
	*/
	function yieldSyncV1Vault_messageHash_messageHashVote(address yieldSyncV1Vault, bytes32 messageHash)
		external
		view
		returns (MessageHashVote memory)
	;


	/**
	* @notice Update signaturesRequired
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `yieldSyncV1Vault_signaturesRequiredUpdate`
	* @param signatureRequired {YieldSyncV1VaultProperty}
	* Emits: `UpdatedPurposerYieldSyncV1VaultProperty`
	*/
	function yieldSyncV1Vault_signaturesRequiredUpdate(uint256 signatureRequired)
		external
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
