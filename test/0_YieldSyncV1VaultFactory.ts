import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";

const { ethers } = require("hardhat");


describe("[0] YieldSyncV1VaultFactory.sol - YieldSync V1 Vault Factory Contract", async () => {
	let yieldSyncV1VaultAccessControl: Contract;
	let yieldSyncV1VaultFactory: Contract;
	let yieldSyncV1TransferRequestProtocol: Contract;
	let mockYieldSyncGovernance: Contract;
	let mockSignatureProtocol: Contract;

	beforeEach("[before] Set up contracts..", async () => {
		const [, addr1] = await ethers.getSigners();

		// Contract Factory
		const YieldSyncV1VaultFactory: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultFactory");
		const YieldSyncV1VaultAccessControl: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultAccessControl");
		const MockYieldSyncGovernance: ContractFactory = await ethers.getContractFactory("MockYieldSyncGovernance");
		const MockSignatureProtocol: ContractFactory = await ethers.getContractFactory("MockSignatureProtocol");
		const YieldSyncV1TransferRequestProtocol: ContractFactory = await ethers.getContractFactory("YieldSyncV1TransferRequestProtocol");

		/// Deploy
		// Mock
		mockYieldSyncGovernance = await (await MockYieldSyncGovernance.deploy()).deployed();
		yieldSyncV1VaultAccessControl = await (await YieldSyncV1VaultAccessControl.deploy()).deployed();

		// Expected
		yieldSyncV1VaultFactory = await (
			await YieldSyncV1VaultFactory.deploy(mockYieldSyncGovernance.address, yieldSyncV1VaultAccessControl.address)
		).deployed();

		// Deploy Transfer Request Protocol
		yieldSyncV1TransferRequestProtocol = await (
			await YieldSyncV1TransferRequestProtocol.deploy(
				yieldSyncV1VaultAccessControl.address,
				yieldSyncV1VaultFactory.address
			)
		).deployed();

		// Set Factory -> Transfer Request Protocol
		await yieldSyncV1VaultFactory.defaultTransferRequestProtocol__update(yieldSyncV1TransferRequestProtocol.address);

		// Deploy Signature Protocol
		mockSignatureProtocol = await (
			await MockSignatureProtocol.deploy(mockYieldSyncGovernance.address, yieldSyncV1VaultAccessControl.address)
		).deployed();


		// Send ether to YieldSyncV1VaultFactory contract
		await addr1.sendTransaction({
			to: yieldSyncV1VaultFactory.address,
			value: ethers.utils.parseEther("1"),
		});
	});

	describe("Receiving tokens & ethers", async () => {
		it(
			"Should be able to recieve ether..",
			async () => {
				const [, addr1] = await ethers.getSigners();

				// Send ether to YieldSyncV1VaultFactory contract
				await addr1.sendTransaction({
					to: yieldSyncV1VaultFactory.address,
					value: ethers.utils.parseEther("1"),
				});

				await expect(
					await ethers.provider.getBalance(yieldSyncV1VaultFactory.address)
				).to.be.greaterThanOrEqual(ethers.utils.parseEther("1"));
			}
		);
	});

	describe("Initial values", async () => {
		it(
			"Should initialize `yieldSyncGovernance` to `MockYieldSyncGovernance` address..",
			async () => {
				expect(await yieldSyncV1VaultFactory.YieldSyncGovernance()).to.equal(
					mockYieldSyncGovernance.address
				);
			}
		);

		it(
			"Should initialize the `fee` to 0..",
			async () => {
				expect(await yieldSyncV1VaultFactory.fee()).to.equal(0);
			}
		);
	});


	describe("Restriction: IYieldSyncGovernance DEFAULT_ADMIN_ROLE", async () => {
		describe("defaultSignatureProtocol__update()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(
						yieldSyncV1VaultFactory.connect(addr1).defaultSignatureProtocol__update(
							ethers.constants.AddressZero
						)
					).to.be.rejectedWith("!auth");
				}
			);

			it(
				"Should be able to change defaultSignatureManager..",
				async () => {
					await yieldSyncV1VaultFactory.defaultSignatureProtocol__update(ethers.constants.AddressZero);

					await expect(
						await yieldSyncV1VaultFactory.defaultSignatureProtocol()
					).to.be.equal(ethers.constants.AddressZero);
				}
			);
		});

		describe("fee__update()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(yieldSyncV1VaultFactory.connect(addr1).fee__update(2)).to.be.rejectedWith("!auth");
				}
			);

			it(
				"Should update correctly..",
				async () => {
					await yieldSyncV1VaultFactory.fee__update(1);

					expect(await yieldSyncV1VaultFactory.fee()).to.equal(1);
				}
			);
		});

		describe("transferFunds()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(
						yieldSyncV1VaultFactory.connect(addr1).transferEther(addr1.address)
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
						yieldSyncV1VaultFactory: parseFloat(
							ethers.utils.formatUnits(
								await ethers.provider.getBalance(yieldSyncV1VaultFactory.address),
								"ether"
							)
						)
					};

					await yieldSyncV1VaultFactory.transferEther(addr1.address);

					const balanceAfter = {
						addr1: parseFloat(
							ethers.utils.formatUnits(await ethers.provider.getBalance(addr1.address), "ether")
						),
						yieldSyncV1VaultFactory: parseFloat(
							ethers.utils.formatUnits(
								await ethers.provider.getBalance(yieldSyncV1VaultFactory.address),
								"ether"
							)
						)
					};

					await expect(balanceAfter.addr1).to.be.equal(
						balanceBefore.addr1 + balanceBefore.yieldSyncV1VaultFactory
					);
				}
			);
		});
	});


	describe("!Restriction", async () => {
		describe("YieldSyncV1TransferRequestProtocol.purposeYieldSyncV1VaultProperty()", async () => {
			it(
				"Should be able to set _purposer_yieldSyncV1VaultProperty..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await yieldSyncV1TransferRequestProtocol.connect(addr1).purposeYieldSyncV1VaultProperty(
						[1, 1, 10]
					);

					const vaultProperties = await yieldSyncV1TransferRequestProtocol.purposer_yieldSyncV1VaultProperty(
						addr1.address
					);

					expect(vaultProperties.forVoteRequired).to.equal(BigInt(1));
					expect(vaultProperties.againstVoteRequired).to.equal(BigInt(1));
					expect(vaultProperties.transferDelaySeconds).to.equal(BigInt(10));
				}
			);
		});

		describe("deployYieldSyncV1Vault()", async () => {
			it(
				"Should fail to deploy YieldSyncV1Vault.sol due to not enough msg.value..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await yieldSyncV1VaultFactory.fee__update(ethers.utils.parseEther("1"));

					await expect(yieldSyncV1VaultFactory.deployYieldSyncV1Vault(
						ethers.constants.AddressZero,
						ethers.constants.AddressZero,
						[addr1.address],
						[addr1.address],
						true,
						true,
						{ value: ethers.utils.parseEther(".5") }
					)).to.be.rejectedWith("!msg.value");
				}
			);

			it(
				"Should be able to record deployed YieldSyncV1Vault.sol on YieldSyncV1VaultFactory.sol..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await yieldSyncV1TransferRequestProtocol.connect(addr1).purposeYieldSyncV1VaultProperty(
						[1, 1, 10]
					);

					const deployedObj = await yieldSyncV1VaultFactory.connect(addr1).deployYieldSyncV1Vault(
						ethers.constants.AddressZero,
						ethers.constants.AddressZero,
						[addr1.address],
						[addr1.address],
						true,
						true,
						{ value: 1 }
					);

					const vaultAddress = await yieldSyncV1VaultFactory.yieldSyncV1VaultId_yieldSyncV1VaultAddress(0);

					expect(vaultAddress).to.equal((await deployedObj.wait()).events[0].args[0]);
				}
			);

			it(
				"Should be able to record deployed YieldSyncV1Vault.sol on YieldSyncV1VaultAccessControl.sol..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await yieldSyncV1TransferRequestProtocol.connect(addr1).purposeYieldSyncV1VaultProperty(
						[1, 1, 10]
					);

					await yieldSyncV1VaultFactory.connect(addr1).deployYieldSyncV1Vault(
						ethers.constants.AddressZero,
						ethers.constants.AddressZero,
						[addr1.address],
						[addr1.address],
						true,
						true,
						{ value: 1 }
					);

					const vaultAddress = await yieldSyncV1VaultAccessControl.member_yieldSyncV1Vaults(addr1.address);

					expect(vaultAddress[0]).to.equal(
						await yieldSyncV1VaultFactory.yieldSyncV1VaultId_yieldSyncV1VaultAddress(0)
					);

					const vaultAddress1 = await yieldSyncV1VaultAccessControl.admin_yieldSyncV1Vaults(addr1.address);

					expect(vaultAddress1[0]).to.equal(
						await yieldSyncV1VaultFactory.yieldSyncV1VaultId_yieldSyncV1VaultAddress(0)
					);

					const members = await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_members(
						await yieldSyncV1VaultFactory.yieldSyncV1VaultId_yieldSyncV1VaultAddress(0)
					);

					expect(members[0]).to.equal(addr1.address);

					const admins = await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_admins(
						await yieldSyncV1VaultFactory.yieldSyncV1VaultId_yieldSyncV1VaultAddress(0)
					);

					expect(admins[0]).to.equal(addr1.address);
				}
			);

			it(
				"Should have correct vault properties on YieldSyncV1TransferRequestProtocol.sol..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await yieldSyncV1TransferRequestProtocol.connect(addr1).purposeYieldSyncV1VaultProperty(
						[1, 1, 10]
					);

					await yieldSyncV1VaultFactory.connect(addr1).deployYieldSyncV1Vault(
						ethers.constants.AddressZero,
						ethers.constants.AddressZero,
						[addr1.address],
						[addr1.address],
						true,
						true,
						{ value: 1 }
					);

					const vProp = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
						await yieldSyncV1VaultFactory.yieldSyncV1VaultId_yieldSyncV1VaultAddress(0)
					);

					expect(vProp.forVoteRequired).to.equal(BigInt(1));
					expect(vProp.againstVoteRequired).to.equal(BigInt(1));
					expect(vProp.transferDelaySeconds).to.equal(BigInt(10));
				}
			);

			it(
				"Should be able to deploy YieldSyncV1Vault.sol with custom signature protocol..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await yieldSyncV1VaultFactory.defaultSignatureProtocol__update(ethers.constants.AddressZero);

					await yieldSyncV1TransferRequestProtocol.connect(addr1).purposeYieldSyncV1VaultProperty(
						[1, 1, 10]
					);

					await yieldSyncV1VaultFactory.deployYieldSyncV1Vault(
						mockSignatureProtocol.address,
						ethers.constants.AddressZero,
						[addr1.address],
						[addr1.address],
						false,
						true,
						{ value: 1 }
					);

					const YieldSyncV1Vault = await ethers.getContractFactory("YieldSyncV1Vault");

					// Attach the deployed vault's address
					const yieldSyncV1Vault = await YieldSyncV1Vault.attach(
						await yieldSyncV1VaultFactory.yieldSyncV1VaultId_yieldSyncV1VaultAddress(0)
					);

					expect(await yieldSyncV1Vault.signatureProtocol()).to.be.equal(mockSignatureProtocol.address);
				}
			);

			describe("YieldSyncV1VaultFactory.sol Deployed: YieldSyncV1.sol", async () => {
				it(
					"Should have admin set properly..",
					async () => {
						const [, addr1] = await ethers.getSigners();

						await yieldSyncV1TransferRequestProtocol.connect(addr1).purposeYieldSyncV1VaultProperty(
							[1, 1, 10]
						);

						await yieldSyncV1VaultFactory.deployYieldSyncV1Vault(
							mockSignatureProtocol.address,
							ethers.constants.AddressZero,
							[addr1.address],
							[addr1.address],
							false,
							true,
							{ value: 1 }
						);

						const YieldSyncV1Vault = await ethers.getContractFactory("YieldSyncV1Vault");

						// Attach the deployed vault's address
						const yieldSyncV1Vault = await YieldSyncV1Vault.attach(
							await yieldSyncV1VaultFactory.yieldSyncV1VaultId_yieldSyncV1VaultAddress(0)
						);

						expect(
							(
								await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_participant_access(
									yieldSyncV1Vault.address,
									addr1.address,
								)
							).admin
						).to.be.true;
					}
				);

				it(
					"Should have member set properly..",
					async () => {
						const [, addr1] = await ethers.getSigners();

						await yieldSyncV1TransferRequestProtocol.connect(
							addr1
						).purposeYieldSyncV1VaultProperty(
							[1, 1, 10]
						);

						await yieldSyncV1VaultFactory.deployYieldSyncV1Vault(
							mockSignatureProtocol.address,
							ethers.constants.AddressZero,
							[addr1.address],
							[addr1.address],
							false,
							true,
							{ value: 1 }
						);

						const YieldSyncV1Vault = await ethers.getContractFactory("YieldSyncV1Vault");

						// Attach the deployed vault's address
						const yieldSyncV1Vault = await YieldSyncV1Vault.attach(
							await yieldSyncV1VaultFactory.yieldSyncV1VaultId_yieldSyncV1VaultAddress(0)
						);

						expect(
							(
								await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_participant_access(
									yieldSyncV1Vault.address,
									addr1.address,
								)
							).member
						).to.be.true;
					}
				);
			});
		});
	});
});
