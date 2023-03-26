import { Contract, ContractFactory } from "ethers";
import { ethers } from "hardhat";


let yieldSyncV1VaultFactory: Contract;


async function main() {
	const [owner] = await ethers.getSigners();

	console.log("Deploying contract with Account:", owner.address);
	console.log("Account Balance:", await owner.getBalance());

	const YieldSyncV1VaultFactory: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultFactory");
	yieldSyncV1VaultFactory = await (await YieldSyncV1VaultFactory.deploy("")).deployed();

	console.log("Contract address:", yieldSyncV1VaultFactory.address);
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
