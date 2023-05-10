require("dotenv").config();
import { Contract, ContractFactory } from "ethers";
import { ethers, run } from "hardhat";


async function main() {
	const [owner] = await ethers.getSigners();

	console.log("Deploying contract with Account:", owner.address);
	console.log("Account Balance:", await owner.getBalance());

	// Get factories
	const MockERC20: ContractFactory = await ethers.getContractFactory("MockERC20");
	const MockERC721: ContractFactory = await ethers.getContractFactory("MockERC721");

	// deploy
	const mockERC20: Contract = await (await MockERC20.deploy()).deployed();
	const mockERC721: Contract = await (await MockERC721.deploy()).deployed();

	console.log("Waiting 30 seconds before verifying..");

	// Delay
	const delay = (ms: number) => new Promise(res => setTimeout(res, ms));

	// Delay
	await delay(30000);

	// verify
	try
	{
		// MockERC20
		await run(
			"verify:verify",
			{
				address: mockERC20.address,
				constructorArguments: [],
				contract: "contracts/test-contracts/MockERC20.sol:MockERC20"
			}
		);

		// MockERC721
		await run(
			"verify:verify",
			{
				address: mockERC721.address,
				constructorArguments: [],
				contract: "contracts/test-contracts/MockERC721.sol:MockERC721"
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

	console.log("mockERC20 Contract address:", mockERC20.address);
	console.log("MockERC721 Contract address:", mockERC721.address);
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
