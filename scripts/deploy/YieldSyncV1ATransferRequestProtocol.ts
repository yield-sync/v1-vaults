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
	const YieldSyncV1ATransferRequestProtocol: ContractFactory = await ethers.getContractFactory(
		"YieldSyncV1ATransferRequestProtocol"
	);

	switch (network.name)
	{
		case "mainnet":
			yieldSyncV1VaultRegistry = String(process.env.YIELD_SYNC_V1_VAULT_ACCESS_CONTROL_MAINNET);

			break;

		case "optimism":
			yieldSyncV1VaultRegistry = String(process.env.YIELD_SYNC_V1_VAULT_ACCESS_CONTROL_OP);

			break;

		case "optimismgoerli":
			yieldSyncV1VaultRegistry = String(process.env.YIELD_SYNC_V1_VAULT_ACCESS_CONTROL_OP_GOERLI);

			break;

		case "sepolia":
			yieldSyncV1VaultRegistry = String(process.env.YIELD_SYNC_V1_VAULT_ACCESS_CONTROL_SEPOLIA);

			break;

		default:
			console.error("Invalid or unsupported network.");
			return;
	}

	console.log("Deploying on Network:", network.name);
	console.log("Deployer Account:", deployer.address);
	console.log("Account Balance:", await deployer.getBalance());
	console.log("yieldSyncV1VaultRegistry:", yieldSyncV1VaultRegistry);

	console.log("Deploying YieldSyncV1ATransferRequestProtocol..");

	// YieldSyncV1ATransferRequestProtocol
	const yieldSyncV1ATransferRequestProtocol: Contract = await (
		await YieldSyncV1ATransferRequestProtocol.deploy(yieldSyncV1VaultRegistry)
	).deployed();

	console.log("Waiting 30 seconds before verifying..");

	// Delay
	await delay(30000);

	// verify
	try
	{
		// yieldSyncV1ATransferRequestProtocol
		await run(
			"verify:verify",
			{
				contract: "contracts/YieldSyncV1ATransferRequestProtocol.sol:YieldSyncV1ATransferRequestProtocol",
				address: yieldSyncV1ATransferRequestProtocol.address,
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

	console.log("yieldSyncV1ATransferRequestProtocol Address:", yieldSyncV1ATransferRequestProtocol.address);
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
