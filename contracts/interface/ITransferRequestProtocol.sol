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
	* @notice Getter for `_yieldSyncV1Vault_transferRequestId_transferRequest`
	* @dev [view][mapping]
	* @param _yieldSyncV1Vault {address}
	* @param _transferRequestId {uint256}
	*/
	function yieldSyncV1Vault_transferRequestId_transferRequest(address _yieldSyncV1Vault, uint256 _transferRequestId)
		external
		view
		returns (TransferRequest memory transferRequest_)
	;

	/**
	* @param _yieldSyncV1Vault {address}
	* @param _transferRequestId {uint256}
	*/
	function yieldSyncV1Vault_transferRequestId_transferRequestProcess(
		address _yieldSyncV1Vault,
		uint256 _transferRequestId
	)
		external
	;

	/**
	* @param _yieldSyncV1Vault {address}
	* @param _transferRequestId {uint256}
	* @return readyToBeProcessed_ {bool}
	* @return approved_ {bool}
	* @return message_ {string}
	*/
	function yieldSyncV1Vault_transferRequestId_transferRequestStatus(
		address _yieldSyncV1Vault,
		uint256 _transferRequestId
	)
		external
		view
		returns (bool readyToBeProcessed_, bool approved_, string memory message_)
	;


	/**
	* @param _initiator {address}
	* @param _yieldSyncV1Vault {address}
	*/
	function yieldSyncV1VaultInitialize(address _initiator, address _yieldSyncV1Vault)
		external
	;
}
