const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");


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
	* @dev transferFunds
	*/
	it(
		"Should be able to recieve ether..",
		async function () {
			const [, addr1] = await ethers.getSigners();
			
			// Send ether to IglooFiV1VaultFactory contract
			await addr1.sendTransaction({
				to: iglooFiV1VaultFactory.address,
				value: ethers.utils.parseEther("1.0"),
			});

			await expect(
				await ethers.provider.getBalance(iglooFiV1VaultFactory.address)
			).to.be.equal(ethers.utils.parseEther("1.0"));
		}
	);


	/**
	* @dev pause
	*/
	it(
		"Should set pause when the owner calls it..",
		async function () {
			await iglooFiV1VaultFactory.setPause(false);
			
			expect(await iglooFiV1VaultFactory.paused()).to.be.equal(false);

			await iglooFiV1VaultFactory.setPause(true);
			
			expect(await iglooFiV1VaultFactory.paused()).to.be.equal(true);
		}
	);

	it(
		"Should revert `setPause` when unauthorized msg.sender calls..",
		async function () {
			const [, addr1] = await ethers.getSigners();

			await expect(iglooFiV1VaultFactory.connect(addr1).setPause(false))
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
			await iglooFiV1VaultFactory.updateFee(1);

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


	/**
	* @dev transferFunds
	*/
	it(
		"Should be able to transfer to an address..",
		async function () {
			const [, addr1] = await ethers.getSigners();
			
			await iglooFiV1VaultFactory.setPause(false);

			const balanceBefore = {
				addr1: parseFloat(ethers.utils.formatUnits(
					(await ethers.provider.getBalance(addr1.address)),
					"ether"
				)),
				iglooFiV1VaultFactory: parseFloat(ethers.utils.formatUnits(
					(await ethers.provider.getBalance(iglooFiV1VaultFactory.address)),
					"ether"
				))
			}

			await iglooFiV1VaultFactory.transferFunds(addr1.address);

			const balanceAfter = {
				addr1: parseFloat(ethers.utils.formatUnits(
					(await ethers.provider.getBalance(addr1.address)),
					"ether"
				)),
				iglooFiV1VaultFactory: parseFloat(ethers.utils.formatUnits(
					(await ethers.provider.getBalance(iglooFiV1VaultFactory.address)),
					"ether"
				))
			}

			await expect(parseFloat(balanceAfter.addr1)).to.be.equal(
				balanceBefore.addr1 + balanceBefore.iglooFiV1VaultFactory
			);
		}
	);

	it(
		"Should revert `transferFunds` when unauthorized msg.sender calls..",
		async function () {
			const [, addr1] = await ethers.getSigners();

			await expect(
				iglooFiV1VaultFactory.connect(addr1).transferFunds(addr1.address)
			).to.be.revertedWith("!auth");
		}
	);
});