import { expect } from "chai";
import { Contract } from "ethers";

const { ethers } = require("hardhat");


const chainId = 31337;


describe("Mock Signature Manager", async () => {
	let mockIglooFiGovernance: Contract;
	let iglooFiV1VaultFactory: Contract;
	let iglooFiV1Vault: Contract;
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
	 * @dev Deploy MockIglooFiGovernance.sol
	*/
	before("[before] Deploy IglooFiGovernance.sol contract..", async () => {
		const MockIglooFiGovernance = await ethers.getContractFactory("MockIglooFiGovernance");

		mockIglooFiGovernance = await MockIglooFiGovernance.deploy();
		mockIglooFiGovernance = await mockIglooFiGovernance.deployed();
	});

	/**
	 * @notice Deploy contract
	 * @dev Deploy IglooFiV1VaultFactory.sol
	*/
	before("[before] Deploy IglooFiV1VaultFactory.sol contracts..", async () => {
		const IglooFiV1VaultFactory = await ethers.getContractFactory("IglooFiV1VaultFactory");

		iglooFiV1VaultFactory = await IglooFiV1VaultFactory.deploy(
			mockIglooFiGovernance.address
		);

		iglooFiV1VaultFactory = await iglooFiV1VaultFactory.deployed();

		await iglooFiV1VaultFactory.setPause(false);
	});


	/**
	 * @notice Deploy contract
	 * @dev Factory Deploy IglooFiV1Vault.sol (IglooFiV1VaultFactory.sol)
	*/
	before("[before] Factory deploy IglooFiV1Vault.sol..", async () => {
		const [owner, addr1, addr2] = await ethers.getSigners();

		const IglooFiV1Vault = await ethers.getContractFactory("IglooFiV1Vault");
		
		// Deploy a vault
		await iglooFiV1VaultFactory.deployVault(
			owner.address,
			2,
			5,
			{ value: 1 }
		);

		// Attach the deployed vault's address
		iglooFiV1Vault = await IglooFiV1Vault.attach(iglooFiV1VaultFactory.vaultAddress(0));

		await iglooFiV1Vault.addVoter(addr1.address);
		await iglooFiV1Vault.addVoter(addr2.address);

		await iglooFiV1Vault.updateSignatureManager(mockSignatureManager.address);
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
		 * @notice [hardhat][ERC-191] Signing a Digest Hash
		 */
		describe("[hardhat][ERC-191] Signing a Digest Hash", async () => {
			it("Should not allow signing by anyone but wallet with VOTER role..", async () => {
				const [, , , addr3] = await ethers.getSigners();

				const messageHash = ethers.utils.id("Hello, world!");

				const signature = await addr3.signMessage(ethers.utils.arrayify(messageHash));

				await expect(
					mockSignatureManager.connect(addr3).signMessageHash(
						iglooFiV1Vault.address,
						messageHash,
						signature
					)
				).to.be.rejectedWith("!auth");
			});

			it("Should allow a VOTER to sign a bytes32 messageHash and create a vaultMessageHashData value..", async () => {
				const [, addr1] = await ethers.getSigners();

				const messageHash = ethers.utils.id("Hello, world!");

				const signature = await addr1.signMessage(ethers.utils.arrayify(messageHash));

				// For Solidity, we need the expanded-format of a signature
				const splitSignature = ethers.utils.splitSignature(signature);

				// Correct signer recovered
				expect(
					await mockSignatureManager.recoverSigner(
						messageHash,
						splitSignature.v,
						splitSignature.r,
						splitSignature.s
					)
				).to.equal(addr1.address);

				// [contract]
				await mockSignatureManager.connect(addr1).signMessageHash(
					iglooFiV1Vault.address,
					messageHash,
					signature
				);

				// [contract]
				const retrievedBytes32 = await mockSignatureManager.vaultMessageHashes(
					iglooFiV1Vault.address
				);

				expect(retrievedBytes32[0]).to.be.equal(messageHash);

				const messageHashData = await mockSignatureManager.vaultMessageHashData(
					iglooFiV1Vault.address,
					retrievedBytes32[0]
				);
				
				expect(messageHashData[0]).to.be.equal(signature);
				expect(messageHashData[1]).to.be.equal(addr1.address);
				expect(messageHashData[2][0]).to.be.equal(addr1.address);
				expect(messageHashData[3]).to.be.equal(1);
			});

			it("Should not allow double signing..", async () => {
				const [, addr1] = await ethers.getSigners();

				// [contract]
				const retrievedBytes32 = await mockSignatureManager.vaultMessageHashes(
					iglooFiV1Vault.address
				);

				const messageHashData = await mockSignatureManager.vaultMessageHashData(
					iglooFiV1Vault.address,
					retrievedBytes32[0]
				);

				// [contract]
				await expect(
					mockSignatureManager.connect(addr1).signMessageHash(
						iglooFiV1Vault.address,
						retrievedBytes32[0],
						messageHashData[0]
					)
				).to.be.rejectedWith("Already signed");
			});

			it("Should fail iglooFiV1Vault.isValidSignature() due to not enough votes..", async () => {
				// [contract]
				const retrievedBytes32 = await mockSignatureManager.vaultMessageHashes(
					iglooFiV1Vault.address
				);

				const messageHashData = await mockSignatureManager.vaultMessageHashData(
					iglooFiV1Vault.address,
					retrievedBytes32[0]
				);
				
				expect(
					await iglooFiV1Vault.isValidSignature(
						retrievedBytes32[0],
						messageHashData[0]
					)
				).to.be.equal("0x00000000");
			});

			it("Should pass iglooFiV1Vault.isValidSignature() due to enough votes..", async () => {
				const [, , addr2] = await ethers.getSigners();

				// [contract]
				const retrievedBytes32 = await mockSignatureManager.vaultMessageHashes(
					iglooFiV1Vault.address
				);

				const messageHashData = await mockSignatureManager.vaultMessageHashData(
					iglooFiV1Vault.address,
					retrievedBytes32[0]
				);
					
				// [contract]
				await mockSignatureManager.connect(addr2).signMessageHash(
					iglooFiV1Vault.address,
					retrievedBytes32[0],
					messageHashData[0]
				);
				
				expect(
					await iglooFiV1Vault.isValidSignature(
						retrievedBytes32[0],
						messageHashData[0]
					)
				).to.be.equal("0x1626ba7e");
			});
		});


		/**
		 * @notice [hardhat][EIP-712] Signing typedDataHash
		*/
		describe("[hardhat][EIP-712] Signing typedDataHash", async () => {
			it("Check signature..", async () => {
				const [owner, addr1] = await ethers.getSigners();

				const message = {
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
					}
				};
				
				/**
				 * @dev To get the payload use the line below
				 * ethers.utils._TypedDataEncoder.getPayload(msg.domain, msg.types, msg.value);
				*/
				
				// [ethers] Get hash
				const messageHash = ethers.utils._TypedDataEncoder.hash(
					message.domain,
					message.types,
					message.value
				);

				// [hardhat] Sign Message
				const signature = await addr1.signMessage(ethers.utils.arrayify(messageHash));
				
				// For Solidity, we need the expanded-format of a signature
				const splitSignature = ethers.utils.splitSignature(signature);

				// Correct signer recovered
				expect(
					await mockSignatureManager.recoverSigner(
						messageHash,
						splitSignature.v,
						splitSignature.r,
						splitSignature.s
					)
				).to.equal(addr1.address);

				// [contract]
				await mockSignatureManager.connect(addr1).signMessageHash(
					iglooFiV1Vault.address,
					messageHash,
					signature
				);

				// [contract]
				const retrievedBytes32 = await mockSignatureManager.vaultMessageHashes(
					iglooFiV1Vault.address
				);

				expect(retrievedBytes32[1]).to.be.equal(messageHash);

				const messageHashData = await mockSignatureManager.vaultMessageHashData(
					iglooFiV1Vault.address,
					retrievedBytes32[1]
				);
				
				expect(messageHashData[0]).to.be.equal(signature);
				expect(messageHashData[1]).to.be.equal(addr1.address);
				expect(messageHashData[2][0]).to.be.equal(addr1.address);
				expect(messageHashData[3]).to.be.equal(1);
			});
		});
	});
});