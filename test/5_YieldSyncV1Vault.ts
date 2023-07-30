import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";

const { ethers } = require("hardhat");


const twoDaysInSeconds = 2 * 24 * 60 * 60;


describe("[5] YieldSyncV1Vault.sol", async () => {
	let yieldSyncV1Vault: Contract;
	let yieldSyncV1VaultFactory: Contract;
	let yieldSyncV1ATransferRequestProtocol: Contract;
	let yieldSyncV1VaultAccessControl: Contract;
	let mockYieldSyncGovernance: Contract;


	beforeEach("[before] Set up contracts..", async () => {
		const [admin, addr1, addr2, addr3] = await ethers.getSigners();

		// Contract Factory
		const YieldSyncV1Vault: ContractFactory = await ethers.getContractFactory("YieldSyncV1Vault");
		const YieldSyncV1VaultFactory: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultFactory");
		const YieldSyncV1VaultAccessControl: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultAccessControl");
		const MockYieldSyncGovernance: ContractFactory = await ethers.getContractFactory("MockYieldSyncGovernance");
		const YieldSyncV1ATransferRequestProtocol: ContractFactory = await ethers.getContractFactory("YieldSyncV1ATransferRequestProtocol");


		// Contract
		mockYieldSyncGovernance = await (await MockYieldSyncGovernance.deploy()).deployed();
		yieldSyncV1VaultAccessControl = await (await YieldSyncV1VaultAccessControl.deploy()).deployed();
		yieldSyncV1VaultFactory = await (
			await YieldSyncV1VaultFactory.deploy(mockYieldSyncGovernance.address, yieldSyncV1VaultAccessControl.address)
		).deployed();

		// Deploy yieldSyncV1ATransferRequestProtocol
		yieldSyncV1ATransferRequestProtocol = await (
			await YieldSyncV1ATransferRequestProtocol.deploy(yieldSyncV1VaultAccessControl.address)
		).deployed();

		// Set YieldSyncV1Vault properties on TransferRequestProtocol.sol
		await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate(
			admin.address,
			[2, 2, twoDaysInSeconds]
		);

		// Deploy a vault
		await yieldSyncV1VaultFactory.deployYieldSyncV1Vault(
			ethers.constants.AddressZero,
			yieldSyncV1ATransferRequestProtocol.address,
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
			const mockSignatureProtocol = await (
				await MockSignatureProtocol.deploy(
					mockYieldSyncGovernance.address,
					yieldSyncV1VaultAccessControl.address
				)
			).deployed();

			// Preset
			await mockSignatureProtocol.connect(BadActor).yieldSyncV1Vault_signaturesRequiredUpdate(2);

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

			// Deploy mockSignatureProtocol
			const mockTransferRequestProtocol = await (
				await MockTransferRequestProtocol.deploy(yieldSyncV1VaultAccessControl.address)
			).deployed();

			// Preset
			await mockTransferRequestProtocol.connect(BadActor).yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate(
				BadActor.address,
				[1, 1, 10]
			);

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

	describe("Potential Reentrancy Attacks", async () => {
		it("Should NOT allow any reentrancy attacks..", async function () {
			const balanceBefore = ethers.utils.formatUnits(await ethers.provider.getBalance(yieldSyncV1Vault.address));

			const [, addr1, addr2] = await ethers.getSigners();

			// Deploy the attacker contract
			const ReenteranceAttacker = await ethers.getContractFactory("ReenteranceAttacker");

			const reenteranceAttacker = await ReenteranceAttacker.connect(addr1).deploy();

			await yieldSyncV1Vault.memberAdd(reenteranceAttacker.address);

			await yieldSyncV1ATransferRequestProtocol.connect(
				addr1
			).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
				yieldSyncV1Vault.address,
				false,
				false,
				reenteranceAttacker.address,
				ethers.constants.AddressZero,
				ethers.utils.parseEther(".5"),
				0
			);

			// Vote
			await yieldSyncV1ATransferRequestProtocol.connect(
				addr1
			).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
				yieldSyncV1Vault.address,
				0,
				true
			)

			// Vote
			await yieldSyncV1ATransferRequestProtocol.connect(
				addr2
			).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
				yieldSyncV1Vault.address,
				0,
				true
			)

			// Fast forward
			await ethers.provider.send('evm_increaseTime', [twoDaysInSeconds + 60]);

			// Attempt attack
			await reenteranceAttacker.attack(yieldSyncV1Vault.address, 0);

			expect(
				balanceBefore
			).to.be.equal(
				ethers.utils.formatUnits(await ethers.provider.getBalance(yieldSyncV1Vault.address))
			);
		});
	});
});
