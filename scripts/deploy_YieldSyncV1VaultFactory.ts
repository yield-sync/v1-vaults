require("dotenv").config();
import { Contract, ContractFactory } from "ethers";
import { ethers, run } from "hardhat";


async function main() {
	const [owner] = await ethers.getSigners();

	console.log("Deploying contract with Account:", owner.address);
	console.log("Account Balance:", await owner.getBalance());

	// Get factories
	const YieldSyncV1VaultFactory: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultFactory");
	const YieldSyncV1VaultAccessControl: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultAccessControl");
	const YieldSyncV1SignatureProtocol: ContractFactory = await ethers.getContractFactory("YieldSyncV1SignatureProtocol");
	const YieldSyncV1TransferRequestProtocol: ContractFactory = await ethers.getContractFactory("YieldSyncV1TransferRequestProtocol");


	// deploy
	const yieldSyncV1VaultAccessControl: Contract = await (await YieldSyncV1VaultAccessControl.deploy()).deployed();
	const yieldSyncV1VaultFactory: Contract = await (
		await YieldSyncV1VaultFactory.deploy(
			process.env.YIELD_SYNC_GOVERNANCE_ADDRESS,
			yieldSyncV1VaultAccessControl.address
		)
	).deployed();

	// Deploy Transfer Request Protocol
	const yieldSyncV1TransferRequestProtocol = await (
		await YieldSyncV1TransferRequestProtocol.deploy(
			yieldSyncV1VaultAccessControl.address,
			yieldSyncV1VaultFactory.address
		)
	).deployed();

	if (false)
	{
		// Deploy Signature Protocol
		const signatureProtocol = await (
			await YieldSyncV1SignatureProtocol.deploy(
				process.env.YIELD_SYNC_GOVERNANCE_ADDRESS,
				yieldSyncV1VaultAccessControl.address
			)
		).deployed();
	}

	// Set Factory -> Transfer Request Protocol
	await yieldSyncV1VaultFactory.updateTransferRequestProtocol(yieldSyncV1TransferRequestProtocol.address);

	console.log("Waiting 30 seconds before verifying..");

	// Delay
	const delay = (ms: number) => new Promise(res => setTimeout(res, ms));

	// Delay
	await delay(30000);

	// verify
	try
	{
		// yieldSyncV1VaultAccessControl
		await run(
			"verify:verify",
			{
				address: yieldSyncV1VaultAccessControl.address,
				constructorArguments: [],
			}
		);

		// yieldSyncV1VaultFactory
		await run(
			"verify:verify",
			{
				address: yieldSyncV1VaultFactory.address,
				constructorArguments: [
					process.env.YIELD_SYNC_GOVERNANCE_ADDRESS,
					yieldSyncV1VaultAccessControl.address,
				],
			}
		);

		// yieldSyncV1TransferRequestProtocol
		await run(
			"verify:verify",
			{
				address: yieldSyncV1TransferRequestProtocol.address,
				constructorArguments: [
					yieldSyncV1VaultAccessControl.address,
					yieldSyncV1VaultFactory.address
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
			console.log(e);
		}
	}

	console.log("yieldSyncV1VaultAccessControl Contract address:", yieldSyncV1VaultAccessControl.address);
	console.log("yieldSyncV1VaultFactory Contract address:", yieldSyncV1VaultFactory.address);
	console.log("Account Balance:", await owner.getBalance());
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
