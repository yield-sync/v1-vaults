import { expect } from "chai";
import { Bytes, Contract, ContractFactory, Signature, TypedDataDomain, TypedDataField } from "ethers";

const { ethers } = require("hardhat");


const chainId: number = 31337;


describe("SignatureManager.sol - Mock Signature Manager Contract", async () => {
	let mockIglooFiGovernance: Contract;
	let iglooFiV1VaultFactory: Contract;
	let iglooFiV1Vault: Contract;
	let signatureManager: Contract;
	let mockDapp: Contract;

	/**
	 * @notice Deploy contract
	 * @dev Deploy MockIglooFiGovernance.sol
	*/
	before("[before] Deploy IglooFiGovernance.sol contract..", async () => {
		const [owner, addr1, addr2] = await ethers.getSigners();

		const MockIglooFiGovernance: ContractFactory = await ethers.getContractFactory("MockIglooFiGovernance");
		const SignatureManager: ContractFactory = await ethers.getContractFactory("SignatureManager");
		const IglooFiV1VaultFactory: ContractFactory = await ethers.getContractFactory("IglooFiV1VaultFactory");
		const IglooFiV1Vault: ContractFactory = await ethers.getContractFactory("IglooFiV1Vault");
		const MockDapp: ContractFactory = await ethers.getContractFactory("MockDapp");

		mockIglooFiGovernance = await (await MockIglooFiGovernance.deploy()).deployed();
		signatureManager = await (await SignatureManager.deploy(mockIglooFiGovernance.address)).deployed();
		iglooFiV1VaultFactory = await (await IglooFiV1VaultFactory.deploy(mockIglooFiGovernance.address)).deployed();
		mockDapp = await (await MockDapp.deploy()).deployed();

		// Unpause contract
		await iglooFiV1VaultFactory.setPause(false);

		// Deploy a vault
		await iglooFiV1VaultFactory.deployVault(
			owner.address,
			ethers.constants.AddressZero,
			true,
			2,
			5,
			{ value: 1 }
		);

		// Attach the deployed vault's address
		iglooFiV1Vault = await IglooFiV1Vault.attach(iglooFiV1VaultFactory.vaultAddress(0));

		await iglooFiV1Vault.addVoter(addr1.address);
		await iglooFiV1Vault.addVoter(addr2.address);

		await iglooFiV1Vault.updateSignatureManager(signatureManager.address);
	});

	/**
	 * @dev admin
	*/
	describe("Restriction: DEFAULT_ADMIN_ROLE", async () => {
		/**
		* @dev setPause
		*/
		describe("setPause", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();
		
					await expect(signatureManager.connect(addr1).setPause(false)).to.be.rejectedWith("!auth");
				}
			);

			it(
				"Should be able to set true..",
				async () => {
					await signatureManager.setPause(false);
					
					expect(await signatureManager.paused()).to.be.false;
				}
			);

			it(
				"Should be able to set false..",
				async () => {
					await signatureManager.setPause(true);
					
					expect(await signatureManager.paused()).to.be.true;
				
					// Unpause for the rest of the test
					await signatureManager.setPause(false);
				}
			);
		});
	});

	/**
	 * @notice [hardhat][ERC-191] Signing a Digest Hash
	*/
	describe("[hardhat][ERC-191] Signing a Digest Hash", async () => {
		it("Should not allow signing by anyone but wallet with VOTER role..", async () => {
			const [, , , addr3] = await ethers.getSigners();

			const messageHash: Bytes = ethers.utils.id("Hello, world!");

			const signature: Signature = await addr3.signMessage(ethers.utils.arrayify(messageHash));

			await expect(
				signatureManager.connect(addr3).signMessageHash(
					iglooFiV1Vault.address,
					messageHash,
					signature
				)
			).to.be.rejectedWith("!auth");
		});

		it("Should be able to recover the original address..", async () => {
			const [, , , addr3] = await ethers.getSigners();

			const messageHash: Bytes = ethers.utils.id("Hello, world!");

			const signature: string = await addr3.signMessage(ethers.utils.arrayify(messageHash));

			// For Solidity, we need the expanded-format of a signature
			const { v, r, s } = ethers.utils.splitSignature(signature);

			// Correct signer recovered
			expect(await mockDapp.recoverSigner(messageHash, v, r, s)).to.equal(addr3.address);
		});

		it("Should allow a VOTER to sign a bytes32 messageHash and create a vaultMessageHashData value..", async () => {
			const [, addr1] = await ethers.getSigners();

			const messageHash: Bytes = ethers.utils.id("Hello, world!");

			const signature: Signature = await addr1.signMessage(ethers.utils.arrayify(messageHash));

			// [contract] Sign message hash
			await signatureManager.connect(addr1).signMessageHash(iglooFiV1Vault.address, messageHash, signature);

			// [contract]
			const retrievedBytes32 = await signatureManager.vaultMessageHashes(iglooFiV1Vault.address);

			expect(retrievedBytes32[0]).to.be.equal(messageHash);

			const messageHashData: any = await signatureManager.vaultMessageHashData(
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
			const retrievedBytes32 = await signatureManager.vaultMessageHashes(iglooFiV1Vault.address);

			const messageHashData: Bytes = await signatureManager.vaultMessageHashData(
				iglooFiV1Vault.address,
				retrievedBytes32[0]
			);

			// [contract]
			await expect(
				signatureManager.connect(addr1).signMessageHash(
					iglooFiV1Vault.address,
					retrievedBytes32[0],
					messageHashData[0]
				)
			).to.be.rejectedWith("Already signed");
		});

		it("Should fail iglooFiV1Vault.isValidSignature() due to not enough votes..", async () => {
			// [contract]
			const retrievedBytes32 = await signatureManager.vaultMessageHashes(iglooFiV1Vault.address);

			const messageHashData = await signatureManager.vaultMessageHashData(
				iglooFiV1Vault.address,
				retrievedBytes32[0]
			);
			
			expect(
				await iglooFiV1Vault.isValidSignature(retrievedBytes32[0], messageHashData[0])
			).to.be.equal("0x00000000");
		});

		it("Should pass iglooFiV1Vault.isValidSignature() due to enough votes..", async () => {
			const [, , addr2] = await ethers.getSigners();

			// [contract]
			const retrievedBytes32 = await signatureManager.vaultMessageHashes(iglooFiV1Vault.address);

			const messageHashData: Bytes = await signatureManager.vaultMessageHashData(
				iglooFiV1Vault.address,
				retrievedBytes32[0]
			);
				
			// [contract]
			await signatureManager.connect(addr2).signMessageHash(
				iglooFiV1Vault.address,
				retrievedBytes32[0],
				messageHashData[0]
			);
			
			expect(
				await iglooFiV1Vault.isValidSignature(retrievedBytes32[0], messageHashData[0])
			).to.be.equal("0x1626ba7e");
		});
	});


	/**
	 * @notice [hardhat][EIP-712] Signing typedDataHash
	*/
	describe("[hardhat][EIP-712] Signing typedDataHash", async () => {
		it("Should be able to sign and verify a a typedDataHash successfully..", async () => {
			const [, addr1] = await ethers.getSigners();

			const message: {
				domain: TypedDataDomain,
				types: Record<string, Array<TypedDataField>>,
				value: Record<string, any>
			} = {
				domain: {
					name: "MockDapp",
					version: "1",
					chainId: chainId,
					verifyingContract: mockDapp.address
				},
				types: {
					Score: [
						{ name: "player", type: "address" },
						{ name: "points", type: "uint" }
					]
				},
				value: {
					player: ethers.constants.AddressZero,
					points: 1
				}
			};
			
			/**
			 * @dev To get the payload use the line below
			 * ethers.utils._TypedDataEncoder.getPayload(msg.domain, msg.types, msg.value);
			*/
			
			// [ethers] Get hash
			const messageHash: Bytes = ethers.utils._TypedDataEncoder.hash(
				message.domain,
				message.types,
				message.value
			);
			
			// Test for onchain generated hash
			expect(
				await mockDapp.hashTypedDataV4(await mockDapp.getStructHash(ethers.constants.AddressZero, 1))
			).to.be.equal(messageHash);		

			// [hardhat] Sign Message
			const signature: Signature = await addr1.signMessage(ethers.utils.arrayify(messageHash));

			// [contract] Sign message hash
			await signatureManager.connect(addr1).signMessageHash(iglooFiV1Vault.address, messageHash, signature);

			// [contract]
			const retrievedBytes32: Bytes = await signatureManager.vaultMessageHashes(iglooFiV1Vault.address);

			expect(retrievedBytes32[1]).to.be.equal(messageHash);

			const messageHashData: any = await signatureManager.vaultMessageHashData(
				iglooFiV1Vault.address,
				retrievedBytes32[1]
			);
			
			expect(messageHashData[0]).to.be.equal(signature);
			expect(messageHashData[1]).to.be.equal(addr1.address);
			expect(messageHashData[2][0]).to.be.equal(addr1.address);
			expect(messageHashData[3]).to.be.equal(1);
		});

		it("Should fail iglooFiV1Vault.isValidSignature() due to not being latest signature..", async () => {
			// [contract]
			const retrievedBytes32 = await signatureManager.vaultMessageHashes(iglooFiV1Vault.address);

			const messageHashData = await signatureManager.vaultMessageHashData(
				iglooFiV1Vault.address,
				retrievedBytes32[0]
			);
			
			expect(
				await iglooFiV1Vault.isValidSignature(retrievedBytes32[0], messageHashData[0])
			).to.be.equal("0x00000000");
		});
	});
});