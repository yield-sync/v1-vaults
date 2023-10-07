const { ethers } = require("hardhat");


import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";


const secondsIn6Days = 24 * 60 * 60 * 6;


describe("[1.0] YieldSyncV1Vault.sol", async () => {
	let mockAdmin: Contract;
	let mockERC20: Contract;
	let mockERC721: Contract;

	let yieldSyncV1Vault: Contract;
	let yieldSyncV1VaultRegistry: Contract;
	let yieldSyncV1VaultDeployer: Contract;
	let mockYieldSyncGovernance: Contract;


	beforeEach("[beforeEach] Set up contracts..", async () => {
		const [owner, addr1] = await ethers.getSigners();


		// Contract Deployer
		const MockAdmin: ContractFactory = await ethers.getContractFactory("MockAdmin");
		const MockERC20: ContractFactory = await ethers.getContractFactory("MockERC20");
		const MockERC721: ContractFactory = await ethers.getContractFactory("MockERC721");
		const MockYieldSyncGovernance: ContractFactory = await ethers.getContractFactory("MockYieldSyncGovernance");

		const YieldSyncV1Vault: ContractFactory = await ethers.getContractFactory("YieldSyncV1Vault");
		const YieldSyncV1VaultDeployer: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultDeployer");
		const YieldSyncV1VaultRegistry: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultRegistry");


		/// Mock
		// Governance and test contracts
		mockAdmin = await (await MockAdmin.deploy()).deployed();
		mockERC20 = await (await MockERC20.deploy()).deployed();
		mockERC721 = await (await MockERC721.deploy()).deployed();
		mockYieldSyncGovernance = await (await MockYieldSyncGovernance.deploy()).deployed();

		/// Core
		// Deploy YieldSyncV1VaultRegistry
		yieldSyncV1VaultRegistry = await (await YieldSyncV1VaultRegistry.deploy()).deployed();
		// Deploy YieldSyncV1VaultDeployer
		yieldSyncV1VaultDeployer = await (
			await YieldSyncV1VaultDeployer.deploy(mockYieldSyncGovernance.address, yieldSyncV1VaultRegistry.address)
		).deployed();

		// Deploy a vault
		await yieldSyncV1VaultDeployer.deployYieldSyncV1Vault(
			ethers.constants.AddressZero,
			ethers.constants.AddressZero,
			[owner.address],
			[addr1.address],
			{ value: 1 }
		);

		// Attach the deployed vault's address
		yieldSyncV1Vault = await YieldSyncV1Vault.attach(
			await yieldSyncV1VaultDeployer.yieldSyncV1VaultId_yieldSyncV1Vault(0)
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


	describe("Receiving tokens & ethers", async () => {
		it(
			"Should be able to receive ether..",
			async () => {
				await expect(
					await ethers.provider.getBalance(yieldSyncV1Vault.address)
				).to.be.greaterThanOrEqual(ethers.utils.parseEther(".5"));
			}
		);

		it(
			"Should be able to receive ERC20 tokens..",
			async () => {
				expect(await mockERC20.balanceOf(yieldSyncV1Vault.address)).to.equal(50);
			}
		);

		it(
			"Should be able to receive ERC721 tokens..",
			async () => {
				expect(await mockERC721.balanceOf(yieldSyncV1Vault.address)).to.equal(1);
			}
		);
	});


	describe("[yieldSyncV1Vault] Initial Values", async () => {
		it(
			"Should have admin set properly..",
			async () => {
				const [owner] = await ethers.getSigners();

				const access: Access = await yieldSyncV1VaultRegistry.yieldSyncV1Vault_participant_access(
					yieldSyncV1Vault.address,
					owner.address,
				);

				expect(access.admin).to.be.true;

				expect(
					(await yieldSyncV1VaultRegistry.yieldSyncV1Vault_admins(yieldSyncV1Vault.address))[0]
				).to.be.equal(owner.address);

				expect(
					(await yieldSyncV1VaultRegistry.admin_yieldSyncV1Vaults(owner.address))[0]
				).to.be.equal(yieldSyncV1Vault.address);
			}
		);

		it(
			"Should have added members correctly..",
			async () => {
				const [, addr1] = await ethers.getSigners();

				const access: Access = await yieldSyncV1VaultRegistry.yieldSyncV1Vault_participant_access(
					yieldSyncV1Vault.address,
					addr1.address,
				);

				expect(access.member).to.be.true;

				expect(
					(await yieldSyncV1VaultRegistry.yieldSyncV1Vault_members(yieldSyncV1Vault.address))[0]
				).to.be.equal(addr1.address);

				expect(
					(await yieldSyncV1VaultRegistry.member_yieldSyncV1Vaults(addr1.address))[0]
				).to.be.equal(yieldSyncV1Vault.address);
			}
		);
	});


	describe("Restriction: admin (1/1)", async () => {
		describe("adminAdd()", async () => {
			it(
				"Should allow admin to add another admin..",
				async () => {
					const [, , , , addr4] = await ethers.getSigners();

					await yieldSyncV1Vault.adminAdd(addr4.address);

					const access: Access = await yieldSyncV1VaultRegistry.yieldSyncV1Vault_participant_access(
						yieldSyncV1Vault.address,
						addr4.address,
					);

					expect(access.admin).to.be.true;

					expect(
						(await yieldSyncV1VaultRegistry.admin_yieldSyncV1Vaults(addr4.address))[0]
					).to.be.equal(yieldSyncV1Vault.address);


					expect(
						(await yieldSyncV1VaultRegistry.yieldSyncV1Vault_admins(yieldSyncV1Vault.address))[1]
					).to.be.equal(addr4.address);
				}
			);

			it(
				"Should allow admin to add a contract-based admin..",
				async () => {
					await yieldSyncV1Vault.adminAdd(mockAdmin.address);

					const access: Access = await yieldSyncV1VaultRegistry.yieldSyncV1Vault_participant_access(
						yieldSyncV1Vault.address,
						mockAdmin.address,
					);

					expect(access.admin).to.be.true;

					expect(
						(await yieldSyncV1VaultRegistry.admin_yieldSyncV1Vaults(mockAdmin.address))[0]
					).to.be.equal(yieldSyncV1Vault.address);


					expect(
						(await yieldSyncV1VaultRegistry.yieldSyncV1Vault_admins(yieldSyncV1Vault.address))[1]
					).to.be.equal(mockAdmin.address);
				}
			);
		});

		describe("memberAdd()", async () => {
			it(
				"[auth] Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await expect(yieldSyncV1Vault.connect(addr1).memberAdd(addr2.address)).to.be.rejected;
				}
			);

			it(
				"Should NOT be able to set up MEMBER role for an address that already is member..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(yieldSyncV1Vault.memberAdd(addr1.address)).to.be.rejectedWith("Already member");
				}
			);

			it(
				"Should be able to set up MEMBER role for an address..",
				async () => {
					const [, , addr2] = await ethers.getSigners();

					await yieldSyncV1Vault.memberAdd(addr2.address);

					const access: Access = await yieldSyncV1VaultRegistry.yieldSyncV1Vault_participant_access(
						yieldSyncV1Vault.address,
						addr2.address,
					);

					expect(access.member).to.be.true;

					expect(
						(await yieldSyncV1VaultRegistry.member_yieldSyncV1Vaults(addr2.address))[0]
					).to.be.equal(yieldSyncV1Vault.address);


					expect(
						(await yieldSyncV1VaultRegistry.yieldSyncV1Vault_members(yieldSyncV1Vault.address))[1]
					).to.be.equal(addr2.address);
				}
			);
		});

		describe("memberRemove()", async () => {
			it(
				"[auth] Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(yieldSyncV1Vault.connect(addr1).memberRemove(addr1.address)).to.be.rejected;
				}
			);

			it(
				"Should be able to remove address from MEMBER role..",
				async () => {
					const [, , , , addr5] = await ethers.getSigners();

					await yieldSyncV1Vault.memberAdd(addr5.address)

					const access: Access = await yieldSyncV1VaultRegistry.yieldSyncV1Vault_participant_access(
						yieldSyncV1Vault.address,
						addr5.address,
					);

					expect(access.member).to.be.true;

					await yieldSyncV1Vault.memberRemove(addr5.address)

					const accessAfter: Access = await yieldSyncV1VaultRegistry.yieldSyncV1Vault_participant_access(
						yieldSyncV1Vault.address,
						addr5.address,
					);

					expect(accessAfter.member).to.be.false;
				}
			);
		});

		describe("signatureProtocolUpdate()", async () => {
			it(
				"[auth] Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					const MockSignatureProtocol: ContractFactory = await ethers.getContractFactory(
						"MockSignatureProtocol"
					);

					const mockSignatureProtocol = await (await MockSignatureProtocol.deploy()).deployed();

					await expect(
						yieldSyncV1Vault.connect(addr1).signatureProtocolUpdate(mockSignatureProtocol.address)
					).to.be.rejected;
				}
			);

			it(
				"Should allow Admin to set a signature manager contract..",
				async () => {
					const MockSignatureProtocol: ContractFactory = await ethers.getContractFactory(
						"MockSignatureProtocol"
					);

					const mockSignatureProtocol = await (await MockSignatureProtocol.deploy()).deployed();

					yieldSyncV1Vault.signatureProtocolUpdate(mockSignatureProtocol.address)

					expect(await yieldSyncV1Vault.signatureProtocol()).to.be.equal(mockSignatureProtocol.address);
				}
			);
		});

		describe("transferRequestProtocolUpdate()", async () => {
			it(
				"[auth] Should revert when unauthorized msg.sender calls..",
				async () => {
					const [admin, addr1] = await ethers.getSigners();

					const MockTransferRequestProtocol: ContractFactory = await ethers.getContractFactory(
						"MockTransferRequestProtocol"
					);

					const mockTransferRequestProtocol: Contract = await (await MockTransferRequestProtocol.deploy()).deployed();

					await expect(
						yieldSyncV1Vault.connect(addr1).transferRequestProtocolUpdate(mockTransferRequestProtocol.address)
					).to.be.rejected;
				}
			);

			it(
				"Should be able to set a transferRequestProtocol contract..",
				async () => {
					const [admin] = await ethers.getSigners();

					const MockTransferRequestProtocol: ContractFactory = await ethers.getContractFactory(
						"MockTransferRequestProtocol"
					);

					const mockTransferRequestProtocol: Contract = await (await MockTransferRequestProtocol.deploy()).deployed();


					await yieldSyncV1Vault.transferRequestProtocolUpdate(mockTransferRequestProtocol.address);

					expect(await yieldSyncV1Vault.transferRequestProtocol()).to.be.equal(
						mockTransferRequestProtocol.address
					);
				}
			);
		});
	});


	describe("Restriction: member (1/1)", async () => {
		describe("memberAdd()", async () => {
			it(
				"Should NOT allow member to add another member..",
				async () => {
					const [, addr1, , , addr4] = await ethers.getSigners();

					await expect(
						yieldSyncV1Vault.connect(addr1).memberAdd(addr4.address)
					).to.be.rejected;
				}
			);
		});

		describe("renounceMembership()", async () => {
			it(
				"Should allow members to leave a vault..",
				async () => {
					const [, , , , , , addr6] = await ethers.getSigners();

					await yieldSyncV1Vault.memberAdd(addr6.address);

					const vaultsBefore: string[] = await yieldSyncV1VaultRegistry.member_yieldSyncV1Vaults(
						addr6.address
					);

					let found: boolean = false;

					for (let i = 0; i < vaultsBefore.length; i++)
					{
						if (vaultsBefore[i] === yieldSyncV1Vault.address) found = true;
					}

					expect(found).to.be.true;

					await yieldSyncV1Vault.connect(addr6).renounceMembership();

					const vaultsAfter: string[] = await yieldSyncV1VaultRegistry.member_yieldSyncV1Vaults(
						addr6.address
					);

					for (let i = 0; i < vaultsAfter.length; i++)
					{
						expect(vaultsAfter[i]).to.not.equal(yieldSyncV1Vault.address);
					}
				}
			);
		});
	});
});
