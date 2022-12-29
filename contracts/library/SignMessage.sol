// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


import "@openzeppelin/contracts/interfaces/IERC1271.sol";


contract SignMessage {
	bytes4 public constant EIP1271_MAGICVALUE = 0x1626ba7e;

	function signMessage(
		address contractAddress,
		bytes32 payloadHash,
		bytes memory signature
	)
		internal
		view
	{
		try IERC1271(contractAddress).isValidSignature(payloadHash, signature)
			returns (bytes4 result)
		{
			require(result == EIP1271_MAGICVALUE, "INVALID_SIGNATURE");
		}
		catch
		{
			revert("INVALID_SIGNATURE_VALIDATION");
		}
	}
}