import { expect } from "chai";
const { ethers } = require("hardhat");


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

				
				const domainSeparator = contract.getMessageHash("EIP-712");
				const hash = await contract.getMessageHash("Hello, world!");
				
				const typedDataHash = await contract.ECDSA_toTypedDataHash(domainSeparator, hash);
				
				const signature = await owner.signMessage(ethers.utils.arrayify(typedDataHash));

				
				// Correct signer recovered
				expect(
					await contract.ECDSA_recover(typedDataHash, signature)
				).to.equal(owner.address);

			});

			it("domain separator returns properly", async () => {
				// Get contract
				const VerifySignature = await ethers.getContractFactory("VerifySignature");

				// Deploy contract
				const contract = await VerifySignature.deploy();
				await contract.deployed();
				
				
				const chainId = 1; //the `chainId` of the chain the contract is deployed on_
				const _name = 1; //the `name()` of the ERC20 contract_;
				const version = 1; //the version as specified in ERC712 (string, generally of a number)_;
				const verifyingContract = 1; //address of the contract the function is in_;

				expect(await contract.DOMAIN_SEPARATOR())
					.to.equal(await ethers.utils._TypedDataEncoder.hashDomain({
					name: _name,
					version,
					chainId,
					verifyingContract
				}));
			});
		});
	});
});