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
	const YieldSyncV1ASignatureProtocol: ContractFactory = await ethers.getContractFactory("YieldSyncV1ASignatureProtocol");
	const YieldSyncV1ATransferRequestProtocol: ContractFactory = await ethers.getContractFactory("YieldSyncV1ATransferRequestProtocol");

	/// DEPLOY
	// YieldSyncV1VaultAccessControl
	const yieldSyncV1VaultAccessControl: Contract = await (await YieldSyncV1VaultAccessControl.deploy()).deployed();


	// YieldSyncV1VaultFactory
	const yieldSyncV1VaultFactory: Contract = await (
		await YieldSyncV1VaultFactory.deploy(
			process.env.YIELD_SYNC_GOVERNANCE_ADDRESS,
			yieldSyncV1VaultAccessControl.address
		)
	).deployed();

	// YieldSyncV1ATransferRequestProtocol
	const yieldSyncV1ATransferRequestProtocol = await (
		await YieldSyncV1ATransferRequestProtocol.deploy(
			yieldSyncV1VaultAccessControl.address
		)
	).deployed();

	if (false)
	{
		// YieldSyncV1ASignatureProtocol
		const signatureProtocol = await (
			await YieldSyncV1ASignatureProtocol.deploy(
				process.env.YIELD_SYNC_GOVERNANCE_ADDRESS,
				yieldSyncV1VaultAccessControl.address
			)
		).deployed();
	}

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

		// yieldSyncV1ATransferRequestProtocol
		await run(
			"verify:verify",
			{
				address: yieldSyncV1ATransferRequestProtocol.address,
				constructorArguments: [
					yieldSyncV1VaultAccessControl.address
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
			console.log(e);
		}
	}

	console.log("yieldSyncV1VaultAccessControl address:", yieldSyncV1VaultAccessControl.address);
	console.log("yieldSyncV1VaultFactory address:", yieldSyncV1VaultFactory.address);
	console.log("yieldSyncV1ATransferRequestProtocol address:", yieldSyncV1ATransferRequestProtocol.address);
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
