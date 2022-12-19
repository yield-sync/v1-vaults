// contracts/Vault.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

interface ICardinalProtocolGovernance is
	IAccessControlEnumerable
{
	/* [STATE VARIABLES] */
	function S() external view returns (bytes32);
	function A() external view returns (bytes32);
	function B() external view returns (bytes32);
	function C() external view returns (bytes32);
}