// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


struct TransferRequest
{
	bool forERC20;
	bool forERC721;
	address creator;
	address token;
	uint256 tokenId;
	uint256 amount;
	address to;
}


interface ITransferRequestProtocol
{
	/**
	* @param yieldSyncV1VaultAddress {address}
	* @param transferRequestId {uint256}
	* @return {TransferRequest}
	*/
	function yieldSyncV1VaultAddress_transferRequestId_transferRequest(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId
	)
		external
		view returns (TransferRequest memory)
	;

	/**
	* @param yieldSyncV1VaultAddress {address}
	* @param transferRequestId {uint256}
	*/
	function yieldSyncV1VaultAddress_transferRequestId_transferRequestProcess(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId
	)
		external
	;

	/**
	* @param yieldSyncV1VaultAddress {address}
	* @param transferRequestId {uint256}
	* @return readyToBeProcessed {bool}
	* @return approved {bool}
	* @return message {string}
	*/
	function yieldSyncV1VaultAddress_transferRequestId_transferRequestStatus(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId
	)
		external
		view
		returns (bool readyToBeProcessed, bool approved, string memory message)
	;


	/**
	* @param initiator {address}
	* @param yieldSyncV1VaultAddress {address}
	*/
	function yieldSyncV1VaultInitialize(address initiator, address yieldSyncV1VaultAddress)
		external
	;
}
