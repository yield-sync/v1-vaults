// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";


interface IMockDapp
{
	function recoverSigner(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) external pure returns (address);
	function getDomainSeperator() external view returns (bytes32);
	function getStructHash(address _player, uint _points) external pure returns (bytes32);
	function hashTypedDataV4(bytes32 _structHash) external view returns (bytes32);
}


contract MockDapp is
	EIP712,
	IMockDapp
{
	constructor ()
		EIP712("MockDapp", "1")
	{}

	function recoverSigner(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s)
		public
		pure
		override
		returns (address)
	{
		return ECDSA.recover(ECDSA.toEthSignedMessageHash(_hash), _v, _r, _s);
	}

	function getDomainSeperator()
		public
		view
		override
		returns (bytes32)
	{
		return _domainSeparatorV4();
	}

	function getStructHash(address _player, uint _points)
		public
		pure
		override
		returns (bytes32)
	{
		return keccak256(abi.encode(keccak256("Score(address player,uint points)"), _player, _points));
	}

	function hashTypedDataV4(bytes32 _structHash)
		public
		view
		override
		returns (bytes32)
	{
		return EIP712._hashTypedDataV4(_structHash);
	}
}
