import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";

const { ethers } = require("hardhat");


const stageContracts = async () => {
	const [owner, addr1, addr2, addr3] = await ethers.getSigners();

	const YieldSyncV1Vault: ContractFactory = await ethers.getContractFactory("YieldSyncV1Vault");
	const YieldSyncV1VaultFactory: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultFactory");
	const YieldSyncV1VaultRecord: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultRecord");
	const MockAdmin: ContractFactory = await ethers.getContractFactory("MockAdmin");
	const MockERC20: ContractFactory = await ethers.getContractFactory("MockERC20");
	const MockERC721: ContractFactory = await ethers.getContractFactory("MockERC721");
	const MockYieldSyncGovernance: ContractFactory = await ethers.getContractFactory("MockYieldSyncGovernance");
	const SignatureManager: ContractFactory = await ethers.getContractFactory("SignatureManager");

	const mockYieldSyncGovernance: Contract = await (await MockYieldSyncGovernance.deploy()).deployed();
	const yieldSyncV1VaultRecord: Contract = await (await YieldSyncV1VaultRecord.deploy()).deployed();
	const yieldSyncV1VaultFactory: Contract = await (
		await YieldSyncV1VaultFactory.deploy(mockYieldSyncGovernance.address, yieldSyncV1VaultRecord.address)
	).deployed();

	// Deploy a vault
	await yieldSyncV1VaultFactory.deployYieldSyncV1Vault(
		owner.address,
		[addr1.address, addr2.address, addr3.address],
		ethers.constants.AddressZero,
		true,
		2,
		2,
		5,
		{ value: 1 }
	);

	// Attach the deployed vault's address
	const yieldSyncV1Vault: Contract = await YieldSyncV1Vault.attach(
		await yieldSyncV1VaultFactory.yieldSyncV1VaultIdToAddress(0)
	);

	const signatureManager: Contract = await (
		await SignatureManager.deploy(mockYieldSyncGovernance.address, yieldSyncV1VaultRecord.address)
	).deployed();
	const mockAdmin: Contract = await (await MockAdmin.deploy()).deployed();
	const mockERC20: Contract = await (await MockERC20.deploy()).deployed();
	const mockERC721: Contract = await (await MockERC721.deploy()).deployed();

	return {
		yieldSyncV1Vault,
		yieldSyncV1VaultFactory,
		yieldSyncV1VaultRecord,
		signatureManager,
		mockAdmin,
		mockERC20,
		mockERC721,
		mockYieldSyncGovernance
	};
};


describe("[2] YieldSyncV1VaultRecord.sol - YieldSync V1 Vault Record Contract", async () => {
	let yieldSyncV1Vault: Contract;
	let yieldSyncV1VaultFactory: Contract;
	let yieldSyncV1VaultRecord: Contract;
	let signatureManager: Contract;
	let mockAdmin: Contract;
	let mockERC20: Contract;
	let mockERC721: Contract;
	let mockYieldSyncGovernance: Contract;


	before("[before] Set up contracts..", async () => {
		const stagedContracts = await stageContracts();

		yieldSyncV1Vault = stagedContracts.yieldSyncV1Vault
		yieldSyncV1VaultFactory = stagedContracts.yieldSyncV1VaultFactory
		yieldSyncV1VaultRecord = stagedContracts.yieldSyncV1VaultRecord
		signatureManager = stagedContracts.signatureManager
		mockAdmin = stagedContracts.mockAdmin
		mockERC20 = stagedContracts.mockERC20
		mockERC721 = stagedContracts.mockERC721
		mockYieldSyncGovernance = stagedContracts.mockYieldSyncGovernance;
	});

	describe("admin_yieldSyncV1Vaults()", async () => {
		it("Should have values set properly..", async () => {
			const [owner] = await ethers.getSigners();

			const admin_yieldSyncV1Vaults = await yieldSyncV1VaultRecord.admin_yieldSyncV1Vaults(owner.address);

			expect(admin_yieldSyncV1Vaults.length).to.be.equal(1);
			expect(admin_yieldSyncV1Vaults[0]).to.be.equal(yieldSyncV1Vault.address);
		});
	});

	describe("yieldSyncV1Vault_admins()", async () => {
		it("Should have values set properly..", async () => {
			const [owner] = await ethers.getSigners();

			const yieldSyncV1Vault_admins = await yieldSyncV1VaultRecord.yieldSyncV1Vault_admins(yieldSyncV1Vault.address);

			expect(yieldSyncV1Vault_admins.length).to.be.equal(1);
			expect(yieldSyncV1Vault_admins[0]).to.be.equal(owner.address);
		});
	});

	describe("yieldSyncV1Vault_members()", async () => {
		it("Should have values set properly..", async () => {
			const [, addr1, addr2, addr3] = await ethers.getSigners();

			const yieldSyncV1Vault_members = await yieldSyncV1VaultRecord.yieldSyncV1Vault_members(yieldSyncV1Vault.address);

			expect(yieldSyncV1Vault_members.length).to.be.equal(3);
			expect(yieldSyncV1Vault_members[0]).to.be.equal(addr1.address);
			expect(yieldSyncV1Vault_members[1]).to.be.equal(addr2.address);
			expect(yieldSyncV1Vault_members[2]).to.be.equal(addr3.address);
		});
	});

	describe("member_yieldSyncV1Vaults()", async () => {
		it("Should have values set properly..", async () => {
			const [, addr1, addr2, addr3] = await ethers.getSigners();

			const addr1_member_yieldSyncV1Vaults = await yieldSyncV1VaultRecord.member_yieldSyncV1Vaults(addr1.address);

			expect(addr1_member_yieldSyncV1Vaults.length).to.be.equal(1);
			expect(addr1_member_yieldSyncV1Vaults[0]).to.be.equal(yieldSyncV1Vault.address);

			const addr2_member_yieldSyncV1Vaults = await yieldSyncV1VaultRecord.member_yieldSyncV1Vaults(addr2.address);

			expect(addr2_member_yieldSyncV1Vaults.length).to.be.equal(1);
			expect(addr2_member_yieldSyncV1Vaults[0]).to.be.equal(yieldSyncV1Vault.address);

			const addr3_member_yieldSyncV1Vaults = await yieldSyncV1VaultRecord.member_yieldSyncV1Vaults(addr3.address);

			expect(addr3_member_yieldSyncV1Vaults.length).to.be.equal(1);
			expect(addr3_member_yieldSyncV1Vaults[0]).to.be.equal(yieldSyncV1Vault.address);
		});
	});

	describe("participant_yieldSyncV1Vault_access()", async () => {
		it("Should have values set properly..", async () => {
			const [owner, addr1, addr2, addr3] = await ethers.getSigners();

			// owner admin
			expect(
				(await yieldSyncV1VaultRecord.participant_yieldSyncV1Vault_access(owner.address, yieldSyncV1Vault.address))[0]
			).to.be.true

			// owner member
			expect(
				(await yieldSyncV1VaultRecord.participant_yieldSyncV1Vault_access(owner.address, yieldSyncV1Vault.address))[1]
			).to.be.false

			// addr1 admin
			expect(
				(await yieldSyncV1VaultRecord.participant_yieldSyncV1Vault_access(addr1.address, yieldSyncV1Vault.address))[0]
			).to.be.false

			// addr1 member
			expect(
				(await yieldSyncV1VaultRecord.participant_yieldSyncV1Vault_access(addr1.address, yieldSyncV1Vault.address))[1]
			).to.be.true

			// addr2 admin
			expect(
				(await yieldSyncV1VaultRecord.participant_yieldSyncV1Vault_access(addr2.address, yieldSyncV1Vault.address))[0]
			).to.be.false

			// addr2 member
			expect(
				(await yieldSyncV1VaultRecord.participant_yieldSyncV1Vault_access(addr2.address, yieldSyncV1Vault.address))[1]
			).to.be.true

			// addr3 admin
			expect(
				(await yieldSyncV1VaultRecord.participant_yieldSyncV1Vault_access(addr3.address, yieldSyncV1Vault.address))[0]
			).to.be.false

			// addr3 member
			expect(
				(await yieldSyncV1VaultRecord.participant_yieldSyncV1Vault_access(addr3.address, yieldSyncV1Vault.address))[1]
			).to.be.true
		});
	});

	describe("addAdmin()", async () => {
		it(
			"Should revert when unauthorized msg.sender calls..",
			async () => {
				const [, addr1] = await ethers.getSigners();

				await expect(
					yieldSyncV1Vault.connect(addr1).addAdmin(ethers.constants.AddressZero)
				).to.be.rejectedWith("!admin");
			}
		);

		it("Should be able to add Admin properly..", async () => {
			const [, , , , addr4] = await ethers.getSigners();

			await yieldSyncV1Vault.addAdmin(addr4.address);

			const yieldSyncV1Vault_admins = await yieldSyncV1VaultRecord.yieldSyncV1Vault_admins(yieldSyncV1Vault.address);

			expect(yieldSyncV1Vault_admins.length).to.be.equal(2);
			expect(yieldSyncV1Vault_admins[1]).to.be.equal(addr4.address);
		});

		it("Should not be able to double add..", async () => {
			const [, , , , addr4] = await ethers.getSigners();

			await expect(yieldSyncV1Vault.addAdmin(addr4.address)).to.be.rejectedWith("Already admin");
		});
	});

	describe("removeAdmin()", async () => {
		it(
			"Should revert when unauthorized msg.sender calls..",
			async () => {
				const [, addr1] = await ethers.getSigners();

				await expect(
					yieldSyncV1Vault.connect(addr1).removeAdmin(ethers.constants.AddressZero)
				).to.be.rejectedWith("!admin");
			}
		);

		it("Should be able to remove Admin properly..", async () => {
			const [, , , , addr4] = await ethers.getSigners();

			await yieldSyncV1Vault.removeAdmin(addr4.address);

			// admin_yieldSyncV1Vaults
			const admin_yieldSyncV1Vaults = await yieldSyncV1VaultRecord.admin_yieldSyncV1Vaults(addr4.address);

			expect(admin_yieldSyncV1Vaults.length).to.be.equal(0);

			for (let i = 0; i < admin_yieldSyncV1Vaults.length; i++) {
				const vault = admin_yieldSyncV1Vaults[i];

				expect(vault).to.not.equal(yieldSyncV1Vault.address);
			}

			// yieldSyncV1Vault_admins
			const yieldSyncV1Vault_admins = await yieldSyncV1VaultRecord.yieldSyncV1Vault_admins(yieldSyncV1Vault.address);

			expect(yieldSyncV1Vault_admins.length).to.be.equal(1);

			for (let i = 0; i < yieldSyncV1Vault_admins.length; i++) {
				const admin = yieldSyncV1Vault_admins[i];

				expect(admin).to.not.equal(addr4.address);
			}
		});
	});

	describe("addMember()", async () => {
		it(
			"Should revert when unauthorized msg.sender calls..",
			async () => {
				const [, addr1] = await ethers.getSigners();

				await expect(
					yieldSyncV1Vault.connect(addr1).addMember(ethers.constants.AddressZero)
				).to.be.rejectedWith("!admin");
			}
		);

		it("Should be able to add Admin properly..", async () => {
			const [, , , , addr4] = await ethers.getSigners();

			await yieldSyncV1Vault.addMember(addr4.address);

			const yieldSyncV1Vault_members = await yieldSyncV1VaultRecord.yieldSyncV1Vault_members(yieldSyncV1Vault.address);

			expect(yieldSyncV1Vault_members.length).to.be.equal(4);
		});

		it("Should not be able to double add..", async () => {
			const [, , , , addr4] = await ethers.getSigners();

			await expect(yieldSyncV1Vault.addMember(addr4.address)).to.be.rejectedWith("Already member");
		});
	});

	describe("removeMember()", async () => {
		it(
			"Should revert when unauthorized msg.sender calls..",
			async () => {
				const [, addr1] = await ethers.getSigners();

				await expect(
					yieldSyncV1Vault.connect(addr1).removeMember(ethers.constants.AddressZero)
				).to.be.rejectedWith("!admin");
			}
		);

		it("Should be able to remove Admin properly..", async () => {
			const [, , addr2] = await ethers.getSigners();

			await yieldSyncV1Vault.removeMember(addr2.address);

			// member_yieldSyncV1Vaults
			const member_yieldSyncV1Vaults = await yieldSyncV1VaultRecord.member_yieldSyncV1Vaults(addr2.address);

			expect(member_yieldSyncV1Vaults.length).to.be.equal(0);

			for (let i = 0; i < member_yieldSyncV1Vaults.length; i++) {
				const vault = member_yieldSyncV1Vaults[i];

				expect(vault).to.not.equal(yieldSyncV1Vault.address);
			}

			// yieldSyncV1Vault_members
			const yieldSyncV1Vault_members = await yieldSyncV1VaultRecord.yieldSyncV1Vault_members(yieldSyncV1Vault.address);

			expect(yieldSyncV1Vault_members.length).to.be.equal(3);

			for (let i = 0; i < yieldSyncV1Vault_members.length; i++) {
				const member = yieldSyncV1Vault_members[i];

				expect(member).to.not.equal(addr2.address);
			}
		});
	});
});
