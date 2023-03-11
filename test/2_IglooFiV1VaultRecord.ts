import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";

const { ethers } = require("hardhat");


const stageContracts = async () => {
	const [owner, addr1, addr2, addr3] = await ethers.getSigners();

	const IglooFiV1Vault: ContractFactory = await ethers.getContractFactory("IglooFiV1Vault");
	const IglooFiV1VaultFactory: ContractFactory = await ethers.getContractFactory("IglooFiV1VaultFactory");
	const IglooFiV1VaultRecord: ContractFactory = await ethers.getContractFactory("IglooFiV1VaultRecord");
	const MockAdmin: ContractFactory = await ethers.getContractFactory("MockAdmin");
	const MockERC20: ContractFactory = await ethers.getContractFactory("MockERC20");
	const MockERC721: ContractFactory = await ethers.getContractFactory("MockERC721");
	const MockIglooFiGovernance: ContractFactory = await ethers.getContractFactory("MockIglooFiGovernance");
	const SignatureManager: ContractFactory = await ethers.getContractFactory("SignatureManager");

	const mockIglooFiGovernance: Contract = await (await MockIglooFiGovernance.deploy()).deployed();
	const iglooFiV1VaultRecord: Contract = await (await IglooFiV1VaultRecord.deploy()).deployed();
	const iglooFiV1VaultFactory: Contract = await (
		await IglooFiV1VaultFactory.deploy(mockIglooFiGovernance.address, iglooFiV1VaultRecord.address)
	).deployed();

	// Deploy a vault
	await iglooFiV1VaultFactory.deployIglooFiV1Vault(
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
	const iglooFiV1Vault: Contract = await IglooFiV1Vault.attach(
		await iglooFiV1VaultFactory.iglooFiV1VaultIdToAddress(0)
	);

	const signatureManager: Contract = await (
		await SignatureManager.deploy(mockIglooFiGovernance.address, iglooFiV1VaultRecord.address)
	).deployed();
	const mockAdmin: Contract = await (await MockAdmin.deploy()).deployed();
	const mockERC20: Contract = await (await MockERC20.deploy()).deployed();
	const mockERC721: Contract = await (await MockERC721.deploy()).deployed();

	return {
		iglooFiV1Vault,
		iglooFiV1VaultFactory,
		iglooFiV1VaultRecord,
		signatureManager,
		mockAdmin,
		mockERC20,
		mockERC721,
		mockIglooFiGovernance
	};
};


describe("[2] IglooFiV1VaultRecord.sol - IglooFi V1 Vault Record Contract", async () => {
	let iglooFiV1Vault: Contract;
	let iglooFiV1VaultFactory: Contract;
	let iglooFiV1VaultRecord: Contract;
	let signatureManager: Contract;
	let mockAdmin: Contract;
	let mockERC20: Contract;
	let mockERC721: Contract;
	let mockIglooFiGovernance: Contract;


	before("[before] Set up contracts..", async () => {
		const stagedContracts = await stageContracts();

		iglooFiV1Vault = stagedContracts.iglooFiV1Vault
		iglooFiV1VaultFactory = stagedContracts.iglooFiV1VaultFactory
		iglooFiV1VaultRecord = stagedContracts.iglooFiV1VaultRecord
		signatureManager = stagedContracts.signatureManager
		mockAdmin = stagedContracts.mockAdmin
		mockERC20 = stagedContracts.mockERC20
		mockERC721 = stagedContracts.mockERC721
		mockIglooFiGovernance = stagedContracts.mockIglooFiGovernance;
	});

	describe("admin_iglooFiV1Vaults()", async () => {
		it("Should have values set properly..", async () => {
			const [owner] = await ethers.getSigners();

			const admin_iglooFiV1Vaults = await iglooFiV1VaultRecord.admin_iglooFiV1Vaults(owner.address);

			expect(admin_iglooFiV1Vaults.length).to.be.equal(1);
			expect(admin_iglooFiV1Vaults[0]).to.be.equal(iglooFiV1Vault.address);
		});
	});

	describe("iglooFiV1Vault_admins()", async () => {
		it("Should have values set properly..", async () => {
			const [owner] = await ethers.getSigners();

			const iglooFiV1Vault_admins = await iglooFiV1VaultRecord.iglooFiV1Vault_admins(iglooFiV1Vault.address);

			expect(iglooFiV1Vault_admins.length).to.be.equal(1);
			expect(iglooFiV1Vault_admins[0]).to.be.equal(owner.address);
		});
	});

	describe("iglooFiV1Vault_members()", async () => {
		it("Should have values set properly..", async () => {
			const [, addr1, addr2, addr3] = await ethers.getSigners();

			const iglooFiV1Vault_members = await iglooFiV1VaultRecord.iglooFiV1Vault_members(iglooFiV1Vault.address);

			expect(iglooFiV1Vault_members.length).to.be.equal(3);
			expect(iglooFiV1Vault_members[0]).to.be.equal(addr1.address);
			expect(iglooFiV1Vault_members[1]).to.be.equal(addr2.address);
			expect(iglooFiV1Vault_members[2]).to.be.equal(addr3.address);
		});
	});

	describe("member_iglooFiV1Vaults()", async () => {
		it("Should have values set properly..", async () => {
			const [, addr1, addr2, addr3] = await ethers.getSigners();

			const addr1_member_iglooFiV1Vaults = await iglooFiV1VaultRecord.member_iglooFiV1Vaults(addr1.address);

			expect(addr1_member_iglooFiV1Vaults.length).to.be.equal(1);
			expect(addr1_member_iglooFiV1Vaults[0]).to.be.equal(iglooFiV1Vault.address);

			const addr2_member_iglooFiV1Vaults = await iglooFiV1VaultRecord.member_iglooFiV1Vaults(addr2.address);

			expect(addr2_member_iglooFiV1Vaults.length).to.be.equal(1);
			expect(addr2_member_iglooFiV1Vaults[0]).to.be.equal(iglooFiV1Vault.address);

			const addr3_member_iglooFiV1Vaults = await iglooFiV1VaultRecord.member_iglooFiV1Vaults(addr3.address);

			expect(addr3_member_iglooFiV1Vaults.length).to.be.equal(1);
			expect(addr3_member_iglooFiV1Vaults[0]).to.be.equal(iglooFiV1Vault.address);
		});
	});

	describe("participant_iglooFiV1Vault_access()", async () => {
		it("Should have values set properly..", async () => {
			const [owner, addr1, addr2, addr3] = await ethers.getSigners();

			// owner admin
			expect(
				(await iglooFiV1VaultRecord.participant_iglooFiV1Vault_access(owner.address, iglooFiV1Vault.address))[0]
			).to.be.true

			// owner member
			expect(
				(await iglooFiV1VaultRecord.participant_iglooFiV1Vault_access(owner.address, iglooFiV1Vault.address))[1]
			).to.be.false

			// addr1 admin
			expect(
				(await iglooFiV1VaultRecord.participant_iglooFiV1Vault_access(addr1.address, iglooFiV1Vault.address))[0]
			).to.be.false

			// addr1 member
			expect(
				(await iglooFiV1VaultRecord.participant_iglooFiV1Vault_access(addr1.address, iglooFiV1Vault.address))[1]
			).to.be.true

			// addr2 admin
			expect(
				(await iglooFiV1VaultRecord.participant_iglooFiV1Vault_access(addr2.address, iglooFiV1Vault.address))[0]
			).to.be.false

			// addr2 member
			expect(
				(await iglooFiV1VaultRecord.participant_iglooFiV1Vault_access(addr2.address, iglooFiV1Vault.address))[1]
			).to.be.true

			// addr3 admin
			expect(
				(await iglooFiV1VaultRecord.participant_iglooFiV1Vault_access(addr3.address, iglooFiV1Vault.address))[0]
			).to.be.false

			// addr3 member
			expect(
				(await iglooFiV1VaultRecord.participant_iglooFiV1Vault_access(addr3.address, iglooFiV1Vault.address))[1]
			).to.be.true
		});
	});

	describe("addAdmin()", async () => {
		it(
			"Should revert when unauthorized msg.sender calls..",
			async () => {
				const [, addr1] = await ethers.getSigners();

				await expect(
					iglooFiV1Vault.connect(addr1).addAdmin(ethers.constants.AddressZero)
				).to.be.rejectedWith("!admin");
			}
		);

		it("Should be able to add Admin properly..", async () => {
			const [, , , , addr4] = await ethers.getSigners();

			await iglooFiV1Vault.addAdmin(addr4.address);

			const iglooFiV1Vault_admins = await iglooFiV1VaultRecord.iglooFiV1Vault_admins(iglooFiV1Vault.address);

			expect(iglooFiV1Vault_admins.length).to.be.equal(2);
			expect(iglooFiV1Vault_admins[1]).to.be.equal(addr4.address);
		});

		it("Should not be able to double add..", async () => {
			const [, , , , addr4] = await ethers.getSigners();

			await expect(iglooFiV1Vault.addAdmin(addr4.address)).to.be.rejectedWith("Already admin");
		});
	});

	describe("removeAdmin()", async () => {
		it(
			"Should revert when unauthorized msg.sender calls..",
			async () => {
				const [, addr1] = await ethers.getSigners();

				await expect(
					iglooFiV1Vault.connect(addr1).removeAdmin(ethers.constants.AddressZero)
				).to.be.rejectedWith("!admin");
			}
		);

		it("Should be able to remove Admin properly..", async () => {
			const [, , , , addr4] = await ethers.getSigners();

			await iglooFiV1Vault.removeAdmin(addr4.address);

			// admin_iglooFiV1Vaults
			const admin_iglooFiV1Vaults = await iglooFiV1VaultRecord.admin_iglooFiV1Vaults(addr4.address);

			expect(admin_iglooFiV1Vaults.length).to.be.equal(0);

			for (let i = 0; i < admin_iglooFiV1Vaults.length; i++) {
				const vault = admin_iglooFiV1Vaults[i];

				expect(vault).to.not.equal(iglooFiV1Vault.address);
			}

			// iglooFiV1Vault_admins
			const iglooFiV1Vault_admins = await iglooFiV1VaultRecord.iglooFiV1Vault_admins(iglooFiV1Vault.address);

			expect(iglooFiV1Vault_admins.length).to.be.equal(1);

			for (let i = 0; i < iglooFiV1Vault_admins.length; i++) {
				const admin = iglooFiV1Vault_admins[i];

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
					iglooFiV1Vault.connect(addr1).addMember(ethers.constants.AddressZero)
				).to.be.rejectedWith("!admin");
			}
		);

		it("Should be able to add Admin properly..", async () => {
			const [, , , , addr4] = await ethers.getSigners();

			await iglooFiV1Vault.addMember(addr4.address);

			const iglooFiV1Vault_members = await iglooFiV1VaultRecord.iglooFiV1Vault_members(iglooFiV1Vault.address);

			expect(iglooFiV1Vault_members.length).to.be.equal(4);
		});

		it("Should not be able to double add..", async () => {
			const [, , , , addr4] = await ethers.getSigners();

			await expect(iglooFiV1Vault.addMember(addr4.address)).to.be.rejectedWith("Already member");
		});
	});

	describe("removeMember()", async () => {
		it(
			"Should revert when unauthorized msg.sender calls..",
			async () => {
				const [, addr1] = await ethers.getSigners();

				await expect(
					iglooFiV1Vault.connect(addr1).removeMember(ethers.constants.AddressZero)
				).to.be.rejectedWith("!admin");
			}
		);

		it("Should be able to remove Admin properly..", async () => {
			const [, , addr2] = await ethers.getSigners();

			await iglooFiV1Vault.removeMember(addr2.address);

			// member_iglooFiV1Vaults
			const member_iglooFiV1Vaults = await iglooFiV1VaultRecord.member_iglooFiV1Vaults(addr2.address);

			expect(member_iglooFiV1Vaults.length).to.be.equal(0);

			for (let i = 0; i < member_iglooFiV1Vaults.length; i++) {
				const vault = member_iglooFiV1Vaults[i];

				expect(vault).to.not.equal(iglooFiV1Vault.address);
			}

			// iglooFiV1Vault_members
			const iglooFiV1Vault_members = await iglooFiV1VaultRecord.iglooFiV1Vault_members(iglooFiV1Vault.address);

			expect(iglooFiV1Vault_members.length).to.be.equal(3);

			for (let i = 0; i < iglooFiV1Vault_members.length; i++) {
				const member = iglooFiV1Vault_members[i];

				expect(member).to.not.equal(addr2.address);
			}
		});
	});
});
