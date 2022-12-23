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
	* @dev Emits when a `WithdrawalRequest` is deleted
	*/
	event DeletedWithdrawalRequest (
		uint256 WithdrawalRequest
	);

	/**
	* @dev Emits when `requiredSignatures` are updated
	*/
	event UpdatedRequiredSignatures (
		uint256 requiredSignatures
	);

	/**
	* @dev Emits when a voter is added
	*/
	event VoterAdded (
		address addedVoter
	);

	/**
	* @dev Emits when a voter is removed
	*/
	event VoterRemoved (
		address addedVoter
	);

	/**
	* @dev Emits when `withdrawalDelayMinutes` is updated
	*/
	event UpdatedWithdrawalDelayMinutes (
		uint256 withdrawalDelayMinutes
	);

	/**
	* @dev Emits when a `WithdrawalRequest.paused` is toggled
	*/
	event ToggledWithdrawalRequestPause (
		bool withdrawalRequestPaused
	);

	/**
	* @dev Emits when a `WithdrawalRequest` is created
	*/
	event CreatedWithdrawalRequest (
		WithdrawalRequest withdrawalRequest
	);

	/**
	* @dev Emits when a voter has voted
	*/
	event VoterVoted (
		uint256 withdrawalRequestId,
		address indexed voter,
		bool vote
	);

	/**
	* @dev Emit when a WithdrawalRequest is ready to be processed
	*/
	event WithdrawalRequestReadyToBeProccessed (
		uint256 withdrawalRequestId
	);

	/**
	* @dev Emits when tokens are withdrawn
	*/
	event TokensWithdrawn (
		address indexed withdrawer,
		address indexed token,
		uint256 amount
	);

	/**
	* @dev Emits when tokens are deposited
	*/
	event TokensDeposited (
		address indexed depositor,
		address indexed token,
		uint256 amount
	);


	/**
	* @notice Required signatures for approval
	*
	* @dev [uint256-getter]
	* @return {uint256}
	*/
	function requiredSignatures()
		external
		view
		returns (uint256)
	;

	/**
	* @notice Get Withdrawal delay in minutes
	*
	* @dev [uint256-getter]
	*
	* @return {uint256}
	*/
	function withdrawalDelayMinutes()
		external
		view
		returns (uint256)
	;
	

	/**
	* @notice Update amount of required signatures
	*
	* @dev [restriction] AccessControl._role = DEFAULT_ADMIN_ROLE
	*
	* @dev [update] `requiredSignatures`
	*
	* @param newRequiredSignatures {uint256}
	* @return {bool} Status
	* @return {uint256} New `requiredSignatures`
	*
	* Emits: `UpdatedRequiredSignatures`
	*/
	function updateRequiredSignatures(uint256 newRequiredSignatures)
		external
		returns (bool, uint256)
	;

	/**
	* @notice Add a voter
	*
	* @dev [restriction] AccessControl._role = DEFAULT_ADMIN_ROLE
	*
	* @dev [add] `AccessControl._roles`
	*
	* @param voter {address} Address of the voter to add
	* @return {bool} Status
	* @return {address} Voter added
	*
	* Emits: `VoterAdded`
	*/
	function addVoter(address voter)
		external
		returns (bool, address)
	;

	/**
	* @notice Remove a voter
	*
	* @dev [restriction] AccessControl._role = DEFAULT_ADMIN_ROLE
	*
	* @dev [remove] `AccessControl._roles`
	*
	* @param voter {address} Address of the voter to remove
	* @return {bool} Status
	* @return {address} Removed voter
	*
	* Emits: `VoterRemoved`
	*/	
	function removeVoter(address voter)
		external
		returns (bool, address)
	;

	/**
	* @notice Update `withdrawalDelayMinutes`
	*
	* @dev [restriction] AccessControl._role = DEFAULT_ADMIN_ROLE
	*
	* @dev [update] `withdrawalDelayMinutes`
	*
	* @param newWithdrawalDelayMinutes {uint256}
	* @return {bool} Status
	* @return {uint256} New `withdrawalDelayMinutes`
	*
	* Emits: `UpdatedWithdrawalDelayMinutes`
	*/
	function updateWithdrawalDelayMinutes(uint256 newWithdrawalDelayMinutes)
		external
		returns (bool, uint256)
	;

	/**
	* @notice Toggle pause on a WithdrawalRequest
	*
	* @dev [restriction] AccessControl._role = DEFAULT_ADMIN_ROLE
	*
	* @dev [update] `_withdrawalRequest`
	*
	* @param withdrawalRequestId {uint256}
	* @return {bool} Status
	* @return {WithdrawalRequest} Updated WithdrawalRequest
	*
	* Emit: `ToggledWithdrawalRequestPause`
	*/
	function toggleWithdrawalRequestPause(uint256 withdrawalRequestId)
		external
		returns (bool, WithdrawalRequest memory)
	;

	/**
	* @notice Toggle pause on a WithdrawalRequest
	*
	* @dev [restriction] AccessControl._role = DEFAULT_ADMIN_ROLE
	*
	* @dev [call][internal] {_deleteWithdrawalRequest}
	*
	* @param withdrawalRequestId {uint256}
	* @return {bool} Status
	*
	* Emits: `DeletedWithdrawalRequest`
	*/
	function deleteWithdrawalRequest(uint256 withdrawalRequestId)
		external
		returns (bool)
	;


	/**
	* @notice Create a WithdrawalRequest
	*
	* @dev [restriction] AccessControl._role = VOTER_ROLE
	*
	* @dev [increment] _withdrawalRequestId
	*      [add] `_withdrawalRequest`
	*      [push-into] `_withdrawalRequestByCreator`
	*
	* @param to {address} Address the withdrawn tokens will be sent
	* @param tokenAddress {address}
	* @param amount {uint256} Amount to be withdrawn
	* @return {bool} Status
	* @return {WithdrawalRequest} The added `WithdrawalRequest`
	*
	* Emits: `CreatedWithdrawalRequest`
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
	* @notice Vote on WithdrawalRequest
	*
	* @dev [restriction] AccessControl._role = VOTER_ROLE
	*
	* @dev [update] `_withdrawalRequest`
	*
	* @param withdrawalRequestId {uint256}
	* @param vote {bool} Approve (true) or deny (false)
	* @return {bool} Status
	* @return {bool} Vote
	* @return {bool} forVoteCount
	* @return {bool} againstVoteCount
	* @return {bool} lastImpactfulVote
	*
	* Emits: `WithdrawalRequestReadyToBeProccessed`
	* Emits: `VoterVoted`
	*/
	function voteOnWithdrawalRequest(uint256 withdrawalRequestId, bool vote)
		external
		returns (bool, bool, uint256, uint256, uint256)
	;

	/**
	* @notice Process WithdrawalRequest with given `withdrawalRequestId`
	*
	* @dev [restriction] AccessControl._role = VOTER_ROLE
	*
	* @dev [ERC20-transfer]
	*      [decrement] `_tokenBalance`
	*      [call][internal] `_deleteWithdrawalRequest`
	*
	* @param withdrawalRequestId {uint256} Id of the WithdrawalRequest
	* @return {bool} Status
	* @return {string} Message
	*
	* Emits: `TokensDeposited`
	* Emits: `DeletedWithdrawalRequest`
	*/
	function processWithdrawalRequests(uint256 withdrawalRequestId)
		external
		returns (bool, string memory)
	;


	/**
	* @notice Get token balance
	*
	* @dev [!restriction]
	*
	* @dev [getter][mapping]
	*
	* @param tokenAddress {address} Token contract address
	* @return {uint256}
	*/
	function tokenBalance(address tokenAddress)
		external
		view
		returns (uint256)
	;

	/**
	* @notice Get WithdrawalRequest with given `withdrawalRequestId`
	*
	* @dev [!restriction]
	*
	* @dev [getter][mapping]
	*
	* @param withdrawalRequestId {uint256}
	* @return {WithdrawalRequest}
	*/
	function withdrawalRequest(uint256 withdrawalRequestId)
		external
		view returns (WithdrawalRequest memory)
	;

	/**
	* @notice Get array of voters
	*
	* @dev [!restriction]
	*
	* @dev [getter][mapping]
	*
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
	*
	* @dev [!restriction]
	*
	* @dev [getter][mapping]
	*
	* @param creator {address}
	* @return {uint256[]} Array of `WithdrawalRequestId`'s
	*/
	function withdrawalRequestByCreator(address creator)
		view
		external
		returns (uint256[] memory)
	;

	/**
	* @notice Deposit tokens
	*
	* @dev [!restriction]
	*
	* @dev [IERC20]
	*
	* @param tokenAddress {address}
	* @param amount {uint256} Amount to be moved
	* @return {bool} Status
	* @return {uint256} Amount deposited
	* @return {uint256} New token balance
	*
	* Emits: `TokensDeposited`
	*/
	function depositTokens(address tokenAddress, uint256 amount)
		external
		payable
		returns (bool, uint256, uint256)
	;
}