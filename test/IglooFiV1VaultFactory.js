const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("IglooFiV1VaultFactory", async function () {
	// Log the network
	console.log("Testing on Network:", network.name);

	let testIglooFiGovernance;
	let iglooFiV1VaultFactory;

	/**
	 * @notice Deploy the contracts
	 * @dev Deploy TestIglooFiGovernance.sol
	 * @dev Deploy IglooFiV1VaultFactory.sol
	*/
	before("[before] Deploy the IglooFi Governance contract..", async () => {
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


	/**
	 * @notice Check if initial values are correct
	*/
	it(
		"Should be intialized as paused..",
		async function () {
			expect(await iglooFiV1VaultFactory.paused()).to.equal(true);
		}
	);

	it(
		"Should initialize `IGLOO_FI` to deployed `TestIglooFiGovernance` address..",
		async function () {
			expect(await iglooFiV1VaultFactory.IGLOO_FI()).to.equal(
				testIglooFiGovernance.address
			);
		}
	);

	it(
		"Should initialize the `fee` to 0..",
		async function () {
			expect(await iglooFiV1VaultFactory.fee()).to.equal(0);
		}
	);


	/**
	* @dev pause
	*/
	it(
		"Should toggle pause when the owner calls it..",
		async function () {
			await iglooFiV1VaultFactory.togglePause();
			
			expect(await iglooFiV1VaultFactory.paused()).to.be.equal(false);

			await iglooFiV1VaultFactory.togglePause();

			expect(await iglooFiV1VaultFactory.paused()).to.be.equal(true);
		}
	);

	it(
		"Should revert `togglePause` when unauthorized msg.sender calls..",
		async function () {
			const [, addr1] = await ethers.getSigners();

			await expect(iglooFiV1VaultFactory.connect(addr1).togglePause())
				.to.be.revertedWith("!auth")
			;
		}
	);


	/**
	* @dev updateFee
	*/
	it(
		"Should update `fee` correctly..",
		async function () {
			const [owner] = await ethers.getSigners();
			
			await iglooFiV1VaultFactory.connect(owner).updateFee(1);

			expect(await iglooFiV1VaultFactory.fee()).to.equal(1);
		}
	);

	it(
		"Should revert `updateFee` when unauthorized msg.sender calls..",
		async function () {
			const [, addr1] = await ethers.getSigners();

			await expect(iglooFiV1VaultFactory.connect(addr1).updateFee(1))
				.to.be.revertedWith("!auth")
			;
		}
	);
});