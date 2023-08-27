require("dotenv").config();


import { Contract, ContractFactory } from "ethers";
import { ethers, run, network } from "hardhat";


// [const]
const delay = (ms: number) => new Promise(res => setTimeout(res, ms));


async function main()
{
	const [deployer] = await ethers.getSigners();

	let yieldSyncV1VaultRegistry: string = "";

	// Get factories
	const YieldSyncV1BTransferRequestProtocol: ContractFactory = await ethers.getContractFactory(
		"YieldSyncV1BTransferRequestProtocol"
	);

	switch (network.name)
	{
		case "mainnet":
			yieldSyncV1VaultRegistry = String(process.env.YIELD_SYNC_V1_VAULT_REGISTRY_MAINNET);

			break;

		case "optimism":
			yieldSyncV1VaultRegistry = String(process.env.YIELD_SYNC_V1_VAULT_REGISTRY_OP);

			break;

		case "optimismgoerli":
			yieldSyncV1VaultRegistry = String(process.env.YIELD_SYNC_V1_VAULT_REGISTRY_OP_GOERLI);

			break;

		case "sepolia":
			yieldSyncV1VaultRegistry = String(process.env.YIELD_SYNC_V1_VAULT_REGISTRY_SEPOLIA);

			break;

		default:
			console.error("Invalid or unsupported network.");
			return;
	}

	console.log("Deploying on Network:", network.name);
	console.log("Deployer Account:", deployer.address);
	console.log("Account Balance:", await deployer.getBalance());
	console.log("yieldSyncV1VaultRegistry:", yieldSyncV1VaultRegistry);

	console.log("Deploying YieldSyncV1BTransferRequestProtocol..");

	// YieldSyncV1BTransferRequestProtocol
	const yieldSyncV1BTransferRequestProtocol: Contract = await (
		await YieldSyncV1BTransferRequestProtocol.deploy(yieldSyncV1VaultRegistry)
	).deployed();

	console.log("Waiting 30 seconds before verifying..");

	// Delay
	await delay(30000);

	// verify
	try
	{
		// yieldSyncV1BTransferRequestProtocol
		await run(
			"verify:verify",
			{
				contract: "contracts/YieldSyncV1BTransferRequestProtocol.sol:YieldSyncV1BTransferRequestProtocol",
				address: yieldSyncV1BTransferRequestProtocol.address,
				constructorArguments: [
					yieldSyncV1VaultRegistry
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

	console.log("yieldSyncV1BTransferRequestProtocol Address:", yieldSyncV1BTransferRequestProtocol.address);
	console.log("Account Balance:", await deployer.getBalance());
}


main().then(
	() =>
	{
		process.exit(0);
	}
).catch(
	(error) =>
	{
		console.error(error);
		process.exit(1);
	}
);
