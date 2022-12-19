// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/**
* @title IVault
* @notice This is a vault for storing ERC20 tokens.
*/
interface IVault
{
	/**
	* @notice AccessControl Role
	* @return {bytes32} keccak256 value
	*/
	function VOTER_ROLE() external view returns (bytes32);

	/**
	* @notice Required signatures for a vote
	* @return {bytes32} keccak256 value
	*/
	function requiredSignatures() external view returns (uint256);

	/**
	* @notice Delay in minutes withdrawal
	* @return {bytes32} keccak256 value
	*/
	function withdrawalDelayMinutes() external view returns (uint256);


	mapping(address => uint256) public tokenBalance;
}