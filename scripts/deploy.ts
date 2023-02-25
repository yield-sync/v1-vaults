import { Bytes, Contract, ContractFactory, Signature, TypedDataDomain, TypedDataField } from "ethers";
import { ethers } from "hardhat";


let mockIglooFiGovernance: Contract;
let iglooFiV1VaultFactory: Contract;
let iglooFiV1Vault: Contract;
let signatureManager: Contract;
let mockDapp: Contract;


async function main() {
	const [deployer] = await ethers.getSigners();

	console.log("Deploying contracts with the account:", deployer.address);
	console.log("Account Balance:", await deployer.getBalance());

	const MockIglooFiGovernance: ContractFactory = await ethers.getContractFactory("MockIglooFiGovernance");

	mockIglooFiGovernance = await (await MockIglooFiGovernance.deploy()).deployed();

	console.log("Contract address:", mockIglooFiGovernance.address);
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