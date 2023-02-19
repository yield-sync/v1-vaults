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
				let sig = ethers.utils.splitSignature(signature);
				
				// Correct signer recovered
				expect(
					await mockSignatureManager.verifyStringSignature("hello world", sig.v, sig.r, sig.s)
				).to.equal(owner.address);
			});
		});

		
		/**
		 * @notice [hardhat][ERC-191] Signing a Digest Hash
		 */
		describe("[hardhat][ERC-191] Signing a Digest Hash", async () => {
			it("Check signature..", async () => {
				const [owner] = await ethers.getSigners();

				let messageHash = ethers.utils.id("Hello World");

				// Note: messageHash is a string, that is 66-bytes long, to sign the
				//       binary value, we must convert it to the 32 byte Array that
				//       the string represents
				//
				// i.e.
				//   // 66-byte string
				//   "0x592fa743889fc7f92ac2a37bb1f5ba1daf2a5c84741ca0e0061d243a2e6707ba"
				//
				//   ... vs ...
				//
				//  // 32 entry Uint8Array
				//  [ 89, 47, 167, 67, 136, 159, 199, 249, 42, 194, 163,
				//    123, 177, 245, 186, 29, 175, 42, 92, 132, 116, 28,
				//    160, 224, 6, 29, 36, 58, 46, 103, 7, 186]

				let messageHashBytes = ethers.utils.arrayify(messageHash)

				// Sign the binary data
				let flatSig = await owner.signMessage(messageHashBytes);

				// For Solidity, we need the expanded-format of a signature
				let sig = ethers.utils.splitSignature(flatSig);

				// Correct signer recovered
				expect(await mockSignatureManager.verifyHashSignature(messageHash, sig.v, sig.r, sig.s))
					.to.equal(owner.address)
				;
			});
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
				}

				// [ethers] Get hash
				const hash = ethers.utils._TypedDataEncoder.hash(msg.domain, msg.types, msg.value)
				
				// [hardhat] Sign Message
				const signature = await owner.signMessage(ethers.utils.arrayify(hash));
				
				// For Solidity, we need the expanded-format of a signature
				const sig = ethers.utils.splitSignature(signature)

				// Correct signer recovered
				expect(await mockSignatureManager.verifyHashSignature(hash, sig.v, sig.r, sig.s))
					.to.equal(owner.address)
				;
			});
		});
	});
});