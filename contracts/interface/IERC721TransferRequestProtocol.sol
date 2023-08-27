// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { ITransferRequestProtocol, TransferRequest } from "./ITransferRequestProtocol.sol";
import { IYieldSyncV1VaultRegistry } from "./IYieldSyncV1VaultRegistry.sol";


struct YieldSyncV1VaultProperty
{
	address erc721Token;
	uint256 voteAgainstRequired;
	uint256 voteForRequired;
}

struct TransferRequestPoll
{
	uint256[] voteAgainstErc721TokenId;
	uint256[] voteForErc721TokenId;
}


interface IERC721TransferRequestProtocol is
	ITransferRequestProtocol
{
	event CreatedTransferRequest(address yieldSyncV1Vault, uint256 transferRequestId);
	event DeletedTransferRequest(address yieldSyncV1Vault, uint256 transferRequestId);
	event UpdateTransferRequest(address yieldSyncV1Vault, TransferRequest transferRequest);
	event UpdateTransferRequestPoll(address yieldSyncV1Vault, TransferRequestPoll transferRequestPoll);
	event MemberVoted(address yieldSyncV1Vault, uint256 transferRequestId, address member, bool vote);
	event TransferRequestReadyToBeProcessed(address yieldSyncV1Vault, uint256 transferRequestId);
}
