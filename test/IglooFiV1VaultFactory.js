const { expect } = require("chai");
const { ethers } = require("hardhat");
const { useWallet } = require("@nomiclabs/hardhat-ethers");


describe("IglooFiV1VaultFactory", async function () {
	let testIglooFiGovernance;
	let iglooFiV1VaultFactory;

	// Log the network
	console.log("Testing on Network:", network.name);

	before('[before] Deploy the IglooFi Governance contract..', async () => {
		const TestIglooFiGovernance = await ethers.getContractFactory(
			"TestIglooFiGovernance"
		);

		testIglooFiGovernance = await TestIglooFiGovernance.deploy();
		testIglooFiGovernance = await testIglooFiGovernance.deployed();

		const IglooFiV1VaultFactory = await ethers.getContractFactory(
			"IglooFiV1VaultFactory"
		);

		iglooFiV1VaultFactory = await IglooFiV1VaultFactory.deploy(
			testIglooFiGovernance.address
		);
		iglooFiV1VaultFactory = await iglooFiV1VaultFactory.deployed();
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
			const [owner] = await ethers.getSigners();
			
			await iglooFiV1VaultFactory.connect(owner).updateFee(1);

			expect(await iglooFiV1VaultFactory.fee()).to.equal(1);
		}
	);

	it(
		"Should revert `updateFee` when unauthorized caller calls..",
		async function () {
			const [, addr1] = await ethers.getSigners();

			await expect(iglooFiV1VaultFactory.connect(addr1).updateFee(1)).to.be
				.revertedWith("!auth")
			;
		}
	);
});