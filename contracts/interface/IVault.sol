// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


/* [import] */
import "@openzeppelin/contracts/access/IAccessControl.sol";


/**
* @title IVault
*/
interface IVault is
	IAccessControl
{
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
	* @notice Required signatures for an approval
	* @dev [state-variable][uint256]
	* @return {uint256}
	*/
	function requiredSignatures()
		external
		view
		returns (uint256)
	;

	/**
	* @notice Get Withdrawal delay (denominated in minutes)
	* @dev [state-variable][uint256]
	* @return {uint256}
	*/
	function withdrawalDelayMinutes()
		external
		view
		returns (uint256)
	;
	

	/**
	* @notice Update requiredSignatures
	* @dev [restriction] AccessControl: DEFAULT_ADMIN_ROLE
	* @dev [update] requiredSignatures
	* @param newRequiredSignatures {uint256} New requiredSignatures
	* @return {bool} Status
	* @return {uint256} New requiredSignatures
	*/
	function updateRequiredSignatures(uint256 newRequiredSignatures)
		external
		returns (bool, uint256)
	;

	/**
	* @notice Add a voter
	* @dev [restriction] AccessControl: DEFAULT_ADMIN_ROLE
	* @dev [create]
	* @param voter {address} Address of the voter to add
	* @return {bool} Status
	* @return {address} Voter added
	*/
	function addVoter(address voter)
		external
		returns (bool, address)
	;

	/**
	* @notice Remove a voter
	* @dev [restriction] AccessControl: DEFAULT_ADMIN_ROLE
	* @dev [delete]
	* @param voter {address} Address of the voter to remove
	* @return {bool} Status
	* @return {address} Removed voter
	*/	
	function removeVoter(address voter)
		external
		returns (bool, address)
	;

	/**
	* @notice Update withdrawalDelayMinutes
	* @dev [restriction] AccessControl: DEFAULT_ADMIN_ROLE
	* @dev [update]
	* @param newWithdrawalDelayMinutes {uint256} New withdrawalDelayMinutes
	* @return {bool} Status
	* @return {uint256} New withdrawalDelayMinutes
	*/
	function updateWithdrawalDelayMinutes(uint256 newWithdrawalDelayMinutes)
		external
		returns (bool, uint256)
	;

	/**
	* @notice Toggle pause on a WithdrawalRequest
	* @dev [restriction] AccessControl: DEFAULT_ADMIN_ROLE
	* @dev [update]
	* @param withdrawalRequestId {uint256}
	* @return {bool} Status
	* @return {WithdrawalRequest} Updated WithdrawalRequest
	*/
	function toggleWithdrawalRequestPause(uint256 withdrawalRequestId)
		external
		returns (bool, WithdrawalRequest memory)
	;

	/**
	* @notice Toggle pause on a WithdrawalRequest
	* @dev [restriction] AccessControl: DEFAULT_ADMIN_ROLE
	* @dev [delete]
	* @param withdrawalRequestId {uint256}
	* @return {bool} Status
	*/
	function deleteWithdrawalRequest(uint256 withdrawalRequestId)
		external
		returns (bool)
	;


	/**
	* @notice Create a WithdrawalRequest
	* @dev [restriction] AccessControl: VOTER_ROLE
	* @dev [create] _withdrawalRequest
	* @param to {address} Address the withdrawn tokens will be sent
	* @param tokenAddress {address} Address of token contract
	* @param amount {uint256} Amount to be withdrawn
	* @return {bool} Status
	* @return {WithdrawalRequest} The created WithdrawalRequest
	*/
	function createWithdrawalRequest(
		address to,
		address tokenAddress,
		uint256 amount
	)
		external
		returns (bool, WithdrawalRequest memory)
	;

	/**
	* @notice Vote on withdrawal request
	* @dev [restriction] AccessControl: VOTER_ROLE
	* @dev [update] _withdrawalRequest
	* @param withdrawalRequestId {uint256} Id of the WithdrawalRequest
	* @param vote {bool} Approve (true) or deny (false)
	* @return {bool} Status
	* @return {bool} Vote received
	* @return {bool} forVoteCount
	* @return {bool} againstVoteCount
	* @return {bool} lastImpactfulVote
	*/
	function voteOnWithdrawalRequest(uint256 withdrawalRequestId, bool vote)
		external
		returns (bool, bool, uint256, uint256, uint256)
	;

	/**
	* @notice Process the WithdrawalRequest
	* @dev [restriction] AccessControl: VOTER_ROLE
	* @param withdrawalRequestId {uint256} Id of the WithdrawalRequest
	* @return {bool} Status
	* @return {string} Message
	*/
	function processWithdrawalRequests(uint256 withdrawalRequestId)
		external
		returns (bool, string memory)
	;


	/**
	* @notice Get token balance
	* @dev [!restriction]
	* @dev [getter][mapping]
	* @param tokenAddress {address} Token contract address
	* @return {uint256}
	*/
	function tokenBalance(address tokenAddress)
		external
		view
		returns (uint256)
	;

	/**
	* @notice Get WithdrawalRequest with given withdrawalRequestId
	* @dev [!restriction]
	* @dev [getter][mapping]
	* @param withdrawalRequestId {uint256}
	* @return {WithdrawalRequest}
	*/
	function withdrawalRequest(uint256 withdrawalRequestId)
		external
		view returns (WithdrawalRequest memory)
	;

	/**
	* @notice Get array of voters
	* @dev [!restriction]
	* @dev [getter][mapping]
	* @param withdrawalRequestId {uint256} Id of WithdrawalRequest
	* @return {WithdrawalRequest}
	*/
	function withdrawalRequestVotedVoters(uint256 withdrawalRequestId)
		view
		external
		returns (address[] memory)
	;

	/**
	* @notice Get withdrawalRequestIds by a given creator
	* @dev [!restriction]
	* @dev [getter][mapping]
	* @param creator {address}
	* @return {uint256[]} Array of WithdrawalRequestIds
	*/
	function withdrawalRequestByCreator(address creator)
		view
		external
		returns (uint256[] memory)
	;

	/**
	* @notice Deposit tokens
	* @dev [!restriction]
	* @dev [IERC20][emit]
	* @param tokenAddress {address} Address of token contract
	* @param amount {uint256} Amount to be moved
	* @return {bool} Status
	* @return {uint256} Amount deposited
	* @return {uint256} New token balance
	*/
	function depositTokens(address tokenAddress, uint256 amount)
		external
		payable
		returns (bool, uint256, uint256)
	;


	/**
	* @notice Emits when tokens are deposited
	* @dev [event]
	*/
	event TokensDeposited (
		address indexed depositor,
		address indexed token,
		uint256 amount
	);

	/**
	* @notice Emits when tokens are withdrawn
	* @dev [event]
	*/
	event TokensWithdrawn (
		address indexed withdrawer,
		address indexed token,
		uint256 amount
	);
}