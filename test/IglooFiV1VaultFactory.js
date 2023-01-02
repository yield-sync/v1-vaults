const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("IglooFiV1VaultFactory", function () {
	it(
		"Should..",
		async function () {
			const IglooFiV1VaultFactory = await ethers.getContractFactory(
				"IglooFiV1VaultFactory"
			);

			const r_IglooFiV1VaultFactory = await IglooFiV1VaultFactory.deploy("");
		
			await r_IglooFiV1VaultFactory.deployed()
		}
	);
});
