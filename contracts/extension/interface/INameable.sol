// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [struct] */
struct ChangeNameRequest {
	uint256 id;
	address creator;
	string name;
	uint256 approveVoteCount;
	uint256 denyVoteCount;
	uint256 latestRelevantApproveVoteTime;
}


/**
* @title INameable
*/
interface INameable
{

}