// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";


/**
 * @title MockDapp
*/
contract MockDapp is
	EIP712
{
	constructor ()
		EIP712("name", "1")
	{}


	function getDomainSeperator() public view returns (bytes32) {
		return _domainSeparatorV4();
	}

	function getStructHash() public pure returns (bytes32) {
		return keccak256(
			abi.encode(
				keccak256("set(address sender,uint x)"),
				address(0),
				1
			)
		);
	}
}