// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [import] */
// [local]
import "./interface/INameable.sol";


/**
* @title Igloo Fi V1 Vault
*/
abstract contract Nameable is
	INameable
{
	// [string][public]
	string public name;

	// [uint256][internal]
	uint256 internal _changeNameRequestId;

	// [ChangeNameRequest][public]
	ChangeNameRequest[] public changeNameRequest;

	// _changeNameRequestId => Voted Voter Addresses Array
	mapping (uint256 => address[]) internal _changeNameRequestVotedVoters;


	/* [constructor] */
	constructor (string memory _name) {
		name = _name;
	}

	/* [function] */
	function changeName()
		public
		virtual
	;

	function createChangeNameRequest()
		public
		virtual
	;

	function voteOnChangeNameRequest()
		public
		virtual
	;

	function processChangeNameRequest()
		public
		virtual
	;
}