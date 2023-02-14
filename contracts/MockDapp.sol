// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "hardhat/console.sol";


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

	function getStructHash(address a, uint x) public pure returns (bytes32) {
		return keccak256(abi.encode(keccak256("Point(address a,uint x)"), a, x));
	}
}