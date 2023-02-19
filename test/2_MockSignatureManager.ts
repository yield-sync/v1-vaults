import { expect } from "chai";
import { Contract } from "ethers";

const { ethers } = require("hardhat");


const chainId = 31337;


describe("Mock Signature Manager", async () => {
	let mockSignatureManager: Contract;
	let mockDapp: Contract;

	/**
	 * @notice Deploy contract
	 * @dev Deploy MockSignatureManager.sol
	*/
	before("[before] Deploy MockSignatureManager.sol contract..", async () => {
		const MockSignatureManager = await ethers.getContractFactory("MockSignatureManager");

		mockSignatureManager = await MockSignatureManager.deploy();
		mockSignatureManager = await mockSignatureManager.deployed();
	});


	/**
	 * @notice Deploy contract
	 * @dev Deploy MockDapp.sol
	*/
	before("[before] Deploy MockDapp.sol contract..", async () => {
		const MockDapp = await ethers.getContractFactory("MockDapp");

		mockDapp = await MockDapp.deploy();
		mockDapp = await mockDapp.deployed();
	});


	describe("MockSignatureManager.sol Contract", async () => {
		/**
		 * @notice [hardhat][string] Signing a String Message
		 */
		describe("[hardhat][string] Signing a String Message", async () => {
			it("Check signature..", async () => {
				const [owner] = await ethers.getSigners();
			
				// [hardhat] Sign hash
				const signature = await owner.signMessage("hello world");

				// [ethers] Split signature
				const splitSignature = ethers.utils.splitSignature(signature);				
				
				// Correct signer recovered
				expect(
					await mockSignatureManager.verifyStringSignature(
						"hello world",
						splitSignature.v,
						splitSignature.r,
						splitSignature.s
					)
				).to.equal(owner.address);
			});
		});

		
		/**
		 * @notice [hardhat][ERC-191] Signing a Digest Hash
		 */
		describe("[hardhat][ERC-191] Signing a Digest Hash", async () => {
			it("Check signature..", async () => {
				const [owner] = await ethers.getSigners();

				const messageHash = ethers.utils.id("Hello World");

				const messageHashBytes = ethers.utils.arrayify(messageHash)

				// Sign the binary data
				const signature = await owner.signMessage(messageHashBytes);

				// For Solidity, we need the expanded-format of a signature
				const splitSignature = ethers.utils.splitSignature(signature);

				// Correct signer recovered
				expect(
					await mockSignatureManager.verifyHashSignature(
						messageHash,
						splitSignature.v,
						splitSignature.r,
						splitSignature.s
					)
				).to.equal(owner.address);
			});


			it("Should pass `isValidSignature()`", async () => {
				const [owner] = await ethers.getSigners();

				const messageHash = ethers.utils.id("Hello World");

				const messageHashBytes = ethers.utils.arrayify(messageHash);

				// Sign the binary data
				const signature = await owner.signMessage(messageHashBytes);

				
				await mockSignatureManager.isValidSignature(
					messageHash,
					signature
				)

				expect(true).to.be.equal(true);
			})
		});


		/**
		 * @notice [hardhat][EIP-712] Signing typedDataHash
		*/
		describe("[hardhat][EIP-712] Signing typedDataHash", async () => {
			it("Check signature..", async () => {
				const [owner] = await ethers.getSigners();

				const msg = {
					domain: {
						name: 'MockDapp',
						version: '1',
						chainId: chainId,
						verifyingContract: mockDapp.address
					},
					types: {
						Point: [
							{ name: 'a', type: 'address' },
							{ name: 'x', type: 'uint' }
						]
					},
					value: {
						a: ethers.constants.AddressZero,
						x: 1
					},
				};
				
				/**
				 * @dev To get the payload use the line below:
				 *     ethers.utils._TypedDataEncoder.getPayload(msg.domain, msg.types, msg.value);
				*/
				
				// [ethers] Get hash
				const messageHash = ethers.utils._TypedDataEncoder.hash(msg.domain, msg.types, msg.value)

				// [hardhat] Sign Message
				const signature = await owner.signMessage(ethers.utils.arrayify(messageHash));
				
				// For Solidity, we need the expanded-format of a signature
				const splitSignature = ethers.utils.splitSignature(signature);

				// Correct signer recovered
				expect(
					await mockSignatureManager.verifyHashSignature(
						messageHash,
						splitSignature.v,
						splitSignature.r,
						splitSignature.s
					)
				).to.equal(owner.address);
			});
		});
	});
});