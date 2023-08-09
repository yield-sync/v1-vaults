require("dotenv").config();


import { Contract, ContractFactory } from "ethers";
import { ethers, run, network } from "hardhat";


// Delay
const delay = (ms: number) => new Promise(res => setTimeout(res, ms));


async function main()
{
	const [owner] = await ethers.getSigners();

	// Factory
	const YieldSyncV1VaultAccessControl: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultAccessControl");
	const YieldSyncV1VaultFactory: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultFactory");
	const YieldSyncV1ATransferRequestProtocol: ContractFactory = await ethers.getContractFactory(
		"YieldSyncV1ATransferRequestProtocol"
	);
	const MockYieldSyncGovernance: ContractFactory = await ethers.getContractFactory("MockYieldSyncGovernance");

	let factoryContractAddress: string = "";
	let transferRequestProtocolAddress: string = "";

	switch (network.name)
	{
		case "mainnet":
			factoryContractAddress = String(process.env.YIELD_SYNC_V1_VAULT_FACTORY_ADDRESS_MAINNET);
			transferRequestProtocolAddress = String(process.env.YIELD_SYNC_V1_VAULT_TRANSFER_REQUEST_PROTOCOL_MAINNET);

			break;

		case "optimism":
			factoryContractAddress = String(process.env.YIELD_SYNC_V1_VAULT_FACTORY_ADDRESS_OP);
			transferRequestProtocolAddress = String(process.env.YIELD_SYNC_V1_VAULT_TRANSFER_REQUEST_PROTOCOL_OP);

			break;

		case "optimismgoerli":
			factoryContractAddress = String(process.env.YIELD_SYNC_V1_VAULT_FACTORY_ADDRESS_OP_GOERLI);
			transferRequestProtocolAddress = String(process.env.YIELD_SYNC_V1_VAULT_TRANSFER_REQUEST_PROTOCOL_OP_GOERLI);

			break;

		case "sepolia":
			factoryContractAddress = String(process.env.YIELD_SYNC_V1_VAULT_FACTORY_ADDRESS_SEPOLIA);
			transferRequestProtocolAddress = String(process.env.YIELD_SYNC_V1_VAULT_TRANSFER_REQUEST_PROTOCOL_SEPOLIA);

			break;

		default:
			console.log("WARNING: Governance contract not set");

			const mockYieldSyncGovernance: Contract = await (await MockYieldSyncGovernance.deploy()).deployed();

			const yieldSyncV1VaultAccessControl: Contract = await (
				await YieldSyncV1VaultAccessControl.deploy()
			).deployed();

			const yieldSyncV1VaultFactory: Contract = await (
				await YieldSyncV1VaultFactory.deploy(
					mockYieldSyncGovernance.address,
					yieldSyncV1VaultAccessControl.address
				)
			).deployed();

			factoryContractAddress = yieldSyncV1VaultFactory.address;

			break;
	}

	if (!factoryContractAddress)
	{
		console.error("No factoryContractAddress set.")
		return;
	}

	if (!transferRequestProtocolAddress)
	{
		console.error("No transferRequestProtocolAddress set.")
		return;
	}

	// [log]
	console.log("Deploying contract with Account:", owner.address);
	console.log("Account Balance:", await owner.getBalance());

	// Attach the deployed YieldSyncV1VaultFactory address
	const yieldSyncV1VaultFactory: Contract = await YieldSyncV1VaultFactory.attach(
		String(factoryContractAddress)
	);

	// Attach the deployed YieldSyncV1ATransferRequestProtocol address
	const yieldSyncV1ATransferRequestProtocol: Contract = await YieldSyncV1ATransferRequestProtocol.attach(
		transferRequestProtocolAddress
	);

	await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate(
		owner.address,
		[1, 1, 10] as UpdateVaultProperty
	);

	// Deploy a vault
	await yieldSyncV1VaultFactory.deployYieldSyncV1Vault(
		ethers.constants.AddressZero,
		transferRequestProtocolAddress,
		[owner.address],
		[owner.address],
		{ value: 0 }
	);

	console.log("Waiting 60 seconds before verifying..");

	// Delay
	await delay(60000);

	// verify
	try
	{
		// yieldSyncV1Vault
		await run(
			"verify:verify",
			{
				contract: "contracts/YieldSyncV1Vault.sol:YieldSyncV1Vault",
				address: await yieldSyncV1VaultFactory.yieldSyncV1VaultId_yieldSyncV1Vault(
					await yieldSyncV1VaultFactory.yieldSyncV1VaultIdTracker() - 1
				),
				constructorArguments: [
					owner.address,
					ethers.constants.AddressZero,
					transferRequestProtocolAddress,
					await yieldSyncV1VaultFactory.YieldSyncV1VaultAccessControl(),
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
