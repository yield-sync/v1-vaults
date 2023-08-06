const { ethers } = require("hardhat");


import { expect } from "chai";
import { Bytes, Contract, ContractFactory, Signature, TypedDataDomain, TypedDataField } from "ethers";
import { Bytes32 } from "soltypes";


const chainId: number = 31337;


describe("[3] signatureProtocol.sol", async () => {
	let yieldSyncV1Vault: Contract;
	let yieldSyncV1VaultAccessControl: Contract;
	let yieldSyncV1VaultFactory: Contract;
	let yieldSyncV1ATransferRequestProtocol: Contract;
	let signatureProtocol: Contract;
	let mockAdmin: Contract;
	let mockDapp: Contract;
	let mockERC20: Contract;
	let mockERC721: Contract;
	let mockYieldSyncGovernance: Contract;


	beforeEach("[beforeEach] Set up contracts..", async () => {
		const [owner, addr1, addr2] = await ethers.getSigners();

		// Contract Factory
		const MockAdmin: ContractFactory = await ethers.getContractFactory("MockAdmin");
		const MockERC20: ContractFactory = await ethers.getContractFactory("MockERC20");
		const MockERC721: ContractFactory = await ethers.getContractFactory("MockERC721");
		const MockDapp: ContractFactory = await ethers.getContractFactory("MockDapp");
		const MockYieldSyncGovernance: ContractFactory = await ethers.getContractFactory("MockYieldSyncGovernance");

		const YieldSyncV1Vault: ContractFactory = await ethers.getContractFactory("YieldSyncV1Vault");
		const YieldSyncV1VaultFactory: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultFactory");
		const YieldSyncV1VaultAccessControl: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultAccessControl");
		const YieldSyncV1ASignatureProtocol: ContractFactory = await ethers.getContractFactory("YieldSyncV1ASignatureProtocol");
		const YieldSyncV1ATransferRequestProtocol: ContractFactory = await ethers.getContractFactory("YieldSyncV1ATransferRequestProtocol");

		/// Deploy
		// Mock
		mockDapp = await (await MockDapp.deploy()).deployed();
		mockAdmin = await (await MockAdmin.deploy()).deployed();
		mockERC20 = await (await MockERC20.deploy()).deployed();
		mockERC721 = await (await MockERC721.deploy()).deployed();
		mockYieldSyncGovernance = await (await MockYieldSyncGovernance.deploy()).deployed();

		// Expected
		yieldSyncV1VaultAccessControl = await (await YieldSyncV1VaultAccessControl.deploy()).deployed();

		// Deploy Factory
		yieldSyncV1VaultFactory = await (
			await YieldSyncV1VaultFactory.deploy(mockYieldSyncGovernance.address, yieldSyncV1VaultAccessControl.address)
		).deployed();

		// Deploy yieldSyncV1ATransferRequestProtocol
		yieldSyncV1ATransferRequestProtocol = await (
			await YieldSyncV1ATransferRequestProtocol.deploy(
				yieldSyncV1VaultAccessControl.address
			)
		).deployed();

		// Deploy Signature Protocol
		signatureProtocol = await (
			await YieldSyncV1ASignatureProtocol.deploy(
				mockYieldSyncGovernance.address,
				yieldSyncV1VaultAccessControl.address
			)
		).deployed();

		await signatureProtocol.yieldSyncV1Vault_signaturesRequiredUpdate(2);

		// Set YieldSyncV1Vault properties on TransferRequestProtocol.sol
		await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate(
			owner.address,
			[2, 2, 5] as UpdateVaultProperty
		);

		// Deploy a vault
		await yieldSyncV1VaultFactory.deployYieldSyncV1Vault(
			signatureProtocol.address,
			yieldSyncV1ATransferRequestProtocol.address,
			[owner.address],
			[addr1.address, addr2.address],
			{ value: 1 }
		);

		// Attach the deployed vault's address
		yieldSyncV1Vault = await YieldSyncV1Vault.attach(
			await yieldSyncV1VaultFactory.yieldSyncV1VaultId_yieldSyncV1Vault(0)
		);

		// Send ether to YieldSyncV1Vault contract
		await addr1.sendTransaction({
			to: yieldSyncV1Vault.address,
			value: ethers.utils.parseEther(".5")
		});

		// Send ERC20 to YieldSyncV1Vault contract
		await mockERC20.transfer(yieldSyncV1Vault.address, 50);

		// Send ERC721 to YieldSyncV1Vault contract
		await mockERC721.transferFrom(owner.address, yieldSyncV1Vault.address, 1);
	});

	/**
	 * @dev admin
	*/
	describe("Restriction: DEFAULT_ADMIN_ROLE (1/1)", async () => {
		/**
		* @dev updatePause
		*/
		describe("updatePause()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
			await signatureProtocol.updatePause(false);
					const [, addr1] = await ethers.getSigners();

					await expect(signatureProtocol.connect(addr1).updatePause(false)).to.be.rejectedWith("!auth");
				}
			);

			it(
				"Should be able to set toggle..",
				async () => {
					await signatureProtocol.updatePause(false);

					expect(await signatureProtocol.paused()).to.be.false;

					await signatureProtocol.updatePause(true);

					expect(await signatureProtocol.paused()).to.be.true;
				}
			);
		});
	});

	/**
	 * @notice [hardhat][ERC-191] Signing a Digest Hash
	*/
	describe("[hardhat][ERC-191] Signing a Digest Hash", async () => {
		it("Should not allow signing by anyone but wallet with MEMBER role..", async () => {
			await signatureProtocol.updatePause(false);

			const [, , , addr3] = await ethers.getSigners();

			const messageHash: Bytes = ethers.utils.id("Hello, world!");

			const signature: Signature = await addr3.signMessage(ethers.utils.arrayify(messageHash));

			await expect(
				signatureProtocol.connect(addr3).signMessageHash(
					yieldSyncV1Vault.address,
					messageHash,
					signature
				)
			).to.be.rejectedWith("!member");
		});

		it("Should be able to recover the original address..", async () => {
			await signatureProtocol.updatePause(false);

			const [, , , addr3] = await ethers.getSigners();

			const messageHash: Bytes = ethers.utils.id("Hello, world!");

			const signature: string = await addr3.signMessage(ethers.utils.arrayify(messageHash));

			// For Solidity, we need the expanded-format of a signature
			const { v, r, s } = ethers.utils.splitSignature(signature);

			// Correct signer recovered
			expect(await mockDapp.recoverSigner(messageHash, v, r, s)).to.equal(addr3.address);
		});

		it(
			"Should allow a MEMBER to sign a bytes32 messageHash and create a yieldSyncV1Vault_messageHash_messageHashData value..",
			async () => {
				await signatureProtocol.updatePause(false);

				const [, addr1] = await ethers.getSigners();

				const messageHash: Bytes = ethers.utils.id("Hello, world!");

				const signature: Signature = await addr1.signMessage(ethers.utils.arrayify(messageHash));

				// [contract] Sign message hash
				await signatureProtocol.connect(addr1).signMessageHash(yieldSyncV1Vault.address, messageHash, signature);

				// [contract]
				const retrievedBytes32: Bytes32[] = await signatureProtocol.vaultMessageHashes(yieldSyncV1Vault.address);

				expect(retrievedBytes32[0]).to.be.equal(messageHash);

				const messageHashData: any = await signatureProtocol.yieldSyncV1Vault_messageHash_messageHashData(
					yieldSyncV1Vault.address,
					retrievedBytes32[0]
				);

				const messageHashVote: any = await signatureProtocol.yieldSyncV1Vault_messageHash_messageHashVote(
					yieldSyncV1Vault.address,
					retrievedBytes32[0]
				);

				expect(messageHashData.signature).to.be.equal(signature);
				expect(messageHashData.signer).to.be.equal(addr1.address);
				expect(messageHashVote.signedMembers[0]).to.be.equal(addr1.address);
				expect(messageHashVote.signatureCount).to.be.equal(1);
			}
		);

		it("Should not allow double signing..", async () => {
			await signatureProtocol.updatePause(false);

			const [, addr1] = await ethers.getSigners();

			const messageHash: Bytes = ethers.utils.id("Hello, world!");

			const signature: Signature = await addr1.signMessage(ethers.utils.arrayify(messageHash));

			// [contract] Sign message hash
			await signatureProtocol.connect(addr1).signMessageHash(yieldSyncV1Vault.address, messageHash, signature);

			// [contract]
			const retrievedBytes32: Bytes32[] = await signatureProtocol.vaultMessageHashes(yieldSyncV1Vault.address);

			const messageHashData: any = await signatureProtocol.yieldSyncV1Vault_messageHash_messageHashData(
				yieldSyncV1Vault.address,
				retrievedBytes32[0]
			);

			signatureProtocol.connect(addr1).signMessageHash(
				yieldSyncV1Vault.address,
				retrievedBytes32[0],
				messageHashData.signature
			)

			// [contract]
			await expect(
				signatureProtocol.connect(addr1).signMessageHash(
					yieldSyncV1Vault.address,
					retrievedBytes32[0],
					messageHashData.signature
				)
			).to.be.rejectedWith("Already signed");
		});

		it(
			"Should fail yieldSyncV1Vault.isValidSignature() due to not enough votes..",
			async () => {
				await signatureProtocol.updatePause(false);

				const [, addr1] = await ethers.getSigners();

				const messageHash: Bytes = ethers.utils.id("Hello, world!");

				const signature: Signature = await addr1.signMessage(ethers.utils.arrayify(messageHash));

				// [contract] Sign message hash
				await signatureProtocol.connect(addr1).signMessageHash(
					yieldSyncV1Vault.address,
					messageHash,
					signature
				);

				// [contract]
				const retrievedBytes32: Bytes32[] = await signatureProtocol.vaultMessageHashes(yieldSyncV1Vault.address);

				const messageHashData = await signatureProtocol.yieldSyncV1Vault_messageHash_messageHashData(
					yieldSyncV1Vault.address,
					retrievedBytes32[0]
				);

				expect(
					await yieldSyncV1Vault.isValidSignature(retrievedBytes32[0], messageHashData.signature)
				).to.be.equal("0x00000000");
			}
		);

		it("Should pass yieldSyncV1Vault.isValidSignature() due to enough votes..", async () => {
			await signatureProtocol.updatePause(false);

			const [, addr1, addr2] = await ethers.getSigners();

			const messageHash: Bytes = ethers.utils.id("Hello, world!");

			const signature: Signature = await addr1.signMessage(ethers.utils.arrayify(messageHash));

			// [contract] Sign message hash
			await signatureProtocol.connect(addr1).signMessageHash(
				yieldSyncV1Vault.address,
				messageHash,
				signature
			);

			// [contract]
			const retrievedBytes32: Bytes32[] = await signatureProtocol.vaultMessageHashes(yieldSyncV1Vault.address);

			const messageHashData: any = await signatureProtocol.yieldSyncV1Vault_messageHash_messageHashData(
				yieldSyncV1Vault.address,
				retrievedBytes32[0]
			);

			// [contract]
			await signatureProtocol.connect(addr2).signMessageHash(
				yieldSyncV1Vault.address,
				retrievedBytes32[0],
				messageHashData.signature
			);

			expect(
				await yieldSyncV1Vault.isValidSignature(retrievedBytes32[0], messageHashData[0])
			).to.be.equal("0x1626ba7e");
		});
	});


	/**
	 * @notice [hardhat][EIP-712] Signing typedDataHash
	*/
	describe("[hardhat][EIP-712] Signing typedDataHash", async () => {
		it("Should be able to sign and verify a a typedDataHash successfully..", async () => {
			await signatureProtocol.updatePause(false);

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
			await signatureProtocol.connect(addr1).signMessageHash(yieldSyncV1Vault.address, messageHash, signature);

			// [contract]
			const retrievedBytes32: Bytes32[] = await signatureProtocol.vaultMessageHashes(yieldSyncV1Vault.address);

			expect(retrievedBytes32[0]).to.be.equal(messageHash);

			const messageHashData: any = await signatureProtocol.yieldSyncV1Vault_messageHash_messageHashData(
				yieldSyncV1Vault.address,
				retrievedBytes32[0]
			);

			const messageHashVote: any = await signatureProtocol.yieldSyncV1Vault_messageHash_messageHashVote(
				yieldSyncV1Vault.address,
				retrievedBytes32[0]
			);

			expect(messageHashData.signature).to.be.equal(signature);
			expect(messageHashData.signer).to.be.equal(addr1.address);
			expect(messageHashVote.signedMembers[0]).to.be.equal(addr1.address);
			expect(messageHashVote.signatureCount).to.be.equal(1);
		});

		it("Should fail yieldSyncV1Vault.isValidSignature() due to not being latest signature..", async () => {
			await signatureProtocol.updatePause(false);

			const [, addr1] = await ethers.getSigners();

			const messageHash: Bytes = ethers.utils.id("Hello, world!");

			const signature: Signature = await addr1.signMessage(ethers.utils.arrayify(messageHash));

			// [contract] Sign message hash
			await signatureProtocol.connect(addr1).signMessageHash(
				yieldSyncV1Vault.address,
				messageHash,
				signature
			);

			// [contract]
			const retrievedBytes32: Bytes32[] = await signatureProtocol.vaultMessageHashes(yieldSyncV1Vault.address);

			const messageHashData = await signatureProtocol.yieldSyncV1Vault_messageHash_messageHashData(
				yieldSyncV1Vault.address,
				retrievedBytes32[0]
			);

			expect(
				await yieldSyncV1Vault.isValidSignature(retrievedBytes32[0], messageHashData[0])
			).to.be.equal("0x00000000");
		});
	});
});
