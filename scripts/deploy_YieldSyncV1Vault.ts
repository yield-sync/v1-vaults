/**
 * @notice A instance of YieldSyncV1VaultFactory and YieldSyncV1ATransferRequestProtocol needs to be already deployed
 * befor running this script. The addresses of such contracts should be stored in `YIELD_SYNC_V1_VAULT_FACTORY` and
 * `YIELD_SYNC_V1_VAULT_TRANSFER_REQUEST_PROTOCOL` in the .env file. If you would like to run this script ona specified
 * network than pass `--network <network-name>` to the CLI.
*/
require("dotenv").config();

import { Contract, ContractFactory } from "ethers";
import { ethers, run } from "hardhat";

async function main() {
	const [owner] = await ethers.getSigners();

	// [log]
	console.log("Deploying contract with Account:", owner.address);
	console.log("Account Balance:", await owner.getBalance());

	// Factory
	const YieldSyncV1VaultFactory: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultFactory");
	const YieldSyncV1ATransferRequestProtocol: ContractFactory = await ethers.getContractFactory(
		"YieldSyncV1ATransferRequestProtocol"
	);

	// Attach the deployed YieldSyncV1VaultFactory address
	const yieldSyncV1VaultFactory = await YieldSyncV1VaultFactory.attach(
		String(process.env.YIELD_SYNC_V1_VAULT_FACTORY)
	);

	// Attach the deployed YieldSyncV1ATransferRequestProtocol address
	const yieldSyncV1ATransferRequestProtocol = await YieldSyncV1ATransferRequestProtocol.attach(
		String(process.env.YIELD_SYNC_V1_VAULT_TRANSFER_REQUEST_PROTOCOL)
	);

	await yieldSyncV1ATransferRequestProtocol.yieldSyncV1VaultAddress_yieldSyncV1VaultPropertyUpdate(
		owner.address,
		[1, 1, 10]
	);

	// Deploy a vault
	const yieldSyncV1Vault: Contract = await yieldSyncV1VaultFactory.deployYieldSyncV1Vault(
		ethers.constants.AddressZero,
		process.env.YIELD_SYNC_V1_VAULT_TRANSFER_REQUEST_PROTOCOL,
		[owner.address],
		[owner.address],
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
				address: await yieldSyncV1VaultFactory.yieldSyncV1VaultId_yieldSyncV1VaultAddress(
					await yieldSyncV1VaultFactory.yieldSyncV1VaultIdTracker() - 1
				),
				constructorArguments: [
					await yieldSyncV1VaultFactory.YieldSyncV1VaultAccessControl(),
					process.env.YIELD_SYNC_V1_VAULT_TRANSFER_REQUEST_PROTOCOL,
					ethers.constants.AddressZero,
					[owner.address],
					[owner.address],
				],
			}
		);

		console.log("Verification complete!");
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
