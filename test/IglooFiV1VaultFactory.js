const { expect } = require("chai");
const { ethers } = require("hardhat");


/* [variables] */
const iglooFiGovernanceAddress = ethers.utils.getAddress("0x0000000000000000000000000000000000000000");


describe("IglooFiV1VaultFactory", function () {
	before('', async () => {
		// Log the network
		console.log("Testing on Network:", network.name);
	})
	

	it(
		"Should set IGLOO_FI to iglooFi",
		async function () {
			const IglooFiV1VaultFactory = await ethers.getContractFactory("IglooFiV1VaultFactory");
			const iglooFiV1VaultFactory = await IglooFiV1VaultFactory.deploy(iglooFiGovernanceAddress);
			const contract = await iglooFiV1VaultFactory.deployed();

			expect(await contract.IGLOO_FI()).to.equal(iglooFiGovernanceAddress);
		}
	);

	it(
		"Should set fee to 0 in constructor",
		async function () {
			const IglooFiV1VaultFactory = await ethers.getContractFactory("IglooFiV1VaultFactory");
			const iglooFiV1VaultFactory = await IglooFiV1VaultFactory.deploy(iglooFiGovernanceAddress);
			const contract = await iglooFiV1VaultFactory.deployed();

			expect(await contract.fee()).to.equal(0);
		}
	);

	it(
		"Should update fee correctly",
		async function () {
			const IglooFiV1VaultFactory = await ethers.getContractFactory("IglooFiV1VaultFactory");
			const iglooFiV1VaultFactory = await IglooFiV1VaultFactory.deploy(iglooFiGovernanceAddress);
			const contract = await iglooFiV1VaultFactory.deployed();

			expect(await contract.fee()).to.equal(1);
		}
	);
});