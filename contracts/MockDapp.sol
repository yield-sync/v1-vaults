// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";


interface IMockDapp {
	function getDomainSeperator() external view returns (bytes32);
	function getStructHash(address player, uint points) external pure returns (bytes32);
}


/**
 * @title MockDapp
*/
contract MockDapp is
	EIP712,
	IMockDapp
{
	constructor ()
		EIP712("MockDapp", "1")
	{}


	function getDomainSeperator() public view override returns (bytes32) {
		return _domainSeparatorV4();
	}

	function getStructHash(address player, uint points) public pure override returns (bytes32) {
		return keccak256(abi.encode(keccak256("Score(address player,uint points)"), player, points));
	}
}