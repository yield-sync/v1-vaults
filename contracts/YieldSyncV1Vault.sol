// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { IYieldSyncV1Vault, WithdrawalRequest } from "./interface/IYieldSyncV1Vault.sol";
import { IYieldSyncV1VaultAccessControl } from "./interface/IYieldSyncV1VaultAccessControl.sol";


contract YieldSyncV1Vault is
	IERC1271,
	IYieldSyncV1Vault
{
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


	address public override immutable YieldSyncV1VaultAccessControl;
	address public override signatureManager;

	bool public override processWithdrawalRequestLocked;

	uint256 public override againstVoteCountRequired;
	uint256 public override forVoteCountRequired;
	uint256 public override withdrawalDelaySeconds;
	uint256 internal _withdrawalRequestIdTracker;
	uint256[] internal _idsOfOpenWithdrawalRequests;

	mapping (
		uint256 withdrawalRequestId => WithdrawalRequest withdralRequest
	) internal _withdrawalRequestId_withdralRequest;


	constructor (
		address _YieldSyncV1VaultAccessControl,
		address[] memory admins,
		address[] memory members,
		address _signatureManager,
		uint256 _againstVoteCountRequired,
		uint256 _forVoteCountRequired,
		uint256 _withdrawalDelaySeconds
	)
	{
		YieldSyncV1VaultAccessControl = _YieldSyncV1VaultAccessControl;

		require(_forVoteCountRequired > 0, "!_forVoteCountRequired");

		for (uint i = 0; i < admins.length; i++)
		{
			IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).addAdmin(address(this), admins[i]);
		}

		for (uint i = 0; i < members.length; i++)
		{
			IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).addMember(address(this), members[i]);
		}

		signatureManager = _signatureManager;
		processWithdrawalRequestLocked = false;
		againstVoteCountRequired = _againstVoteCountRequired;
		forVoteCountRequired = _forVoteCountRequired;
		withdrawalDelaySeconds = _withdrawalDelaySeconds;

		_withdrawalRequestIdTracker = 0;
	}


	modifier validWithdrawalRequest(uint256 withdrawalRequestId)
	{
		require(
			_withdrawalRequestId_withdralRequest[withdrawalRequestId].amount > 0,
			"No WithdrawalRequest found"
		);

		_;
	}

	modifier onlyAdmin()
	{
		(bool admin,) = IYieldSyncV1VaultAccessControl(
			YieldSyncV1VaultAccessControl
		).participant_yieldSyncV1Vault_access(msg.sender, address(this));

		require(admin, "!admin");

		_;
	}

	modifier onlyMember()
	{
		(, bool member) = IYieldSyncV1VaultAccessControl(
			YieldSyncV1VaultAccessControl
		).participant_yieldSyncV1Vault_access(msg.sender, address(this));

		require(member, "!member");

		_;
	}


	/**
	* @notice Delete WithdrawalRequest
	* @dev [restriction][internal]
	* @dev [delete] `_withdrawalRequestId_withdralRequest` value
	*      [delete] `_idsOfOpenWithdrawalRequests` value
	* @param withdrawalRequestId {uint256}
	* Emits: `DeletedWithdrawalRequest`
	*/
	function _deleteWithdrawalRequest(uint256 withdrawalRequestId)
		internal
	{
		delete _withdrawalRequestId_withdralRequest[withdrawalRequestId];

		for (uint256 i = 0; i < _idsOfOpenWithdrawalRequests.length; i++)
		{
			if (_idsOfOpenWithdrawalRequests[i] == withdrawalRequestId)
			{
				_idsOfOpenWithdrawalRequests[i] = _idsOfOpenWithdrawalRequests[_idsOfOpenWithdrawalRequests.length - 1];

				_idsOfOpenWithdrawalRequests.pop();

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
	function idsOfOpenWithdrawalRequests()
		public
		view
		override
		returns (uint256[] memory)
	{
		return _idsOfOpenWithdrawalRequests;
	}

	/// @inheritdoc IYieldSyncV1Vault
	function withdrawalRequestId_withdralRequest(uint256 withdrawalRequestId)
		public
		view
		override
		validWithdrawalRequest(withdrawalRequestId)
		returns (WithdrawalRequest memory)
	{
		return _withdrawalRequestId_withdralRequest[withdrawalRequestId];
	}


	/// @inheritdoc IYieldSyncV1Vault
	function addAdmin(address targetAddress)
		public
		override
		onlyAdmin()
	{
		IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).addAdmin(address(this), targetAddress);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function removeAdmin(address admin)
		public
		override
		onlyAdmin()
	{
		IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).removeAdmin(address(this), admin);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function addMember(address targetAddress)
		public
		override
		onlyAdmin()
	{
		IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).addMember(address(this), targetAddress);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function removeMember(address member)
		public
		override
		onlyAdmin()
	{
		IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).removeMember(address(this), member);
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
		_withdrawalRequestId_withdralRequest[withdrawalRequestId] = __withdrawalRequest;

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

		_withdrawalRequestId_withdralRequest[_withdrawalRequestIdTracker] = WithdrawalRequest(
			{
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

		_idsOfOpenWithdrawalRequests.push(_withdrawalRequestIdTracker);

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
		for (uint256 i = 0; i < _withdrawalRequestId_withdralRequest[withdrawalRequestId].votedMembers.length; i++)
		{
			require(
				_withdrawalRequestId_withdralRequest[withdrawalRequestId].votedMembers[i] != msg.sender,
				"Already voted"
			);
		}

		if (vote)
		{
			_withdrawalRequestId_withdralRequest[withdrawalRequestId].forVoteCount++;
		}
		else
		{
			_withdrawalRequestId_withdralRequest[withdrawalRequestId].againstVoteCount++;
		}

		if (
			_withdrawalRequestId_withdralRequest[withdrawalRequestId].forVoteCount >= forVoteCountRequired ||
			_withdrawalRequestId_withdralRequest[withdrawalRequestId].againstVoteCount >= againstVoteCountRequired
		)
		{
			emit WithdrawalRequestReadyToBeProcessed(withdrawalRequestId);
		}

		_withdrawalRequestId_withdralRequest[withdrawalRequestId].votedMembers.push(msg.sender);

		if (_withdrawalRequestId_withdralRequest[withdrawalRequestId].forVoteCount < forVoteCountRequired)
		{
			_withdrawalRequestId_withdralRequest[withdrawalRequestId].latestRelevantApproveVoteTime = block.timestamp;
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
		require(!processWithdrawalRequestLocked, "processWithdrawalRequestLocked");
		require(
			_withdrawalRequestId_withdralRequest[withdrawalRequestId].forVoteCount >= forVoteCountRequired ||
			_withdrawalRequestId_withdralRequest[withdrawalRequestId].againstVoteCount >= againstVoteCountRequired,
			"!forVoteCountRequired && !againstVoteCount"
		);

		processWithdrawalRequestLocked = true;

		if (_withdrawalRequestId_withdralRequest[withdrawalRequestId].forVoteCount >= forVoteCountRequired)
		{
			require(
				block.timestamp - _withdrawalRequestId_withdralRequest[
					withdrawalRequestId
				].latestRelevantApproveVoteTime >= withdrawalDelaySeconds * 1 seconds,
				"Not enough time has passed"
			);

			if (
				_withdrawalRequestId_withdralRequest[withdrawalRequestId].forERC20 &&
				!_withdrawalRequestId_withdralRequest[withdrawalRequestId].forERC721
			)
			{
				if (
					IERC20(_withdrawalRequestId_withdralRequest[withdrawalRequestId].token).balanceOf(address(this)) >=
					_withdrawalRequestId_withdralRequest[withdrawalRequestId].amount
				)
				{
					// [ERC20-transfer]
					IERC20(_withdrawalRequestId_withdralRequest[withdrawalRequestId].token).transfer(
						_withdrawalRequestId_withdralRequest[withdrawalRequestId].to,
						_withdrawalRequestId_withdralRequest[withdrawalRequestId].amount
					);
				}
				else
				{
					emit ProcessWithdrawalRequestFailed(withdrawalRequestId);
				}
			}

			if (
				!_withdrawalRequestId_withdralRequest[withdrawalRequestId].forERC20 &&
				_withdrawalRequestId_withdralRequest[withdrawalRequestId].forERC721
			)
			{
				if (
					IERC721(_withdrawalRequestId_withdralRequest[withdrawalRequestId].token).ownerOf(
						_withdrawalRequestId_withdralRequest[withdrawalRequestId].tokenId
					) == address(this)
				)
				{
					// [ERC721-transfer]
					IERC721(_withdrawalRequestId_withdralRequest[withdrawalRequestId].token).transferFrom(
						address(this),
						_withdrawalRequestId_withdralRequest[withdrawalRequestId].to,
						_withdrawalRequestId_withdralRequest[withdrawalRequestId].tokenId
					);
				}
				else
				{
					emit ProcessWithdrawalRequestFailed(withdrawalRequestId);
				}
			}

			if (
				!_withdrawalRequestId_withdralRequest[withdrawalRequestId].forERC20 &&
				!_withdrawalRequestId_withdralRequest[withdrawalRequestId].forERC721
			)
			{
				// [transfer]
				(bool success, ) = _withdrawalRequestId_withdralRequest[withdrawalRequestId].to.call{
					value: _withdrawalRequestId_withdralRequest[withdrawalRequestId].amount
				}("");

				if (!success)
				{
					emit ProcessWithdrawalRequestFailed(withdrawalRequestId);
				}
			}

			emit TokensWithdrawn(
				msg.sender,
				_withdrawalRequestId_withdralRequest[withdrawalRequestId].to,
				_withdrawalRequestId_withdralRequest[withdrawalRequestId].amount
			);
		}

		processWithdrawalRequestLocked = false;

		_deleteWithdrawalRequest(withdrawalRequestId);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function renounceMembership()
		public
		override
		onlyMember()
	{
		IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).removeMember(address(this), msg.sender);
	}
}
