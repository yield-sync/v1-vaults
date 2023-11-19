type VaultProperty = {
	transferDelaySeconds: number,
	voteAgainstRequired: number,
	voteForRequired: number,
};

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


describe("[0.0] YieldSyncV1VaultDeployer.sol", async () => {
	let yieldSyncV1VaultRegistry: Contract;
	let yieldSyncV1VaultDeployer: Contract;
	let yieldSyncV1ATransferRequestProtocol: Contract;
	let mockYieldSyncGovernance: Contract;
	let mockSignatureProtocol: Contract;

	beforeEach("[beforeEach] Set up contracts..", async () => {
		const [, addr1] = await ethers.getSigners();

		// Contract Deployer
		const YieldSyncV1VaultDeployer: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultDeployer");
		const YieldSyncV1VaultRegistry: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultRegistry");
		const MockYieldSyncGovernance: ContractFactory = await ethers.getContractFactory("MockYieldSyncGovernance");
		const MockSignatureProtocol: ContractFactory = await ethers.getContractFactory("MockSignatureProtocol");
		const YieldSyncV1ATransferRequestProtocol: ContractFactory = await ethers.getContractFactory("YieldSyncV1ATransferRequestProtocol");

		/// Mock
		// Governance and Registry
		mockYieldSyncGovernance = await (await MockYieldSyncGovernance.deploy()).deployed();

		/// Core
		// Deploy YieldSyncV1VaultRegistry
		yieldSyncV1VaultRegistry = await (await YieldSyncV1VaultRegistry.deploy()).deployed();
		// Deploy YieldSyncV1VaultDeployer
		yieldSyncV1VaultDeployer = await (
			await YieldSyncV1VaultDeployer.deploy(mockYieldSyncGovernance.address, yieldSyncV1VaultRegistry.address)
		).deployed();

		// Deploy YieldSyncV1ATransferRequestProtocol
		yieldSyncV1ATransferRequestProtocol = await (
			await YieldSyncV1ATransferRequestProtocol.deploy(yieldSyncV1VaultRegistry.address)
		).deployed();

		// Deploy mockSignatureProtocol
		mockSignatureProtocol = await (await MockSignatureProtocol.deploy()).deployed();

		// Send ether to YieldSyncV1VaultDeployer contract
		await addr1.sendTransaction({
			to: yieldSyncV1VaultDeployer.address,
			value: ethers.utils.parseEther("1"),
		});
	});

	describe("Receiving tokens & ethers", async () => {
		it(
			"Should be able to receive ether..",
			async () => {
				const [, addr1] = await ethers.getSigners();

				// Send ether to YieldSyncV1VaultDeployer contract
				await addr1.sendTransaction({
					to: yieldSyncV1VaultDeployer.address,
					value: ethers.utils.parseEther("1"),
				});

				await expect(
					await ethers.provider.getBalance(yieldSyncV1VaultDeployer.address)
				).to.be.greaterThanOrEqual(ethers.utils.parseEther("1"));
			}
		);
	});

	describe("Initial values", async () => {
		it(
			"Should initialize `yieldSyncGovernance` to `MockYieldSyncGovernance` address..",
			async () => {
				expect(await yieldSyncV1VaultDeployer.YieldSyncGovernance()).to.equal(mockYieldSyncGovernance.address);
			}
		);

		it(
			"Should initialize the `fee` to 0..",
			async () => {
				expect(await yieldSyncV1VaultDeployer.fee()).to.equal(0);
			}
		);
	});


	describe("Restriction: IYieldSyncGovernance DEFAULT_ADMIN_ROLE", async () => {
		describe("feeUpdate()", async () => {
			it(
				"[auth] Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(yieldSyncV1VaultDeployer.connect(addr1).feeUpdate(2)).to.be.rejectedWith("!auth");
				}
			);

			it(
				"Should update correctly..",
				async () => {
					await yieldSyncV1VaultDeployer.feeUpdate(1);

					expect(await yieldSyncV1VaultDeployer.fee()).to.equal(1);
				}
			);
		});

		describe("transferFunds()", async () => {
			it(
				"[auth] Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(
						yieldSyncV1VaultDeployer.connect(addr1).etherTransfer(addr1.address)
					).to.be.rejectedWith("!auth");
				}
			);

			it(
				"Should be able to transfer to an address..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					const balanceBefore = {
						addr1: parseFloat(
							ethers.utils.formatUnits(await ethers.provider.getBalance(addr1.address), "ether")
						),
						yieldSyncV1VaultDeployer: parseFloat(
							ethers.utils.formatUnits(
								await ethers.provider.getBalance(yieldSyncV1VaultDeployer.address),
								"ether"
							)
						)
					};

					await yieldSyncV1VaultDeployer.etherTransfer(addr1.address);

					const balanceAfter = {
						addr1: parseFloat(
							ethers.utils.formatUnits(await ethers.provider.getBalance(addr1.address), "ether")
						),
						yieldSyncV1VaultDeployer: parseFloat(
							ethers.utils.formatUnits(
								await ethers.provider.getBalance(yieldSyncV1VaultDeployer.address),
								"ether"
							)
						)
					};

					await expect(balanceAfter.addr1).to.be.equal(
						balanceBefore.addr1 + balanceBefore.yieldSyncV1VaultDeployer
					);
				}
			);
		});
	});


	describe("!Restriction", async () => {
		describe("YieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate()", async () => {
			it(
				"[auth] Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(
						yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
							addr1.address,
							[1, 1, 10] as UpdateVaultProperty
						)
					).to.be.rejectedWith("!admin && msg.sender != yieldSyncV1Vault");
				}
			);

			it(
				"Should be able to set _yieldSyncV1Vault_yieldSyncV1VaultProperty..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					// Preset
					await yieldSyncV1ATransferRequestProtocol.connect(
						addr1
					).yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
						addr1.address,
						[1, 1, 10] as UpdateVaultProperty
					);

					const vaultProperties: VaultProperty = await yieldSyncV1ATransferRequestProtocol
					.yieldSyncV1Vault_yieldSyncV1VaultProperty(
						addr1.address
					);

					expect(vaultProperties.voteForRequired).to.equal(BigInt(1));
					expect(vaultProperties.voteAgainstRequired).to.equal(BigInt(1));
					expect(vaultProperties.transferDelaySeconds).to.equal(BigInt(10));
				}
			);
		});

		describe("deployYieldSyncV1Vault()", async () => {
			it(
				"Should fail to deploy YieldSyncV1Vault.sol due to not enough msg.value..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await yieldSyncV1VaultDeployer.feeUpdate(ethers.utils.parseEther("1"));

					await expect(yieldSyncV1VaultDeployer.deployYieldSyncV1Vault(
						ethers.constants.AddressZero,
						yieldSyncV1ATransferRequestProtocol.address,
						[addr1.address],
						[addr1.address],
						{ value: ethers.utils.parseEther(".5") }
					)).to.be.rejectedWith("!msg.value");
				}
			);

			it(
				"Should fail to deploy YieldSyncV1Vault.sol due to not enough _againstVoteRequired..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await yieldSyncV1VaultDeployer.feeUpdate(ethers.utils.parseEther("1"));

					await expect(yieldSyncV1VaultDeployer.deployYieldSyncV1Vault(
						ethers.constants.AddressZero,
						yieldSyncV1ATransferRequestProtocol.address,
						[addr1.address],
						[addr1.address],
						{
							value: ethers.utils.parseEther("1")
						}
					)).to.be.rejectedWith();
				}
			);

			it(
				"Should be able to record deployed YieldSyncV1Vault.sol on YieldSyncV1VaultDeployer.sol..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					// Preset
					await yieldSyncV1ATransferRequestProtocol.connect(
						addr1
					).yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
						addr1.address,
						[1, 1, 10] as UpdateVaultProperty
					);

					const deployedObj = await yieldSyncV1VaultDeployer.connect(addr1).deployYieldSyncV1Vault(
						ethers.constants.AddressZero,
						yieldSyncV1ATransferRequestProtocol.address,
						[addr1.address],
						[addr1.address],
						{ value: 1 }
					);

					const vaultAddress = await yieldSyncV1VaultDeployer.yieldSyncV1VaultId_yieldSyncV1Vault(0);

					expect(vaultAddress).to.equal((await deployedObj.wait()).events[0].args[0]);
				}
			);

			it(
				"Should be able to record deployed YieldSyncV1Vault.sol on YieldSyncV1VaultRegistry.sol..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					// Preset
					await yieldSyncV1ATransferRequestProtocol.connect(
						addr1
					).yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
						addr1.address,
						[1, 1, 10] as UpdateVaultProperty
					);

					await yieldSyncV1VaultDeployer.connect(addr1).deployYieldSyncV1Vault(
						ethers.constants.AddressZero,
						yieldSyncV1ATransferRequestProtocol.address,
						[addr1.address],
						[addr1.address],
						{ value: 1 }
					);

					const vaultAddress = await yieldSyncV1VaultRegistry.member_yieldSyncV1Vaults(addr1.address);

					expect(vaultAddress[0]).to.equal(
						await yieldSyncV1VaultDeployer.yieldSyncV1VaultId_yieldSyncV1Vault(0)
					);

					const vaultAddress1 = await yieldSyncV1VaultRegistry.admin_yieldSyncV1Vaults(addr1.address);

					expect(vaultAddress1[0]).to.equal(
						await yieldSyncV1VaultDeployer.yieldSyncV1VaultId_yieldSyncV1Vault(0)
					);

					const members = await yieldSyncV1VaultRegistry.yieldSyncV1Vault_members(
						await yieldSyncV1VaultDeployer.yieldSyncV1VaultId_yieldSyncV1Vault(0)
					);

					expect(members[0]).to.equal(addr1.address);

					const admins = await yieldSyncV1VaultRegistry.yieldSyncV1Vault_admins(
						await yieldSyncV1VaultDeployer.yieldSyncV1VaultId_yieldSyncV1Vault(0)
					);

					expect(admins[0]).to.equal(addr1.address);
				}
			);

			it(
				"Should have correct vault properties on YieldSyncV1ATransferRequestProtocol.sol..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					// Preset
					await yieldSyncV1ATransferRequestProtocol.connect(
						addr1
					).yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
						addr1.address,
						[1, 1, 10] as UpdateVaultProperty
					);

					await yieldSyncV1VaultDeployer.connect(addr1).deployYieldSyncV1Vault(
						ethers.constants.AddressZero,
						yieldSyncV1ATransferRequestProtocol.address,
						[addr1.address],
						[addr1.address],
						{ value: 1 }
					);

					const vProp = await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
						await yieldSyncV1VaultDeployer.yieldSyncV1VaultId_yieldSyncV1Vault(0)
					);

					expect(vProp.voteForRequired).to.equal(BigInt(1));
					expect(vProp.voteAgainstRequired).to.equal(BigInt(1));
					expect(vProp.transferDelaySeconds).to.equal(BigInt(10));
				}
			);

			it(
				"Should be able to deploy YieldSyncV1Vault.sol with custom signature protocol..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					// Preset
					await yieldSyncV1ATransferRequestProtocol.connect(
						addr1
					).yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
						addr1.address,
						[1, 1, 10] as UpdateVaultProperty
					);

					await yieldSyncV1VaultDeployer.connect(addr1).deployYieldSyncV1Vault(
						mockSignatureProtocol.address,
						yieldSyncV1ATransferRequestProtocol.address,
						[addr1.address],
						[addr1.address],
						{ value: 1 }
					);

					const YieldSyncV1Vault = await ethers.getContractFactory("YieldSyncV1Vault");

					// Attach the deployed vault's address
					const yieldSyncV1Vault = await YieldSyncV1Vault.attach(
						await yieldSyncV1VaultDeployer.yieldSyncV1VaultId_yieldSyncV1Vault(0)
					);

					expect(await yieldSyncV1Vault.signatureProtocol()).to.be.equal(mockSignatureProtocol.address);
				}
			);

			describe("YieldSyncV1VaultDeployer.sol Deployed: YieldSyncV1Vault.sol", async () => {
				it(
					"Should have admin set properly..",
					async () => {
						const [, addr1] = await ethers.getSigners();

						// Preset
						await yieldSyncV1ATransferRequestProtocol.connect(
							addr1
						).yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
							addr1.address,
							[1, 1, 10] as UpdateVaultProperty
						);

						await yieldSyncV1VaultDeployer.connect(addr1).deployYieldSyncV1Vault(
							mockSignatureProtocol.address,
							yieldSyncV1ATransferRequestProtocol.address,
							[addr1.address],
							[addr1.address],
							{ value: 1 }
						);

						const YieldSyncV1Vault = await ethers.getContractFactory("YieldSyncV1Vault");

						// Attach the deployed vault's address
						const yieldSyncV1Vault = await YieldSyncV1Vault.attach(
							await yieldSyncV1VaultDeployer.yieldSyncV1VaultId_yieldSyncV1Vault(0)
						);

						expect(
							(
								await yieldSyncV1VaultRegistry.yieldSyncV1Vault_participant_access(
									yieldSyncV1Vault.address,
									addr1.address,
								)
							).admin_
						).to.be.true;
					}
				);

				it(
					"Should have member set properly..",
					async () => {
						const [, addr1] = await ethers.getSigners();

						// Preset
						await yieldSyncV1ATransferRequestProtocol.connect(
							addr1
						).yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
							addr1.address,
							[1, 1, 10] as UpdateVaultProperty
						);

						await yieldSyncV1VaultDeployer.connect(addr1).deployYieldSyncV1Vault(
							mockSignatureProtocol.address,
							yieldSyncV1ATransferRequestProtocol.address,
							[addr1.address],
							[addr1.address],
							{ value: 1 }
						);

						const YieldSyncV1Vault = await ethers.getContractFactory("YieldSyncV1Vault");

						// Attach the deployed vault's address
						const yieldSyncV1Vault = await YieldSyncV1Vault.attach(
							await yieldSyncV1VaultDeployer.yieldSyncV1VaultId_yieldSyncV1Vault(0)
						);

						expect(
							(
								await yieldSyncV1VaultRegistry.yieldSyncV1Vault_participant_access(
									yieldSyncV1Vault.address,
									addr1.address,
								)
							).member_
						).to.be.true;
					}
				);
			});
		});
	});
});
