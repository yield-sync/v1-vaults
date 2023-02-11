import { expect } from "chai";
const { ethers } = require("hardhat");


describe("Mock Signature Manager", async () => {
	let mockSignatureManager: any;

	/**
	 * @notice Deploy contract
	 * @dev Deploy MockSignatureManager.sol
	*/
	before("[before] Deploy IglooFiGovernance.sol contract..", async () => {
		const MockSignatureManager = await ethers.getContractFactory("MockSignatureManager");

		mockSignatureManager = await MockSignatureManager.deploy();
		mockSignatureManager = await mockSignatureManager.deployed();
	});


	describe("MockSignatureManager.sol Contract", async () => {
		/**
		 * @notice Eth Signed Message Hash
		*/
		describe("ethSignedMessageHash", async () => {
			it("Check signature..", async () => {
				const [owner] = await ethers.getSigners();
			
				// [contract]
				const hash = await mockSignatureManager.getMessageHash("Hello, world!");

				const ethHash = await mockSignatureManager.ECDSA_toEthSignedMessageHash(hash);

				// [hardhat] Sign Message
				const signature = await owner.signMessage(ethers.utils.arrayify(hash));

				// Correct signer recovered
				expect(
					await mockSignatureManager.ECDSA_recover(ethHash, signature)
				).to.equal(owner.address);

				// Correct signature and message
				expect(
					await mockSignatureManager.verify(owner.address, "Hello, world!", signature)
				).to.equal(true);
			});
		});

		/**
		 * @notice Typed Data Hash
		*/
		describe("typedDataHash", async () => {
			it("Check signature..", async () => {
				const [owner] = await ethers.getSigners();
			});

			it("domain separator returns properly", async () => {
				const [owner] = await ethers.getSigners();			
			});
		});
	});
});