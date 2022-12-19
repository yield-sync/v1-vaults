// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/**
* @title IVault
* @notice This is a vault for storing ERC20 tokens.
*/
interface IVault
{
	/* [STRUCT] */
	struct WithdrawalRequest {
		address creator;
		address to;
		address token;
		bool paused;
		bool accelerated;
		uint256 amount;
		uint256 forVoteCount;
		uint256 againstVoteCount;
		uint256 lastImpactfulVote;
	}

	/**
	* @dev [bytes32]
	* @notice AccessControl Role
	* @return {bytes32} keccak256 value
	*/
	function VOTER_ROLE() external view returns (bytes32);

	/**
	* @dev [uint256]
	* @notice Required signatures for a vote
	* @return {bytes32} keccak256 value
	*/
	function requiredSignatures() external view returns (uint256);

	/**
	* @dev [uint256]
	* @notice Delay in minutes withdrawal
	* @return {bytes32} keccak256 value
	*/
	function withdrawalDelayMinutes() external view returns (uint256);

	/**
	* @dev [mapping]
	* @notice Token Balances
	* @param {address} Token contract address
	* @return {uint256} Balance of token
	*/
	function tokenBalance(address token) external view returns (uint256);
}