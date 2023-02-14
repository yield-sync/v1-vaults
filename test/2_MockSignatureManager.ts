import { expect } from "chai";
import { Contract } from "ethers";

const { ethers } = require("hardhat");


describe("Mock Signature Manager", async () => {
	let mockSignatureManager: Contract;

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
		describe("Regular Hash", async () => {
			it("Check signature..", async () => {
				const [owner] = await ethers.getSigners();
			
				// [ethers] Get hash of string
				const hash = await ethers.utils.keccak256(ethers.utils.toUtf8Bytes("hello world"));
				
				// [hardhat] Sign hash
				const signature = await owner.signMessage(ethers.utils.arrayify(hash));

				// [contract]
				const ethHash = await mockSignatureManager.ECDSA_toEthSignedMessageHash(hash);

				// Correct signer recovered
				expect(
					await mockSignatureManager.ECDSA_recover(ethHash, signature)
				).to.equal(owner.address);

				// Correct signature and message
				expect(
					await mockSignatureManager.verifySignature(owner.address, "hello world", signature)
				).to.equal(true);
			});
		});


		describe("[ERC-191] ethSignedMessageHash", async () => {
			it("Check signature..", async () => {
				const [owner] = await ethers.getSigners();
			
				// [ethers] prefixed with \x19Ethereum Signed Message
				const hash = await ethers.utils.hashMessage("hello world");
				
				// [hardhat] Sign Message
				const signature = await owner.signMessage(ethers.utils.arrayify(hash));

				// [contract]
				const ethHash = await mockSignatureManager.ECDSA_toEthSignedMessageHash(hash);

				// Correct signer recovered
				expect(
					await mockSignatureManager.ECDSA_recover(hash, signature)
				).to.equal(owner.address);

				// Correct signature and message
				expect(
					await mockSignatureManager.verifySignature(owner.address, "hello world", signature)
				).to.equal(true);
			});
		})


		/**
		 * @notice Typed Data Hash
		*/
		describe("[EIP-712] typedDataHash", async () => {
			it("Check signature..", async () => {
				const [owner] = await ethers.getSigners();

				const typedDataHash = await mockSignatureManager.ECDSA_toTypedDataHash(
					await mockSignatureManager.getDomainSeperator(),
					await mockSignatureManager.getStructHash()
				);

				// [hardhat] Sign Message
				const signature = await owner.signMessage(ethers.utils.arrayify(typedDataHash));
				
				const signedHash = await mockSignatureManager.ECDSA_toEthSignedMessageHash(typedDataHash)

				console.log("signature:", signature)
				console.log("recovered:", await mockSignatureManager.ECDSA_recover(signedHash, signature));
				console.log("owner:", owner.address);
			});
		});
	});
});