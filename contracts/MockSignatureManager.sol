// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "hardhat/console.sol";


struct SignatureObject {
	address signer;
	address[] votedVoters;
	bytes32 messageHash;
	string message;
	uint256 votes;
}


/**
 * @title MockSignatureManager
*/
contract MockSignatureManager is
	IERC1271
{
	bytes4 public constant ERC1271_MAGIC_VALUE = 0x1626ba7e;


	// [mapping][internal]
	mapping (address => SignatureObject[]) vaultSignatureObject;


	/// @inheritdoc IERC1271
	function isValidSignature(bytes32 _messageHash, bytes memory _signature)
		public
		view
		override
		returns (bytes4 magicValue)
	{	
		if (true)
		{
			address recovered = ECDSA.recover(
				ECDSA.toEthSignedMessageHash(_messageHash),
				_signature
			);

			require(recovered != address(0), "!recovered");

			return ERC1271_MAGIC_VALUE;
		}
		else
		{
			console.logBytes(_signature);
			console.logBytes32(_messageHash);
			return bytes4(0);
		}
	}


    function verifyStringSignature(
		string memory message,
		uint8 v,
		bytes32 r,
		bytes32 s
	)
		public
		pure
		returns (address)
	{
		return ECDSA.recover(ECDSA.toEthSignedMessageHash(abi.encodePacked(message)), v, r, s);
	}


	function verifyHashSignature(
		bytes32 hash,
		uint8 v,
		bytes32 r,
		bytes32 s
	)
		public
		pure
		returns (address)
	{
		return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), v, r, s);
	}


	function signMessageHash(address iglooFiV1Vault, bytes32 messageHash) public {
	}
}