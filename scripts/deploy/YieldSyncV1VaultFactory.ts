require("dotenv").config();


import { Contract, ContractFactory } from "ethers";
import { ethers, run, network } from "hardhat";


// [const]
const delay = (ms: number) => new Promise(res => setTimeout(res, ms));


async function main()
{
	const [deployer] = await ethers.getSigners();

	let governanceContractAddress: string = "";

	// Get factories
	const MockYieldSyncGovernance: ContractFactory = await ethers.getContractFactory("MockYieldSyncGovernance");
	const YieldSyncV1VaultFactory: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultFactory");
	const YieldSyncV1VaultAccessControl: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultAccessControl");

	switch (network.name)
	{
		case "mainnet":
			governanceContractAddress = String(process.env.YIELD_SYNC_GOVERNANCE_ADDRESS_MAINNET);

			break;

		case "optimism":
			governanceContractAddress = String(process.env.YIELD_SYNC_GOVERNANCE_ADDRESS_OP);

			break;

		case "optimismgoerli":
			governanceContractAddress = String(process.env.YIELD_SYNC_GOVERNANCE_ADDRESS_OP_GOERLI);

			break;

		case "sepolia":
			governanceContractAddress = String(process.env.YIELD_SYNC_GOVERNANCE_ADDRESS_SEPOLIA);

			break;

		default:
			console.log("WARNING: Governance contract not set");

			const mockYieldSyncGovernance: Contract = await (await MockYieldSyncGovernance.deploy()).deployed();

			governanceContractAddress = mockYieldSyncGovernance.address;

			break;
	}

	console.log("Deploying on Network:", network.name);
	console.log("Deployer Account:", deployer.address);
	console.log("Account Balance:", await deployer.getBalance());
	console.log("governanceContractAddress:", governanceContractAddress);

	/// DEPLOY
	console.log("Deploying YieldSyncV1VaultAccessControl..");

	// YieldSyncV1VaultAccessControl
	const yieldSyncV1VaultAccessControl: Contract = await (await YieldSyncV1VaultAccessControl.deploy()).deployed();


	console.log("Deploying YieldSyncV1VaultFactory..");

	// YieldSyncV1VaultFactory
	const yieldSyncV1VaultFactory: Contract = await (
		await YieldSyncV1VaultFactory.deploy(governanceContractAddress, yieldSyncV1VaultAccessControl.address)
	).deployed();

	console.log("Waiting 30 seconds before verifying..");

	// Delay
	await delay(30000);

	// verify
	try
	{
		// yieldSyncV1VaultAccessControl
		await run(
			"verify:verify",
			{
				contract: "contracts/YieldSyncV1VaultAccessControl.sol:YieldSyncV1VaultAccessControl",
				address: yieldSyncV1VaultAccessControl.address,
				constructorArguments: [],
			}
		);

		// yieldSyncV1VaultFactory
		await run(
			"verify:verify",
			{
				contract: "contracts/YieldSyncV1VaultFactory.sol:YieldSyncV1VaultFactory",
				address: yieldSyncV1VaultFactory.address,
				constructorArguments: [
					governanceContractAddress,
					yieldSyncV1VaultAccessControl.address,
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
