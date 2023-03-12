// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { IYieldSyncV1Vault, WithdrawalRequest } from "./interface/IYieldSyncV1Vault.sol";
import { IYieldSyncV1VaultRecord } from "./interface/IYieldSyncV1VaultRecord.sol";


/**
* @title YieldSyncV1Vault
*/
contract YieldSyncV1Vault is
	IERC1271,
	IYieldSyncV1Vault
{
	// [address]
	address public override yieldSyncV1VaultRecord;
	address public override signatureManager;

	// [uint256]
	uint256 public override againstVoteCountRequired;
	uint256 public override forVoteCountRequired;
	uint256 public override withdrawalDelaySeconds;
	uint256 internal _withdrawalRequestIdTracker;
	uint256[] internal _openWithdrawalRequestIds;

	// [mapping]
	// withdrawalRequestId => withdralRequest
	mapping (uint256 => WithdrawalRequest) internal _withdrawalRequest;


	constructor (
		address _yieldSyncV1VaultRecord,
		address admin,
		address[] memory members,
		address _signatureManager,
		uint256 _againstVoteCountRequired,
		uint256 _forVoteCountRequired,
		uint256 _withdrawalDelaySeconds
	)
	{
		require(_forVoteCountRequired > 0, "!_forVoteCountRequired");

		IYieldSyncV1VaultRecord(_yieldSyncV1VaultRecord).addAdmin(address(this), admin);

		for (uint i = 0; i < members.length; i++)
		{
			IYieldSyncV1VaultRecord(_yieldSyncV1VaultRecord).addMember(address(this), members[i]);
		}

		yieldSyncV1VaultRecord = _yieldSyncV1VaultRecord;
		signatureManager = _signatureManager;
		againstVoteCountRequired = _againstVoteCountRequired;
		forVoteCountRequired = _forVoteCountRequired;
		withdrawalDelaySeconds = _withdrawalDelaySeconds;

		_withdrawalRequestIdTracker = 0;
	}


	receive ()
		external
		payable
		override
	{}


	fallback ()
		external
		payable
		override
	{}


	modifier validWithdrawalRequest(uint256 withdrawalRequestId)
	{
		require(
			_withdrawalRequest[withdrawalRequestId].forEther ||
			_withdrawalRequest[withdrawalRequestId].forERC20 ||
			_withdrawalRequest[withdrawalRequestId].forERC721,
			"No WithdrawalRequest found"
		);

		_;
	}


	modifier onlyAdmin()
	{
		(bool admin,) = IYieldSyncV1VaultRecord(yieldSyncV1VaultRecord).participant_yieldSyncV1Vault_access(
			msg.sender,
			address(this)
		);

		require(admin, "!admin");

		_;
	}


	modifier onlyMember()
	{
		(, bool member) = IYieldSyncV1VaultRecord(yieldSyncV1VaultRecord).participant_yieldSyncV1Vault_access(
			msg.sender,
			address(this)
		);

		require(member, "!member");

		_;
	}


	/**
	* @notice Delete WithdrawalRequest
	* @dev [restriction][internal]
	* @dev [delete] `_withdrawalRequest` value
	*      [delete] `_openWithdrawalRequestIds` value
	* @param withdrawalRequestId {uint256}
	* Emits: `DeletedWithdrawalRequest`
	*/
	function _deleteWithdrawalRequest(uint256 withdrawalRequestId)
		internal
	{
		delete _withdrawalRequest[withdrawalRequestId];

		for (uint256 i = 0; i < _openWithdrawalRequestIds.length; i++)
		{
			if (_openWithdrawalRequestIds[i] == withdrawalRequestId)
			{
				_openWithdrawalRequestIds[i] = _openWithdrawalRequestIds[_openWithdrawalRequestIds.length - 1];

				_openWithdrawalRequestIds.pop();

				break;
			}
		}
	}


	/// @inheritdoc IERC1271
	function isValidSignature(bytes32 _messageHash, bytes memory _signature)
		public
		view
		override
		returns (bytes4 magicValue)
	{
		return IERC1271(signatureManager).isValidSignature(_messageHash, _signature);
	}


	/// @inheritdoc IYieldSyncV1Vault
	function openWithdrawalRequestIds()
		public
		view
		override
		returns (uint256[] memory)
	{
		return _openWithdrawalRequestIds;
	}

	/// @inheritdoc IYieldSyncV1Vault
	function withdrawalRequest(uint256 withdrawalRequestId)
		public
		view
		override
		validWithdrawalRequest(withdrawalRequestId)
		returns (WithdrawalRequest memory)
	{
		return _withdrawalRequest[withdrawalRequestId];
	}


	/// @inheritdoc IYieldSyncV1Vault
	function addAdmin(address targetAddress)
		public
		override
		onlyAdmin()
	{
		IYieldSyncV1VaultRecord(yieldSyncV1VaultRecord).addAdmin(address(this), targetAddress);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function removeAdmin(address admin)
		public
		override
		onlyAdmin()
	{
		IYieldSyncV1VaultRecord(yieldSyncV1VaultRecord).removeAdmin(address(this), admin);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function addMember(address targetAddress)
		public
		override
		onlyAdmin()
	{
		IYieldSyncV1VaultRecord(yieldSyncV1VaultRecord).addMember(address(this), targetAddress);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function removeMember(address member)
		public
		override
		onlyAdmin()
	{
		IYieldSyncV1VaultRecord(yieldSyncV1VaultRecord).removeMember(address(this), member);
	}


	/// @inheritdoc IYieldSyncV1Vault
	function deleteWithdrawalRequest(uint256 withdrawalRequestId)
		public
		override
		onlyAdmin()
		validWithdrawalRequest(withdrawalRequestId)
	{
		_deleteWithdrawalRequest(withdrawalRequestId);

		emit DeletedWithdrawalRequest(withdrawalRequestId);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function updateWithdrawalRequest(uint256 withdrawalRequestId, WithdrawalRequest memory __withdrawalRequest)
		public
		override
		onlyAdmin()
		validWithdrawalRequest(withdrawalRequestId)
	{
		_withdrawalRequest[withdrawalRequestId] = __withdrawalRequest;

		emit UpdatedWithdrawalRequest(__withdrawalRequest);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function updateAgainstVoteCountRequired(uint256 _againstVoteCountRequired)
		public
		override
		onlyAdmin()
	{
		require(_againstVoteCountRequired > 0, "!_againstVoteCountRequired");

		againstVoteCountRequired = _againstVoteCountRequired;

		emit UpdatedAgainstVoteCountRequired(againstVoteCountRequired);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function updateForVoteCountRequired(uint256 _forVoteCountRequired)
		public
		override
		onlyAdmin()
	{
		require(_forVoteCountRequired > 0, "!_forVoteCountRequired");

		forVoteCountRequired = _forVoteCountRequired;

		emit UpdatedForVoteCountRequired(forVoteCountRequired);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function updateSignatureManager(address _signatureManager)
		public
		override
		onlyAdmin()
	{
		signatureManager = _signatureManager;

		emit UpdatedSignatureManger(signatureManager);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function updateWithdrawalDelaySeconds(uint256 _withdrawalDelaySeconds)
		public
		override
		onlyAdmin()
	{
		require(_withdrawalDelaySeconds >= 0, "!_withdrawalDelaySeconds");

		withdrawalDelaySeconds = _withdrawalDelaySeconds;

		emit UpdatedWithdrawalDelaySeconds(withdrawalDelaySeconds);
	}


	/// @inheritdoc IYieldSyncV1Vault
	function createWithdrawalRequest(
		bool forEther,
		bool forERC20,
		bool forERC721,
		address to,
		address tokenAddress,
		uint256 amount,
		uint256 tokenId
	)
		public
		override
		onlyMember()
	{
		require(amount > 0, "!amount");

		address[] memory initialVotedMembers;

		_withdrawalRequest[_withdrawalRequestIdTracker] = WithdrawalRequest(
			{
				forEther: forEther,
				forERC20: forERC20,
				forERC721: forERC721,
				creator: msg.sender,
				to: to,
				token: tokenAddress,
				amount: amount,
				tokenId: tokenId,
				forVoteCount: 0,
				againstVoteCount: 0,
				latestRelevantApproveVoteTime: block.timestamp,
				votedMembers: initialVotedMembers
			}
		);

		_openWithdrawalRequestIds.push(_withdrawalRequestIdTracker);

		_withdrawalRequestIdTracker++;

		emit CreatedWithdrawalRequest(_withdrawalRequestIdTracker - 1);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function voteOnWithdrawalRequest(uint256 withdrawalRequestId, bool vote)
		public
		override
		onlyMember()
		validWithdrawalRequest(withdrawalRequestId)
	{
		for (uint256 i = 0; i < _withdrawalRequest[withdrawalRequestId].votedMembers.length; i++)
		{
			require(_withdrawalRequest[withdrawalRequestId].votedMembers[i] != msg.sender, "Already voted");
		}

		if (vote)
		{
			_withdrawalRequest[withdrawalRequestId].forVoteCount++;
		}
		else {
			_withdrawalRequest[withdrawalRequestId].againstVoteCount++;
		}

		if (
			_withdrawalRequest[withdrawalRequestId].forVoteCount >= forVoteCountRequired ||
			_withdrawalRequest[withdrawalRequestId].againstVoteCount >= againstVoteCountRequired
		)
		{
			emit WithdrawalRequestReadyToBeProcessed(withdrawalRequestId);
		}

		_withdrawalRequest[withdrawalRequestId].votedMembers.push(msg.sender);

		if (_withdrawalRequest[withdrawalRequestId].forVoteCount < forVoteCountRequired)
		{
			_withdrawalRequest[withdrawalRequestId].latestRelevantApproveVoteTime = block.timestamp;
		}

		emit MemberVoted(withdrawalRequestId, msg.sender, vote);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function processWithdrawalRequest(uint256 withdrawalRequestId)
		public
		override
		onlyMember()
		validWithdrawalRequest(withdrawalRequestId)
	{
		WithdrawalRequest memory wR = _withdrawalRequest[withdrawalRequestId];

		require(
			wR.forVoteCount >= forVoteCountRequired || wR.againstVoteCount >= againstVoteCountRequired,
			"!forVoteCountRequired && !againstVoteCount"
		);

		if (wR.forVoteCount >= forVoteCountRequired)
		{
			require(
				block.timestamp - wR.latestRelevantApproveVoteTime >= withdrawalDelaySeconds * 1 seconds,
				"Not enough time has passed"
			);

			// Transfer accordingly
			if (wR.forERC20 && !wR.forERC721)
			{
				if (IERC20(wR.token).balanceOf(address(this)) >= wR.amount)
				{
					// [ERC20-transfer]
					IERC20(wR.token).transfer(wR.to, wR.amount);
				}
			}
			else if (wR.forERC721 && !wR.forERC20)
			{
				if (IERC721(wR.token).ownerOf(wR.tokenId) == address(this))
				{
					// [ERC721-transfer]
					IERC721(wR.token).transferFrom(address(this), wR.to, wR.tokenId);
				}
			}
			else if (wR.forEther)
			{
				// [transfer]
				(bool success, ) = wR.to.call{value: wR.amount}("");

				require(success, "Unable to send value");
			}

			emit TokensWithdrawn(msg.sender, wR.to, wR.amount);
		}

		_deleteWithdrawalRequest(withdrawalRequestId);
	}
}
