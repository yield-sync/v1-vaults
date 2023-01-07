const hre = require('hardhat');


async function main() {
	const [deployer] = await hre.ethers.getSigners();

	console.log(`Deploying contracts with the account: ${deployer.address}`);
	console.log(`Account Balance: ${await deployer.getBalance()}`);

	const IglooFiGovernance = await hre.ethers.getContractFactory('IglooFiV1VaultFactory');
	const iglooFiGovernance = await IglooFiGovernance.deploy(
		hre.ethers.utils.getAddress("0x20550e54e4cb1b6e92d72a47adba7d1d59646d86")
	);

	console.log(`Contract address: ${iglooFiGovernance.address}`);
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