// contracts/Governance.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


/* ========== [IMPORT] ========== */

// @openzeppelin/contracts/access
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract Governance is AccessControlEnumerable {
	/* ========== [STATE VARIABLES] ========== */
	
	bytes32 public constant S_ROLE = keccak256("S_ROLE");
	bytes32 public constant A_ROLE = keccak256("A_ROLE");
	bytes32 public constant B_ROLE = keccak256("B_ROLE");
	bytes32 public constant C_ROLE = keccak256("C_ROLE");


	/* ========== [CONSTRUCTOR] ========== */
	
	constructor () {
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
	}
}