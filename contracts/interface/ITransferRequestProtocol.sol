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
	function yieldSyncV1Vault_transferRequestId_transferRequest(
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
	function yieldSyncV1Vault_transferRequestId_transferRequest__process(
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
	function yieldSyncV1Vault_transferRequestId_transferRequest__status(
		address yieldSyncV1VaultAddress,
		uint256 transferRequestId
	)
		external
		view
		returns (bool readyToBeProcessed, bool approved, string memory message)
	;


	/**
	* @param purposer {address}
	* @param yieldSyncV1VaultAddress {address}
	*/
	function yieldSyncV1Vault_yieldSyncV1VaultProperty__update(
		address purposer,
		address yieldSyncV1VaultAddress
	)
		external
	;
}
