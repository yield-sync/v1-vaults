import { expect } from "chai";
const { ethers } = require("hardhat");


describe("IglooFiV1Vault", async function () {
	let iglooFiV1Vault: any;


	/**
	 * @notice Deploy the contracts
	 * @dev Deploy TestIglooFiGovernance.sol
	 * @dev Deploy IglooFiV1VaultFactory.sol
	*/
	before("[before] Deploy..", async () => {
		const [owner] = await ethers.getSigners();

		const IglooFiV1Vault = await ethers.getContractFactory(
			"IglooFiV1Vault"
		);

		iglooFiV1Vault = await IglooFiV1Vault.deploy(
			owner.address,
			2,
			10
		);
		iglooFiV1Vault = await iglooFiV1Vault.deployed();
	});


	/**
	* @dev recieve
	*/
	describe("Contract", async function () {
		it(
			"Should be able to recieve ether..",
			async function () {
				const [, addr1] = await ethers.getSigners();
				
				// Send ether to IglooFiV1VaultFactory contract
				await addr1.sendTransaction({
					to: iglooFiV1Vault.address,
					value: ethers.utils.parseEther("1"),
				});

				await expect(
					await ethers.provider.getBalance(iglooFiV1Vault.address)
				).to.be.equal(ethers.utils.parseEther("1"));
			}
		);
	})


	/**
	* @dev Initial values set by constructor
	*/
	describe("Constructor Initialized values", async function () {
		it(
			"Should have admin set properly..",
			async function () {
				const [owner] = await ethers.getSigners();

				await iglooFiV1Vault.hasRole(
					await iglooFiV1Vault.DEFAULT_ADMIN_ROLE(),
					owner.address
				)
			}
		);

		it(
			"Should intialize requiredVoteCount as 2..",
			async function () {
				expect(await iglooFiV1Vault.requiredVoteCount()).to.equal(2);
			}
		);
	
		it(
			"Should initialize withdrawalDelaySeconds 10..",
			async function () {
				expect(await iglooFiV1Vault.withdrawalDelaySeconds()).to.equal(
					10
				);
			}
		);
	});
});