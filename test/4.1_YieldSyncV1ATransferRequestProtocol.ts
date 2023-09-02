type UpdateVaultProperty = [
	// voteAgainstRequired
	number,
	// voteForRequired
	number,
	// transferDelaySeconds
	number,
];


const { ethers } = require("hardhat");


import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";


const twoDaysInSeconds = 2 * 24 * 60 * 60;


describe("[4.1] YieldSyncV1Vault.sol with YieldSyncV1ATransferRequestProtocol - Security", async () => {
	let yieldSyncV1Vault: Contract;
	let yieldSyncV1VaultFactory: Contract;
	let yieldSyncV1ATransferRequestProtocol: Contract;
	let yieldSyncV1VaultRegistry: Contract;
	let mockYieldSyncGovernance: Contract;


	beforeEach("[beforeEach] Set up contracts..", async () => {
		const [admin, addr1, addr2, addr3] = await ethers.getSigners();

		// Contract Factory
		const YieldSyncV1Vault: ContractFactory = await ethers.getContractFactory("YieldSyncV1Vault");
		const YieldSyncV1VaultFactory: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultFactory");
		const YieldSyncV1VaultRegistry: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultRegistry");
		const MockYieldSyncGovernance: ContractFactory = await ethers.getContractFactory("MockYieldSyncGovernance");
		const YieldSyncV1ATransferRequestProtocol: ContractFactory = await ethers.getContractFactory("YieldSyncV1ATransferRequestProtocol");


		// Contract
		mockYieldSyncGovernance = await (await MockYieldSyncGovernance.deploy()).deployed();
		yieldSyncV1VaultRegistry = await (await YieldSyncV1VaultRegistry.deploy()).deployed();
		yieldSyncV1VaultFactory = await (
			await YieldSyncV1VaultFactory.deploy(mockYieldSyncGovernance.address, yieldSyncV1VaultRegistry.address)
		).deployed();

		// Deploy yieldSyncV1ATransferRequestProtocol
		yieldSyncV1ATransferRequestProtocol = await (
			await YieldSyncV1ATransferRequestProtocol.deploy(yieldSyncV1VaultRegistry.address)
		).deployed();

		// Set YieldSyncV1Vault properties on TransferRequestProtocol.sol
		await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate(
			admin.address,
			[2, 2, twoDaysInSeconds] as UpdateVaultProperty
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
