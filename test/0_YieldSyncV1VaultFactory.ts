import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";

const { ethers } = require("hardhat");


const stageContracts = async () => {
	const YieldSyncV1VaultFactory: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultFactory");
	const YieldSyncV1VaultRecord: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultRecord");
	const MockYieldSyncGovernance: ContractFactory = await ethers.getContractFactory("MockYieldSyncGovernance");
	const MockSignatureManager: ContractFactory = await ethers.getContractFactory("MockSignatureManager");

	// Deploy
	const mockYieldSyncGovernance: Contract = await (await MockYieldSyncGovernance.deploy()).deployed();
	const yieldSyncV1VaultRecord: Contract = await (await YieldSyncV1VaultRecord.deploy()).deployed();
	const yieldSyncV1VaultFactory: Contract = await (
		await YieldSyncV1VaultFactory.deploy(mockYieldSyncGovernance.address, yieldSyncV1VaultRecord.address)
	).deployed();
	const mockSignatureManager: Contract = await (
		await MockSignatureManager.deploy(mockYieldSyncGovernance.address, yieldSyncV1VaultRecord.address)
	).deployed();

	return {
		yieldSyncV1VaultFactory,
		yieldSyncV1VaultRecord,
		mockYieldSyncGovernance,
		mockSignatureManager
	};
}


describe("[0] YieldSyncV1VaultFactory.sol - YieldSync V1 Vault Factory Contract", async () => {
	let yieldSyncV1VaultFactory: Contract;
	let yieldSyncV1VaultRecord: Contract;
	let mockYieldSyncGovernance: Contract;
	let mockSignatureManager: Contract;

	before("[before] Set up contracts..", async () => {
		const stagedContracts = await stageContracts();

		yieldSyncV1VaultFactory = stagedContracts.yieldSyncV1VaultFactory
		yieldSyncV1VaultRecord = stagedContracts.yieldSyncV1VaultRecord
		mockYieldSyncGovernance = stagedContracts.mockYieldSyncGovernance;
		mockSignatureManager = stagedContracts.mockSignatureManager;
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
				expect(await yieldSyncV1VaultFactory.yieldSyncGovernance()).to.equal(
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
		describe("updateDefaultSignatureManager()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(
						yieldSyncV1VaultFactory.connect(addr1).updateDefaultSignatureManager(ethers.constants.AddressZero)
					).to.be.rejectedWith("!auth");
				}
			);

			it(
				"Should be able to change defaultSignatureManager..",
				async () => {
					await yieldSyncV1VaultFactory.updateDefaultSignatureManager(ethers.constants.AddressZero);

					await expect(
						await yieldSyncV1VaultFactory.defaultSignatureManager()
					).to.be.equal(ethers.constants.AddressZero);
				}
			);
		});

		describe("updateFee()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(yieldSyncV1VaultFactory.connect(addr1).updateFee(2)).to.be.rejectedWith("!auth");
				}
			);

			it(
				"Should update correctly..",
				async () => {
					await yieldSyncV1VaultFactory.updateFee(1);

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
		describe("deployYieldSyncV1Vault()", async () => {
			it(
				"Should be able to record deployed YieldSyncV1Vault.sol..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					const deployedObj = await yieldSyncV1VaultFactory.deployYieldSyncV1Vault(
						addr1.address,
						[addr1.address],
						ethers.constants.AddressZero,
						true,
						2,
						2,
						10,
						{ value: 1 }
					);

					expect(await yieldSyncV1VaultFactory.yieldSyncV1VaultId_yieldSyncV1VaultAddress(0)).to.equal(
						(await deployedObj.wait()).events[0].args[0]
					);
				}
			);

			it(
				"Should be able to deploy YieldSyncV1Vault.sol with custom signature manager..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					const YieldSyncV1Vault = await ethers.getContractFactory("YieldSyncV1Vault");

					await yieldSyncV1VaultFactory.deployYieldSyncV1Vault(
						addr1.address,
						[addr1.address],
						mockSignatureManager.address,
						false,
						2,
						2,
						10,
						{ value: 1 }
					);

					// Attach the deployed vault's address
					const yieldSyncV1Vault = await YieldSyncV1Vault.attach(
						await yieldSyncV1VaultFactory.yieldSyncV1VaultId_yieldSyncV1VaultAddress(1)
					);

					expect(await yieldSyncV1Vault.signatureManager()).to.be.equal(mockSignatureManager.address);
				}
			);

			describe("YieldSyncV1VaultFactory.sol Deployed: YieldSyncV1.sol", async () => {
				it(
					"Should have admin set properly..",
					async () => {
						const [, addr1] = await ethers.getSigners();

						const YieldSyncV1Vault = await ethers.getContractFactory("YieldSyncV1Vault");

						// Retreive the deployed vault's address
						const deployedAddress = await yieldSyncV1VaultFactory.yieldSyncV1VaultId_yieldSyncV1VaultAddress(0);

						// Attach the deployed vault's address
						const yieldSyncV1Vault = await YieldSyncV1Vault.attach(deployedAddress);

						expect(
							(await yieldSyncV1VaultRecord.participant_yieldSyncV1Vault_access(
								addr1.address,
								yieldSyncV1Vault.address
							))[0]
						).to.be.true;
					}
				);
			});
		});
	});
});
