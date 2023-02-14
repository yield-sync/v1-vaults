import { expect } from "chai";
import { Contract } from "ethers";

const { ethers } = require("hardhat");


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
		 * @notice Eth Signed Message Hash
		*/
		describe("[ERC-191] Signed Hash", async () => {
			it("Check signature..", async () => {
				const [owner] = await ethers.getSigners();
			
				// [ethers] Get hash
				const hash = await ethers.utils.keccak256(ethers.utils.toUtf8Bytes("hello world"));
				
				// [hardhat] Sign hash
				const signature = await owner.signMessage(ethers.utils.arrayify(hash));

				// [contract] takes: {bytes32} - prefixes with \x19Ethereum Signed Message
				const ethSignedHash = await mockSignatureManager.ECDSA_toEthSignedMessageHash(hash);

				// Correct signer recovered
				expect(
					await mockSignatureManager.ECDSA_recover(ethSignedHash, signature)
				).to.equal(owner.address);

				// Correct signature and message
				expect(
					await mockSignatureManager.verifySignature(owner.address, "hello world", signature)
				).to.equal(true);
			});
		});


		/**
		 * @notice Typed Data Hash
		*/
		describe("[EIP-712] typedDataHash", async () => {
			it("Check signature..", async () => {
				const [owner] = await ethers.getSigners();

				const msg = {
					domain: {
						name: 'name',
						version: '1',
						chainId: 31337,
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

				// [hardhat] Get hash
				const hash = ethers.utils._TypedDataEncoder.hash(msg.domain, msg.types, msg.value)
				
				// [hardhat] Sign Message
				const signature = await owner.signMessage(ethers.utils.arrayify(hash));

				// [contract] takes: {bytes32} - prefixes with \x19Ethereum Signed Message
				const ethSignedHash = await mockSignatureManager.ECDSA_toEthSignedMessageHash(hash)

				// Correct signer recovered
				expect(
					await mockSignatureManager.ECDSA_recover(ethSignedHash, signature)
				).to.equal(owner.address);
			});
		});
	});
});