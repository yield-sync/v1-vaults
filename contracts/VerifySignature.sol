// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract VerifySignature {
	///
	function getMessageHash(string memory _message)
		public
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked(_message));
	}


	///
	function ECDSA_toEthSignedMessageHash(bytes32 _messageHash)
		public
		pure
		returns (bytes32)
	{
		return ECDSA.toEthSignedMessageHash(_messageHash);
	}

	///
	function ECDSA_recover(bytes32 _ethSignedMessageHash, bytes memory _signature)
		public
		pure
		returns (address)
	{
		return ECDSA.recover(_ethSignedMessageHash, _signature);
	}

	///
	function verify(address _signer, string memory _message, bytes memory _signature)
		public
		pure
		returns (bool)
	{
		bytes32 messageHash = keccak256(abi.encodePacked(_message));
		bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);

		return ECDSA.recover(ethSignedMessageHash, _signature) == _signer;
	}
}