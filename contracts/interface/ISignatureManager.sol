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
	 * @notice Recover Signer
	 * @dev [!restriction]
	 * @dev [pure]
	 * @param hash {bytes32}
	 * @param v {uint8}
	 * @param r {bytes32}
	 * @param s {bytes32}
	*/
	function recoverSigner(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
		external
		pure
		returns (address)
	;

	/**
	 * @notice Getter for `_vaultMessageHashes`
	 * @dev [!restriction]
	 * @dev [view][mapping]
	 * @param _iglooFiV1Vault {address}
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
	*/
	function vaultMessageHashData(address _iglooFiV1Vault, bytes32 _messageHash)
		external
		view
		returns (MessageHashData memory)
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