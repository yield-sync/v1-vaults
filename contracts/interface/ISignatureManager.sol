// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


struct MessageHashData {
	bytes signature;
	address signer;
	address[] signedVoters;
	uint256 signatureCount;
}


/**
* @title ISignatureManager
*/
interface ISignatureManager
{
	/**
	* @notice CONSTANT Address of Igloo Fi Governance contract
	* @dev [!restriction]
	* @dev [view-address]
	* @return {address}
	*/
	function iglooFiGovernance()
		external
		view
		returns (address)
	;

	/**
	* @notice Getter for `_vaultMessageHashes`
	* @dev [!restriction]
	* @dev [view][mapping]
	* @param iglooFiV1Vault {address}
	* @return {bytes32[]}
	*/
	function vaultMessageHashes(address iglooFiV1Vault)
		external
		view
		returns (bytes32[] memory)
	;

	/**
	* @notice Getter for `_vaultMessageHashData`
	* @dev [!restriction][public]
	* @dev [view][mapping]
	* @param iglooFiV1Vault {address}
	* @param messageHash {bytes32}
	* @return {MessageHashData}
	*/
	function vaultMessageHashData(address iglooFiV1Vault, bytes32 messageHash)
		external
		view
		returns (MessageHashData memory)
	;


	/**
	* @notice Sign a Message Hash
	* @dev [!restriction][public]
	* @dev [create] `_vaultMessageHashData` value
	* @param iglooFiV1Vault {address}
	* @param messageHash {bytes32}
	* @param signature {bytes}
	*/
	function signMessageHash(address iglooFiV1Vault, bytes32 messageHash, bytes memory signature)
		external
	;


	/**
	* @notice Set pause
	* @dev [restriction] IIglooFiGovernance AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [call-internal]
	* @param pause {bool}
	*/
	function setPause(bool pause)
		external
	;
}