const { ethers } = require("hardhat");


import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";


describe("[2] YieldSyncV1VaultAccessControl.sol", async () => {
	let yieldSyncV1Vault: Contract;
	let yieldSyncV1VaultFactory: Contract;
	let yieldSyncV1ATransferRequestProtocol: Contract;
	let yieldSyncV1VaultAccessControl: Contract;
	let mockYieldSyncGovernance: Contract;


	beforeEach("[before] Set up contracts..", async () => {
		const [owner, addr1, addr2, addr3] = await ethers.getSigners();

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
			owner.address,
			[2, 2, 5] as UpdateVaultProperty
		);

		// Deploy a vault
		await yieldSyncV1VaultFactory.deployYieldSyncV1Vault(
			ethers.constants.AddressZero,
			yieldSyncV1ATransferRequestProtocol.address,
			[owner.address],
			[addr1.address, addr2.address, addr3.address],
			{ value: 1 }
		);

		// Attach the deployed vault's address
		yieldSyncV1Vault = await YieldSyncV1Vault.attach(
			await yieldSyncV1VaultFactory.yieldSyncV1VaultId_yieldSyncV1Vault(0)
		);
	});

	describe("admin_yieldSyncV1Vaults()", async () => {
		it("Should have values set properly..", async () => {
			const [owner] = await ethers.getSigners();

			const admin_yieldSyncV1Vaults = await yieldSyncV1VaultAccessControl.admin_yieldSyncV1Vaultes(
				owner.address
			);

			expect(admin_yieldSyncV1Vaults.length).to.be.equal(1);
			expect(admin_yieldSyncV1Vaults[0]).to.be.equal(yieldSyncV1Vault.address);
		});
	});

	describe("yieldSyncV1Vault_admins()", async () => {
		it("Should have values set properly..", async () => {
			const [owner] = await ethers.getSigners();

			const yieldSyncV1Vault_admins = await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_admins(
				yieldSyncV1Vault.address
			);

			expect(yieldSyncV1Vault_admins.length).to.be.equal(1);
			expect(yieldSyncV1Vault_admins[0]).to.be.equal(owner.address);
		});
	});

	describe("yieldSyncV1Vault_members()", async () => {
		it("Should have values set properly..", async () => {
			const [, addr1, addr2, addr3] = await ethers.getSigners();

			const yieldSyncV1Vault_members = await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_members(
				yieldSyncV1Vault.address
			);

			expect(yieldSyncV1Vault_members.length).to.be.equal(3);
			expect(yieldSyncV1Vault_members[0]).to.be.equal(addr1.address);
			expect(yieldSyncV1Vault_members[1]).to.be.equal(addr2.address);
			expect(yieldSyncV1Vault_members[2]).to.be.equal(addr3.address);
		});
	});

	describe("member_yieldSyncV1Vaults()", async () => {
		it("Should have values set properly..", async () => {
			const [, addr1, addr2, addr3] = await ethers.getSigners();

			const addr1_member_yieldSyncV1Vaults = await yieldSyncV1VaultAccessControl.member_yieldSyncV1Vaultes(
				addr1.address
			);

			expect(addr1_member_yieldSyncV1Vaults.length).to.be.equal(1);
			expect(addr1_member_yieldSyncV1Vaults[0]).to.be.equal(yieldSyncV1Vault.address);

			const addr2_member_yieldSyncV1Vaults = await yieldSyncV1VaultAccessControl.member_yieldSyncV1Vaultes(
				addr2.address
			);

			expect(addr2_member_yieldSyncV1Vaults.length).to.be.equal(1);
			expect(addr2_member_yieldSyncV1Vaults[0]).to.be.equal(yieldSyncV1Vault.address);

			const addr3_member_yieldSyncV1Vaults = await yieldSyncV1VaultAccessControl.member_yieldSyncV1Vaultes(
				addr3.address
			);

			expect(addr3_member_yieldSyncV1Vaults.length).to.be.equal(1);
			expect(addr3_member_yieldSyncV1Vaults[0]).to.be.equal(yieldSyncV1Vault.address);
		});
	});

	describe("yieldSyncV1Vault_participant_access()", async () => {
		it("Should have values set properly..", async () => {
			const [owner, addr1, addr2, addr3] = await ethers.getSigners();

			// owner admin
			expect(
				(await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_participant_access(
					yieldSyncV1Vault.address,
					owner.address,
				))[0]
			).to.be.true

			// owner member
			expect(
				(await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_participant_access(
					yieldSyncV1Vault.address,
					owner.address,
				))[1]
			).to.be.false

			// addr1 admin
			expect(
				(await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_participant_access(
					yieldSyncV1Vault.address,
					addr1.address,
				))[0]
			).to.be.false

			// addr1 member
			expect(
				(await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_participant_access(
					yieldSyncV1Vault.address,
					addr1.address,
				))[1]
			).to.be.true

			// addr2 admin
			expect(
				(await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_participant_access(
					yieldSyncV1Vault.address,
					addr2.address,
				))[0]
			).to.be.false

			// addr2 member
			expect(
				(await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_participant_access(
					yieldSyncV1Vault.address,
					addr2.address,
				))[1]
			).to.be.true

			// addr3 admin
			expect(
				(await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_participant_access(
					yieldSyncV1Vault.address,
					addr3.address,
				))[0]
			).to.be.false

			// addr3 member
			expect(
				(await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_participant_access(
					yieldSyncV1Vault.address,
					addr3.address,
				))[1]
			).to.be.true
		});
	});

	describe("adminAdd()", async () => {
		it(
			"Should revert when unauthorized msg.sender calls..",
			async () => {
				const [, addr1] = await ethers.getSigners();

				await expect(
					yieldSyncV1Vault.connect(addr1).adminAdd(ethers.constants.AddressZero)
				).to.be.rejectedWith("!admin");
			}
		);

		it("Should be able to add Admin properly..", async () => {
			const [, , , , addr4] = await ethers.getSigners();

			await yieldSyncV1Vault.adminAdd(addr4.address);

			const yieldSyncV1Vault_admins = await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_admins(
				yieldSyncV1Vault.address
			);

			expect(yieldSyncV1Vault_admins.length).to.be.equal(2);
			expect(yieldSyncV1Vault_admins[1]).to.be.equal(addr4.address);
		});

		it("Should not be able to double add..", async () => {
			const [, , , , addr4] = await ethers.getSigners();

			await yieldSyncV1Vault.adminAdd(addr4.address)

			await expect(yieldSyncV1Vault.adminAdd(addr4.address)).to.be.rejectedWith("Already admin");
		});
	});

	describe("adminRemove()", async () => {
		it(
			"Should revert when unauthorized msg.sender calls..",
			async () => {
				const [, addr1] = await ethers.getSigners();

				await expect(
					yieldSyncV1Vault.connect(addr1).adminRemove(ethers.constants.AddressZero)
				).to.be.rejectedWith("!admin");
			}
		);

		it("Should be able to remove Admin properly..", async () => {
			const [, , , , addr4] = await ethers.getSigners();

			await yieldSyncV1Vault.adminAdd(addr4.address)

			await yieldSyncV1Vault.adminRemove(addr4.address);

			// admin_yieldSyncV1Vaults
			const admin_yieldSyncV1Vaults = await yieldSyncV1VaultAccessControl.admin_yieldSyncV1Vaultes(
				addr4.address
			);

			expect(admin_yieldSyncV1Vaults.length).to.be.equal(0);

			for (let i = 0; i < admin_yieldSyncV1Vaults.length; i++) {
				const vault = admin_yieldSyncV1Vaults[i];

				expect(vault).to.not.equal(yieldSyncV1Vault.address);
			}

			// yieldSyncV1Vault_admins
			const yieldSyncV1Vault_admins = await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_admins(
				yieldSyncV1Vault.address
			);

			expect(yieldSyncV1Vault_admins.length).to.be.equal(1);

			for (let i = 0; i < yieldSyncV1Vault_admins.length; i++) {
				const admin = yieldSyncV1Vault_admins[i];

				expect(admin).to.not.equal(addr4.address);
			}
		});
	});

	describe("memberAdd()", async () => {
		it(
			"Should revert when unauthorized msg.sender calls..",
			async () => {
				const [, addr1] = await ethers.getSigners();

				await expect(
					yieldSyncV1Vault.connect(addr1).memberAdd(ethers.constants.AddressZero)
				).to.be.rejectedWith("!admin");
			}
		);

		it("Should be able to add Admin properly..", async () => {
			const [, , , , addr4] = await ethers.getSigners();

			await yieldSyncV1Vault.memberAdd(addr4.address);

			const yieldSyncV1Vault_members = await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_members(
				yieldSyncV1Vault.address
			);

			expect(yieldSyncV1Vault_members.length).to.be.equal(4);
		});

		it("Should not be able to double add..", async () => {
			const [, , , , addr4] = await ethers.getSigners();

			await yieldSyncV1Vault.memberAdd(addr4.address)

			await expect(yieldSyncV1Vault.memberAdd(addr4.address)).to.be.rejectedWith("Already member");
		});
	});

	describe("memberRemove()", async () => {
		it(
			"Should revert when unauthorized msg.sender calls..",
			async () => {
				const [, addr1] = await ethers.getSigners();

				await expect(
					yieldSyncV1Vault.connect(addr1).memberRemove(ethers.constants.AddressZero)
				).to.be.rejectedWith("!admin");
			}
		);

		it("Should be able to remove Admin properly..", async () => {
			const [, , addr2] = await ethers.getSigners();

			await yieldSyncV1Vault.memberRemove(addr2.address);

			// member_yieldSyncV1Vaults
			const member_yieldSyncV1Vaults = await yieldSyncV1VaultAccessControl.member_yieldSyncV1Vaultes(
				addr2.address
			);

			expect(member_yieldSyncV1Vaults.length).to.be.equal(0);

			for (let i = 0; i < member_yieldSyncV1Vaults.length; i++) {
				const vault = member_yieldSyncV1Vaults[i];

				expect(vault).to.not.equal(yieldSyncV1Vault.address);
			}

			// yieldSyncV1Vault_members
			const yieldSyncV1Vault_members = await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_members(
				yieldSyncV1Vault.address
			);

			expect(yieldSyncV1Vault_members.length).to.be.equal(2);

			for (let i = 0; i < yieldSyncV1Vault_members.length; i++) {
				const member = yieldSyncV1Vault_members[i];

				expect(member).to.not.equal(addr2.address);
			}
		});
	});
});
