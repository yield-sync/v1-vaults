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
	* @param _yieldSyncV1Vault {address}
	* @return vaultMessageHashes_ {bytes32[]}
	*/
	function vaultMessageHashes(address _yieldSyncV1Vault)
		external
		view
		returns (bytes32[] memory vaultMessageHashes_)
	;

	/**
	* @notice Getter for `_yieldSyncV1Vault_signaturesRequired`
	* @dev [view][mapping]
	* @param _purposer {address}
	* @return signaturesRequired_ {YieldSyncV1VaultProperty}
	*/
	function yieldSyncV1Vault_signaturesRequired(address _purposer)
		external
		returns (uint256 signaturesRequired_)
	;

	/**
	* @notice Getter for `_yieldSyncV1Vault_messageHash_messageHashData`
	* @dev [view][mapping]
	* @param _yieldSyncV1Vault {address}
	* @param _messageHash {bytes32}
	* @return messageHashData_ {MessageHashData}
	*/
	function yieldSyncV1Vault_messageHash_messageHashData(address _yieldSyncV1Vault, bytes32 _messageHash)
		external
		view
		returns (MessageHashData memory messageHashData_)
	;

	/**
	* @notice Getter for `_yieldSyncV1Vault_messageHash_messageHashVote`
	* @dev [view][mapping]
	* @param _yieldSyncV1Vault {address}
	* @param _messageHash {bytes32}
	* @return messageHashVote_ {MessageHashData}
	*/
	function yieldSyncV1Vault_messageHash_messageHashVote(address _yieldSyncV1Vault, bytes32 _messageHash)
		external
		view
		returns (MessageHashVote memory messageHashVote_)
	;


	/**
	* @notice Update signaturesRequired
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `yieldSyncV1Vault_signaturesRequiredUpdate`
	* @param _signatureRequired {YieldSyncV1VaultProperty}
	* Emits: `UpdatedPurposerYieldSyncV1VaultProperty`
	*/
	function yieldSyncV1Vault_signaturesRequiredUpdate(uint256 _signatureRequired)
		external
	;

	/**
	* @notice Sign a Message Hash
	* @dev [create] `_vaultMessageHashData` value
	* @param _yieldSyncV1Vault {address}
	* @param _messageHash {bytes32}
	* @param _signature {bytes}
	*/
	function signMessageHash(address _yieldSyncV1Vault, bytes32 _messageHash, bytes memory _signature)
		external
	;

	/**
	* @notice Set pause
	* @dev [restriction] `IYieldSyncGovernance` AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [call-internal]
	* @param _pause {bool}
	*/
	function updatePause(bool _pause)
		external
	;
}
