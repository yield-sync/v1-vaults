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
			it("Check signature2..", async () => {
				const [owner] = await ethers.getSigners();

				const msg = {
					// All properties on a domain are optional
					domain: {
						name: 'DApp Name',
						version: '1',
						chainId: 31337,
						verifyingContract: '0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC'
					},

					// The named list of all type definitions
					types: {
						Person: [
							{ name: 'name', type: 'string' },
							{ name: 'wallet', type: 'address' }
						],
						Mail: [
							{ name: 'from', type: 'Person' },
							{ name: 'to', type: 'Person' },
							{ name: 'contents', type: 'string' }
						]
					},

					// The data to sign
					value: {
						from: {
							name: 'Cow',
							wallet: '0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826'
						},
						to: {
							name: 'Bob',
							wallet: '0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB'
						},
						contents: 'Hello, Bob!'
					}
				};

				const signature = await owner._signTypedData(msg.domain, msg.types, msg.value);


				console.log("signature:", signature)
				await mockSignatureManager.ECDSA_recover(msg, signature)
				
			});

			it("domain separator returns properly", async () => {
				const [owner] = await ethers.getSigners();			
			});
		});
	});
});