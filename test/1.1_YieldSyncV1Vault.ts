const { ethers } = require("hardhat");


import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";


describe("[1.1] YieldSyncV1Vault.sol - Security", async () => {
	let yieldSyncV1Vault: Contract;
	let yieldSyncV1VaultFactory: Contract;
	let yieldSyncV1VaultRegistry: Contract;
	let mockYieldSyncGovernance: Contract;


	beforeEach("[beforeEach] Set up contracts..", async () => {
		const [admin, addr1, addr2, addr3] = await ethers.getSigners();

		// Contract Factory
		const YieldSyncV1Vault: ContractFactory = await ethers.getContractFactory("YieldSyncV1Vault");
		const YieldSyncV1VaultFactory: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultFactory");
		const YieldSyncV1VaultRegistry: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultRegistry");
		const MockYieldSyncGovernance: ContractFactory = await ethers.getContractFactory("MockYieldSyncGovernance");

		// Contract
		mockYieldSyncGovernance = await (await MockYieldSyncGovernance.deploy()).deployed();
		yieldSyncV1VaultRegistry = await (await YieldSyncV1VaultRegistry.deploy()).deployed();
		yieldSyncV1VaultFactory = await (
			await YieldSyncV1VaultFactory.deploy(mockYieldSyncGovernance.address, yieldSyncV1VaultRegistry.address)
		).deployed();

		// Deploy a vault
		await yieldSyncV1VaultFactory.deployYieldSyncV1Vault(
			ethers.constants.AddressZero,
			ethers.constants.AddressZero,
			[admin.address],
			[addr1.address, addr2.address, addr3.address],
			{ value: 1 }
		);

		// Attach the deployed vault's address
		yieldSyncV1Vault = await YieldSyncV1Vault.attach(
			await yieldSyncV1VaultFactory.yieldSyncV1VaultId_yieldSyncV1Vault(0)
		);

		// Send ether to YieldSyncV1Vault contract
		await addr1.sendTransaction({
			to: yieldSyncV1Vault.address,
			value: ethers.utils.parseEther("5")
		});
	});

	describe("adminAdd()", async () => {
		it("BadActor should fail to add himself as admin..", async () => {
			const [admin, addr1, addr2, addr3, BadActor] = await ethers.getSigners();

			await expect(yieldSyncV1Vault.connect(BadActor).adminAdd(BadActor.address)).to.be.rejectedWith("!admin");
		});
	});

	describe("adminRemove()", async () => {
		it("BadActor should fail to remove existing admin..", async () => {
			const [admin, , , , BadActor] = await ethers.getSigners();

			await expect(yieldSyncV1Vault.connect(BadActor).adminRemove(admin.address)).to.be.rejectedWith("!admin");
		});
	});

	describe("memberAdd()", async () => {
		it("BadActor should fail to add himself as member..", async () => {
			const [, , , , BadActor] = await ethers.getSigners();

			await expect(yieldSyncV1Vault.connect(BadActor).memberAdd(BadActor.address)).to.be.rejectedWith("!admin");
		});
	});

	describe("memberRemove()", async () => {
		it("BadActor should fail to remove existing admin..", async () => {
			const [admin, , , , BadActor] = await ethers.getSigners();

			await expect(yieldSyncV1Vault.connect(BadActor).memberRemove(admin.address)).to.be.rejectedWith("!admin");
		});
	});

	describe("signatureProtocolUpdate()", async () => {
		it("BadActor should fail to change signatureProtocol..", async () => {
			const [, , , , BadActor] = await ethers.getSigners();

			const MockSignatureProtocol: ContractFactory = await ethers.getContractFactory("MockSignatureProtocol");

			// Deploy mockSignatureProtocol
			const mockSignatureProtocol = await (await MockSignatureProtocol.deploy()).deployed();

			await expect(
				yieldSyncV1Vault.connect(BadActor).signatureProtocolUpdate(mockSignatureProtocol.address)
			).to.be.rejectedWith(
				"!admin"
			);
		});
	});

	describe("transferRequestProtocolUpdate()", async () => {
		it("BadActor should fail to change transferRequestProtocol..", async () => {
			const [, , , , BadActor] = await ethers.getSigners();

			const MockTransferRequestProtocol: ContractFactory = await ethers.getContractFactory(
				"MockTransferRequestProtocol"
			);

			const mockTransferRequestProtocol = await (await MockTransferRequestProtocol.deploy()).deployed();

			await expect(
				yieldSyncV1Vault.connect(BadActor).transferRequestProtocolUpdate(mockTransferRequestProtocol.address)
			).to.be.rejectedWith(
				"!admin"
			);
		});
	});

	describe("yieldSyncV1Vault_transferRequestId_transferRequestProcess()", async () => {
		it("BadActor should not be able to process transferRequest..", async () => {
			const [, , , , BadActor] = await ethers.getSigners();

			await expect(
				yieldSyncV1Vault.connect(BadActor).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0)
			).to.be.rejectedWith(
				"!member"
			);
		});
	});

	describe("renounceMembership()", async () => {
		it("BadActor should not be able to renounce a membership that does not exist..", async () => {
			const [, , , , BadActor] = await ethers.getSigners();

			await expect(yieldSyncV1Vault.connect(BadActor).renounceMembership()).to.be.rejectedWith("!member");
		});
	});
});
