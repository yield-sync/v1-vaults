const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("IglooFiV1VaultFactory", function () {
	let testIglooFiGovernance;
	let iglooFiV1VaultFactory;

	// Log the network
	console.log("Testing on Network:", network.name);

	before('[before] Deploy the IglooFi Governance contract..', async () => {
		const TestIglooFiGovernance = await ethers.getContractFactory(
			"TestIglooFiGovernance"
		);

		const IglooFiV1VaultFactory = await ethers.getContractFactory(
			"IglooFiV1VaultFactory"
		);


		testIglooFiGovernance = await TestIglooFiGovernance.deploy();
		testIglooFiGovernance = await testIglooFiGovernance.deployed();

		iglooFiV1VaultFactory = await IglooFiV1VaultFactory.deploy(testIglooFiGovernance.address);
		iglooFiV1VaultFactory = await iglooFiV1VaultFactory.deployed();


		console.log(
			"Deployed TestIglooFiGovernance:", testIglooFiGovernance.address,
		);

		console.log(
			"Deployed IglooFiV1VaultFactory:", iglooFiV1VaultFactory.address
		);
	})

	it(
		"Should set `IGLOO_FI` to a deployed `TestIglooFiGovernance` address..",
		async function () {
			expect(await iglooFiV1VaultFactory.IGLOO_FI()).to.equal(
				testIglooFiGovernance.address
			);
		}
	);

	it(
		"Should set `fee` initially to 0..",
		async function () {
			expect(await iglooFiV1VaultFactory.fee()).to.equal(0);
		}
	);

	it(
		"Should update `fee` correctly..",
		async function () {
			await iglooFiV1VaultFactory.updateFee(1);

			expect(await iglooFiV1VaultFactory.fee()).to.equal(1);
		}
	);
});