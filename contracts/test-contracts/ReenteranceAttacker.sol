// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


/* solhint-disable */
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { console } from "hardhat/console.sol";

import { IYieldSyncV1Vault } from "../interface/IYieldSyncV1Vault.sol";


contract ReenteranceAttacker is Ownable
{
	address public vaultAddress;

	uint256 public transferRequestId;


	receive ()
		external
		payable
	{
		IYieldSyncV1Vault(payable(vaultAddress)).yieldSyncV1Vault_transferRequestId_transferRequestProcess(
			transferRequestId
		);

		console.log("This should not display unless a reenterancy attack has been accomplished!");
	}


	function attack(address _vaultAddress, uint256 _transferRequestId)
		external
		payable
	{
		vaultAddress = _vaultAddress;

		transferRequestId = _transferRequestId;

		IYieldSyncV1Vault(payable(_vaultAddress)).yieldSyncV1Vault_transferRequestId_transferRequestProcess(
			_transferRequestId
		);
	}

	function etherTransfer(address to)
		public
		onlyOwner()
	{
		(bool success, ) = to.call{value: address(this).balance}("");

		require(success, "etherTransfer failed");
	}
}
