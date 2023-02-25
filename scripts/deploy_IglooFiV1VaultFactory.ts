import { Contract, ContractFactory } from "ethers";
import { ethers } from "hardhat";


let iglooFiV1VaultFactory: Contract;


async function main() {
	const [owner] = await ethers.getSigners();

	console.log("Deploying contract with Account:", owner.address);
	console.log("Account Balance:", await owner.getBalance());

	const IglooFiV1VaultFactory: ContractFactory = await ethers.getContractFactory("IglooFiV1VaultFactory");
	iglooFiV1VaultFactory = await (await IglooFiV1VaultFactory.deploy("")).deployed();

	console.log("Contract address:", iglooFiV1VaultFactory.address);
	console.log("Account Balance:", await owner.getBalance());
}


main()
	.then(() => {
		console.log();
		
		process.exit(0);
	})
	.catch((error) => {
		console.error(error);
		process.exit(1);
	})
;