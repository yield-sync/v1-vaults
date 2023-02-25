import { Contract, ContractFactory } from "ethers";
import { ethers } from "hardhat";


let mockIglooFiGovernance: Contract;
let iglooFiV1VaultFactory: Contract;
let iglooFiV1Vault: Contract;
let signatureManager: Contract;
let mockDapp: Contract;


async function main() {
	const [owner] = await ethers.getSigners();

	console.log("Deploying contracts with the account:", owner.address);
	console.log("Account Balance:", await owner.getBalance());

	const MockIglooFiGovernance: ContractFactory = await ethers.getContractFactory("MockIglooFiGovernance");
	const IglooFiV1VaultFactory: ContractFactory = await ethers.getContractFactory("IglooFiV1VaultFactory");

	mockIglooFiGovernance = await (await MockIglooFiGovernance.deploy()).deployed();
	iglooFiV1VaultFactory = await (await IglooFiV1VaultFactory.deploy(mockIglooFiGovernance.address)).deployed();

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