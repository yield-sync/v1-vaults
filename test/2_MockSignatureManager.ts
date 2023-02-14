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
		describe("ethSignedMessageHash", async () => {
			it("Check signature..", async () => {
				const [owner] = await ethers.getSigners();
			
				// [ethers] Get hash of string
				const hash = await ethers.utils.keccak256(ethers.utils.toUtf8Bytes("Hello World"));
				
				const ethHash = await mockSignatureManager.ECDSA_toEthSignedMessageHash(
					ethers.utils.toUtf8Bytes("Hello World")
				);
					
				// Make this..
				console.log(ethHash);
				// Equal this.. (use only ethers library here )
				console.log(await ethers.utils.hashMessage(
					ethers.utils.toUtf8Bytes("Hello World")
				));
				
				console.log(hash);
				
				// [ethers] Wallet Sign Message
				const signature = await owner.signMessage(ethers.utils.arrayify(hash));
				
				// Correct signer recovered
				expect(
					await mockSignatureManager.ECDSA_recover(ethHash, signature)
				).to.equal(owner.address);

				// Correct signature and message
				expect(
					await mockSignatureManager.verify(owner.address, "Hello World", signature)
				).to.equal(true);
			});
		});

		/**
		 * @notice Typed Data Hash
		*/
		describe("typedDataHash", async () => {
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

			it("domain separator returns properly", async () => {
				const [owner] = await ethers.getSigners();			
			});
		});
	});
});