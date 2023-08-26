// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


struct TransferRequest
{
	bool forERC20;
	bool forERC721;
	address creator;
	address to;
	address token;
	uint256 amount;
	uint256 created;
	uint256 tokenId;
}


interface ITransferRequestProtocol
{
	/**
	* @param yieldSyncV1Vault {address}
	* @param transferRequestId {uint256}
	* @return {TransferRequest}
	*/
	function yieldSyncV1Vault_transferRequestId_transferRequest(address yieldSyncV1Vault, uint256 transferRequestId)
		external
		view returns (TransferRequest memory)
	;

	/**
	* @param yieldSyncV1Vault {address}
	* @param transferRequestId {uint256}
	*/
	function yieldSyncV1Vault_transferRequestId_transferRequestProcess(
		address yieldSyncV1Vault,
		uint256 transferRequestId
	)
		external
	;

	/**
	* @param yieldSyncV1Vault {address}
	* @param transferRequestId {uint256}
	* @return readyToBeProcessed {bool}
	* @return approved {bool}
	* @return message {string}
	*/
	function yieldSyncV1Vault_transferRequestId_transferRequestStatus(
		address yieldSyncV1Vault,
		uint256 transferRequestId
	)
		external
		view
		returns (bool readyToBeProcessed, bool approved, string memory message)
	;


	/**
	* @param initiator {address}
	* @param yieldSyncV1Vault {address}
	*/
	function yieldSyncV1VaultInitialize(address initiator, address yieldSyncV1Vault)
		external
	;
}
