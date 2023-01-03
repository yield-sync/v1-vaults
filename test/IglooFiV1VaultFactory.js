const { expect } = require("chai");
const { ethers } = require("hardhat");


/* [variables] */
const iglooFiGovernanceAddress = ethers.utils.getAddress("0x96A4BC19E6947b8C4b3FbC47bAE0dCB32F0037c8")


describe("IglooFiV1VaultFactory", function () {
	it(
		"Should set IGLOO_FI to iglooFi",
		async function () {
			const IglooFiV1VaultFactory = await ethers.getContractFactory("IglooFiV1VaultFactory");
			const iglooFiV1VaultFactory = await IglooFiV1VaultFactory.deploy(iglooFiGovernanceAddress);
		
			const contract = await iglooFiV1VaultFactory.deployed();

			const IGLOO_FI = await contract.IGLOO_FI();

			expect(IGLOO_FI).to.equal(iglooFiGovernanceAddress);
		}
	);

	it(
		"Should set fee to 0 in constructor",
		async function () {
			const IglooFiV1VaultFactory = await ethers.getContractFactory("IglooFiV1VaultFactory");
			const iglooFiV1VaultFactory = await IglooFiV1VaultFactory.deploy(iglooFiGovernanceAddress);
		
			const contract = await iglooFiV1VaultFactory.deployed();

			const fee = await contract.fee();

			expect(fee).to.equal(0);
		}
	);
});
