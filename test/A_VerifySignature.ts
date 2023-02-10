import { expect } from "chai";
const { ethers } = require("hardhat");


const sevenDaysInSeconds = 7 * 24 * 60 * 60;
const sixDaysInSeconds = 6 * 24 * 60 * 60;


describe("Verify Signature", async () => {
	describe("VerifySignature.sol Contract", () => {
		describe("ethSignedMessageHash", () => {
			it("Check signature..", async () => {
				const [owner] = await ethers.getSigners();
			
				// Get contract
				const VerifySignature = await ethers.getContractFactory("VerifySignature");

				// Deploy contract
				const contract = await VerifySignature.deploy();
				await contract.deployed();

				// [contract]
				const hash = await contract.getMessageHash("Hello, world!");

				const ethHash = await contract.ECDSA_toEthSignedMessageHash(hash);

				// [hardhat] Sign Message
				const signature = await owner.signMessage(ethers.utils.arrayify(hash));

				// Correct signer recovered
				expect(
					await contract.ECDSA_recover(ethHash, signature)
				).to.equal(owner.address);

				// Correct signature and message
				expect(
					await contract.verify(owner.address, "Hello, world!", signature)
				).to.equal(true);
			});
		});


		describe("typedDataHash", () => {
			it("Check signature..", async () => {
				const [owner] = await ethers.getSigners();
			
				// Get contract
				const VerifySignature = await ethers.getContractFactory("VerifySignature");

				// Deploy contract
				const contract = await VerifySignature.deploy();
				await contract.deployed();

				
				const domainSeparator = ethers.utils.id("EIP-712");
				const hash = await contract.getMessageHash("Hello, world!");
				
				const typedDataHash = await contract.ECDSA_toTypedDataHash(domainSeparator, hash);
				
				const signature = await owner.signMessage(ethers.utils.arrayify(typedDataHash));

				
				// Correct signer recovered
				expect(
					await contract.ECDSA_recover(typedDataHash, signature)
				).to.equal(owner.address);
			});
		});
	});
});