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


interface IYieldSyncV1ERC721TransferRequestProtocol is
	ITransferRequestProtocol
{
	event CreatedTransferRequest(address _yieldSyncV1Vault, uint256 _transferRequestId);
	event DeletedTransferRequest(address _yieldSyncV1Vault, uint256 _transferRequestId);
	event UpdateTransferRequest(address _yieldSyncV1Vault, TransferRequest _transferRequest);
	event UpdateTransferRequestPoll(address _yieldSyncV1Vault, TransferRequestPoll _transferRequestPoll);
	event MemberVoted(address _yieldSyncV1Vault, uint256 _transferRequestId, address _member, bool _vote);
	event TransferRequestReadyToBeProcessed(address _yieldSyncV1Vault, uint256 _transferRequestId);
}
