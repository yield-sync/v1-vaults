// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


contract VerifySignature {
	///
	function splitSignature(bytes memory _signature)
		internal
		pure
		returns (bytes32 r, bytes32 s, uint8 v)
	{
		require(_signature.length == 65, "invalid signature length");

		assembly {
			r := mload(add(_signature, 32))
			s := mload(add(_signature, 64))
			v := byte(0, mload(add(_signature, 96)))
		}
	}


	///
	function getMessageHash(string memory _message)
		public
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked(_message));
	}


	///
	function getEthSignedMessageHash(bytes32 _messageHash)
		public
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
	}

	///
	function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
		public
		pure
		returns (address)
	{
		(bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

		return ecrecover(_ethSignedMessageHash, v, r, s);
	}

	///
	function verify(address _signer, string memory _message, bytes memory _signature)
		public
		pure
		returns (bool)
	{
		bytes32 messageHash = getMessageHash(_message);
		bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

		return recoverSigner(ethSignedMessageHash, _signature) == _signer;
	}
}
