// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


/* [struct] */
struct WithdrawalRequest {
	bool forEther;
	bool forERC20;
	bool forERC721;
	address creator;
	address to;
	address token;
	uint256 amount;
	uint256 tokenId;
	uint256 forVoteCount;
	uint256 againstVoteCount;
	uint256 latestRelevantApproveVoteTime;
	address[] votedVoters;
}


/**
* @title IIglooFiV1Vault
*/
interface IIglooFiV1Vault
{
	event CreatedWithdrawalRequest(uint256 withdrawalRequest);
	event DeletedWithdrawalRequest(uint256 withdrawalRequestId);
	event TokensWithdrawn(address indexed withdrawer, address indexed token, uint256 amount);
	event UpdatedForVoteCountRequired(uint256 forVoteCountRequired);
	event UpdatedSignatureManger(address signatureManager);
	event UpdatedWithdrawalDelaySeconds(uint256 withdrawalDelaySeconds);
	event UpdatedWithdrawalRequest(WithdrawalRequest withdrawalRequest);
	event VoterVoted(uint256 withdrawalRequestId, address indexed voter, bool vote);
	event WithdrawalRequestReadyToBeProccessed(uint256 withdrawalRequestId);


	receive ()
		external
		payable
	;

	fallback ()
		external
		payable
	;

	/**
	* @notice Address of signature manager
	* @dev [!restriction]
	* @dev [view-address]
	* @return {address}
	*/
	function signatureManager()
		external
		view
		returns (address)
	;

	/**
	* @notice AccessControlEnumerable role
	* @dev [!restriction]
	* @dev [view-bytes32]
	* @return {uint256}
	*/
	function VOTER()
		external
		view
		returns (bytes32)
	;

	/**
	* @notice Required For Vote Count
	* @dev [!restriction]
	* @dev [view-uint256]
	* @return {uint256}
	*/
	function forVoteCountRequired()
		external
		view
		returns (uint256)
	;

	/**
	* @notice Against Vote Count Required
	* @dev [!restriction]
	* @dev [view-uint256]
	* @return {uint256}
	*/
	function againstVoteCountRequired()
		external
		view
		returns (uint256)
	;

	/**
	* @notice Withdrawal delay in minutes
	* @dev [!restriction]
	* @dev [view-uint256]
	* @return {uint256}
	*/
	function withdrawalDelaySeconds()
		external
		view
		returns (uint256)
	;


	/**
	* @notice Getter for active withdrawlRequests
	* @dev [!restriction]
	* @dev [view-uint256[]]
	* @return {uint256[]}
	*/
	function openWithdrawalRequestIds()
		external
		view
		returns (uint256[] memory)
	;

	/**
	* @notice Getter for `_withdrawalRequest`
	* @dev [!restriction]
	* @dev [view][mapping]
	* @param withdrawalRequestId {uint256}
	* @return {WithdrawalRequest}
	*/
	function withdrawalRequest(uint256 withdrawalRequestId)
		external
		view returns (WithdrawalRequest memory)
	;


	/**
	* @notice Assign VOTER to an address on AccessControlEnumerable
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [add] address to VOTER on `AccessControlEnumerable`
	* @param targetAddress {address}
	*/
	function addVoter(address targetAddress)
		external
	;

	/**
	* @notice Remove a voter
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [remove] address with VOTER on `AccessControlEnumerable`
	* @param voter {address} Address of the voter to remove
	*/	
	function removeVoter(address voter)
		external
	;

	/**
	* @notice Delete withdrawalRequest & all associated values
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [call][internal] {_deleteWithdrawalRequest}
	* @param withdrawalRequestId {uint256}
	* Emits: `DeletedWithdrawalRequest`
	*/
	function deleteWithdrawalRequest(uint256 withdrawalRequestId)
		external
	;

	/**
	* @notice Update withdrawalRequest
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [update] `_withdrawalRequest`
	* @param withdrawalRequestId {uint256}
	* @param __withdrawalRequest {WithdrawalRequest}
	* Emits: `UpdatedWithdrawalRequest`
	*/
	function updateWithdrawalRequest(uint256 withdrawalRequestId, WithdrawalRequest memory __withdrawalRequest)
		external
	;

	/**
	* @notice Update the For Vote Count Required
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [update] `forVoteCountRequired`
	* @param _forVoteCountRequired {uint256}
	* Emits: `UpdatedRequiredVoteCount`
	*/
	function updateForVoteCountRequired(uint256 _forVoteCountRequired)
		external
	;

	/**
	* @notice Update Signature Manager Contract
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [update] `signatureManager`
	* @param _signatureManager {address}
	*/
	function updateSignatureManager(address _signatureManager)
		external
	;

	/**
	* @notice Update `withdrawalDelaySeconds`
	* @dev [restriction] AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [update] `withdrawalDelaySeconds` to new value
	* @param _withdrawalDelaySeconds {uint256}
	* Emits: `UpdatedWithdrawalDelaySeconds`
	*/
	function updateWithdrawalDelaySeconds(uint256 _withdrawalDelaySeconds)
		external
	;


	/**
	* @notice Create a withdrawalRequest
	* @dev [restriction] AccessControlEnumerable → VOTER
	* @dev [increment] `_withdrawalRequestId`
	*      [add] `_withdrawalRequest` value
	*      [push-into] `_withdrawalRequestIds`
	* @param forEther {bool} If to be withdrawn asset is Ether
	* @param forERC20 {bool} If to be withdrawn asset is ERC20
	* @param forERC721 {bool} If to be withdrawn asset is ERC721
	* @param to {address} Address the withdrawn tokens will be sent
	* @param tokenAddress {address} Token address contract
	* @param amount {uint256} Amount to be withdrawn
	* @param tokenId {uint256} erc721 token id
	* Emits: `CreatedWithdrawalRequest`
	*/
	function createWithdrawalRequest(
		bool forEther,
		bool forERC20,
		bool forERC721,
		address to,
		address tokenAddress,
		uint256 amount,
		uint256 tokenId
	)
		external
	;

	/**
	* @notice Vote on withdrawalRequest
	* @dev [restriction] AccessControlEnumerable → VOTER
	* @dev [update] `_withdrawalRequest`
	* @param withdrawalRequestId {uint256}
	* @param vote {bool} true (approve) or false (deny)
	* Emits: `WithdrawalRequestReadyToBeProccessed`
	* Emits: `VoterVoted`
	*/
	function voteOnWithdrawalRequest(uint256 withdrawalRequestId, bool vote)
		external
	;

	/**
	* @notice Process withdrawalRequest with given `withdrawalRequestId`
	* @dev [restriction] AccessControlEnumerable → VOTER
	* @dev [erc20-transfer]
	*      [decrement] `_tokenBalance`
	*      [call][internal] `_deleteWithdrawalRequest`
	* @param withdrawalRequestId {uint256} Id of the WithdrawalRequest
	* Emits: `TokensWithdrawn`
	*/
	function processWithdrawalRequest(uint256 withdrawalRequestId)
		external
	;
}