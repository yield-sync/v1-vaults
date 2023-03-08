// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { IIglooFiV1Vault, WithdrawalRequest } from "./interface/IIglooFiV1Vault.sol";
import { IIglooFiV1VaultRecord } from "./interface/IIglooFiV1VaultRecord.sol";


/**
* @title IglooFiV1Vault
*/
contract IglooFiV1Vault is
	AccessControl,
	IERC1271,
	IIglooFiV1Vault
{
	// [address]
	address public iglooFiV1VaultRecord;
	address public override signatureManager;

	// [bytes4]
	bytes32 public constant override VOTER = keccak256("VOTER");

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
		address _iglooFiV1VaultRecord,
		address admin,
		address[] memory members,
		address _signatureManager,
		uint256 _againstVoteCountRequired,
		uint256 _forVoteCountRequired,
		uint256 _withdrawalDelaySeconds
	)
	{
		require(_forVoteCountRequired > 0, "!_forVoteCountRequired");

		_setupRole(DEFAULT_ADMIN_ROLE, admin);

		for (uint i = 0; i < members.length; i++)
		{
			IIglooFiV1VaultRecord(_iglooFiV1VaultRecord).addMember(address(this), members[i]);
		}

		iglooFiV1VaultRecord = _iglooFiV1VaultRecord;
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


	modifier onlyAdmin(address participant)
	{
		(bool admin,) = IIglooFiV1VaultRecord(iglooFiV1VaultRecord).participant_iglooFiV1Vault_access(
			address(this),
			participant
		);

		require(admin, "!admin");

		_;
	}


	modifier onlyMember(address participant)
	{
		(, bool member) = IIglooFiV1VaultRecord(iglooFiV1VaultRecord).participant_iglooFiV1Vault_access(
			address(this),
			participant
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


	/// @inheritdoc IIglooFiV1Vault
	function openWithdrawalRequestIds()
		public
		view
		override
		returns (uint256[] memory)
	{
		return _openWithdrawalRequestIds;
	}

	/// @inheritdoc IIglooFiV1Vault
	function withdrawalRequest(uint256 withdrawalRequestId)
		public
		view
		override
		validWithdrawalRequest(withdrawalRequestId)
		returns (WithdrawalRequest memory)
	{
		return _withdrawalRequest[withdrawalRequestId];
	}


	/// @inheritdoc IIglooFiV1Vault
	function addVoter(address targetAddress)
		public
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		_setupRole(VOTER, targetAddress);
		
		IIglooFiV1VaultRecord(iglooFiV1VaultRecord).addMember(address(this),targetAddress);
	}

	/// @inheritdoc IIglooFiV1Vault
	function removeVoter(address voter)
		public
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		_revokeRole(VOTER, voter);
	}

	/// @inheritdoc IIglooFiV1Vault
	function deleteWithdrawalRequest(uint256 withdrawalRequestId)
		public
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
		validWithdrawalRequest(withdrawalRequestId)
	{
		_deleteWithdrawalRequest(withdrawalRequestId);

		emit DeletedWithdrawalRequest(withdrawalRequestId);
	}

	/// @inheritdoc IIglooFiV1Vault
	function updateWithdrawalRequest(uint256 withdrawalRequestId, WithdrawalRequest memory __withdrawalRequest)
		public
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
		validWithdrawalRequest(withdrawalRequestId)
	{
		_withdrawalRequest[withdrawalRequestId] = __withdrawalRequest;

		emit UpdatedWithdrawalRequest(__withdrawalRequest);
	}

	/// @inheritdoc IIglooFiV1Vault
	function updateAgainstVoteCountRequired(uint256 _againstVoteCountRequired)
		public
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(_againstVoteCountRequired > 0, "!_againstVoteCountRequired");

		againstVoteCountRequired = _againstVoteCountRequired;

		emit UpdatedAgainstVoteCountRequired(againstVoteCountRequired);
	}

	/// @inheritdoc IIglooFiV1Vault
	function updateForVoteCountRequired(uint256 _forVoteCountRequired)
		public
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(_forVoteCountRequired > 0, "!_forVoteCountRequired");

		forVoteCountRequired = _forVoteCountRequired;

		emit UpdatedForVoteCountRequired(forVoteCountRequired);
	}

	/// @inheritdoc IIglooFiV1Vault
	function updateSignatureManager(address _signatureManager)
		public
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		signatureManager = _signatureManager;

		emit UpdatedSignatureManger(signatureManager);
	}

	/// @inheritdoc IIglooFiV1Vault
	function updateWithdrawalDelaySeconds(uint256 _withdrawalDelaySeconds)
		public
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(_withdrawalDelaySeconds >= 0, "!_withdrawalDelaySeconds");

		withdrawalDelaySeconds = _withdrawalDelaySeconds;

		emit UpdatedWithdrawalDelaySeconds(withdrawalDelaySeconds);
	}


	/// @inheritdoc IIglooFiV1Vault
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
		onlyRole(VOTER)
	{
		require(amount > 0, "!amount");

		address[] memory initialVotedVoters;

		_withdrawalRequest[_withdrawalRequestIdTracker] = WithdrawalRequest(
			{
				forEther: forEther,
				forERC20: forERC20,
				forERC721: forERC721,
				creator: _msgSender(),
				to: to,
				token: tokenAddress,
				amount: amount,
				tokenId: tokenId,
				forVoteCount: 0,
				againstVoteCount: 0,
				latestRelevantApproveVoteTime: block.timestamp,
				votedVoters: initialVotedVoters
			}
		);

		_openWithdrawalRequestIds.push(_withdrawalRequestIdTracker);

		_withdrawalRequestIdTracker++;

		emit CreatedWithdrawalRequest(_withdrawalRequestIdTracker - 1);
	}

	/// @inheritdoc IIglooFiV1Vault
	function voteOnWithdrawalRequest(uint256 withdrawalRequestId, bool vote)
		public
		override
		onlyRole(VOTER)
		validWithdrawalRequest(withdrawalRequestId)
	{
		for (uint256 i = 0; i < _withdrawalRequest[withdrawalRequestId].votedVoters.length; i++)
		{
			require(_withdrawalRequest[withdrawalRequestId].votedVoters[i] != _msgSender(), "Already voted");
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

		_withdrawalRequest[withdrawalRequestId].votedVoters.push(_msgSender());

		if (_withdrawalRequest[withdrawalRequestId].forVoteCount < forVoteCountRequired)
		{
			_withdrawalRequest[withdrawalRequestId].latestRelevantApproveVoteTime = block.timestamp;
		}

		emit VoterVoted(withdrawalRequestId, _msgSender(), vote);
	}

	/// @inheritdoc IIglooFiV1Vault
	function processWithdrawalRequest(uint256 withdrawalRequestId)
		public
		override
		onlyRole(VOTER)
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

			emit TokensWithdrawn(_msgSender(), wR.to, wR.amount);
		}

		_deleteWithdrawalRequest(withdrawalRequestId);
	}
}