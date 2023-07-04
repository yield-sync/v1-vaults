/**
 * @notice A YieldSyncV1VaultFactory needs to be already deployed befor running this script. The address of such a
 * contract should be stored in `YIELD_SYNC_V1_VAULT_FACTORY` in the .env file. If you would like to run this script on
 * a specified network than pass `--network <network-name>` to the CLI.
*/
require("dotenv").config();

import { Contract, ContractFactory } from "ethers";
import { ethers, run } from "hardhat";

async function main() {
	const [owner, addr1] = await ethers.getSigners();

	// [log]
	console.log("Deploying contract with Account:", owner.address);
	console.log("Account Balance:", await owner.getBalance());

	// Attach the deployed vault's address
	const YieldSyncV1VaultFactory: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultFactory");

	const yieldSyncV1VaultFactory = await YieldSyncV1VaultFactory.attach(
		String(process.env.YIELD_SYNC_V1_VAULT_FACTORY)
	);

	// Deploy a vault
	const yieldSyncV1Vault: Contract = await yieldSyncV1VaultFactory.deployYieldSyncV1Vault(
		ethers.constants.AddressZero,
		ethers.constants.AddressZero,
		[owner.address],
		[addr1.address],
		true,
		true,
		{ value: 0 }
	);


	// Delay
	const delay = (ms: number) => new Promise(res => setTimeout(res, ms));

	// Delay
	await delay(30000);

	// verify
	try
	{
		// yieldSyncV1Vault
		await run(
			"verify:verify",
			{
				address: yieldSyncV1Vault.address,
				constructorArguments: [
					ethers.constants.AddressZero,
					ethers.constants.AddressZero,
					[owner.address],
					[addr1.address],
					true,
					true
				],
			}
		);
	}
	catch (e: any)
	{
		if (e.message.toLowerCase().includes("already verified"))
		{
			console.log("Already verified!");
		}
		else
		{
			console.error(e);
		}
	}
}

main()
	.then(() => {
		process.exit(0);
	})
	.catch((error) => {
		console.error(error);
		process.exit(1);
	})
;
