// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


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
	* @param _iglooFiV1Vault {address}
	* @return {bytes32[]}
	*/
	function vaultMessageHashes(address _iglooFiV1Vault)
		external
		view
		returns (bytes32[] memory)
	;

	/**
	* @notice Getter for `_vaultMessageHashData`
	* @dev [!restriction][public]
	* @dev [view][mapping]
	* @param _iglooFiV1Vault {address}
	* @param _messageHash {bytes32}
	* @return {MessageHashData}
	*/
	function vaultMessageHashData(address _iglooFiV1Vault, bytes32 _messageHash)
		external
		view
		returns (MessageHashData memory)
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

	/**
	* @notice Sign a Message Hash
	* @dev [!restriction][public]
	* @dev [create] `_vaultMessageHashData` value
	* @param _iglooFiV1Vault {address}
	* @param _messageHash {bytes32}
	* @param _signature {bytes}
	*/
	function signMessageHash(address _iglooFiV1Vault, bytes32 _messageHash, bytes memory _signature)
		external
	;
}