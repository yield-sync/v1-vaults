import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";

const { ethers } = require("hardhat");


describe("IglooFiV1VaultFactory.sol - IglooFi V1 Vault Factory Contract", async () => {
	let mockIglooFiGovernance: Contract;
	let mockSignatureManager: Contract;
	let iglooFiV1VaultFactory: Contract;
	

	before("[before] Set up contracts..", async () => {
		const MockIglooFiGovernance: ContractFactory = await ethers.getContractFactory("MockIglooFiGovernance");
		const MockSignatureManager: ContractFactory = await ethers.getContractFactory("MockSignatureManager");
		const IglooFiV1VaultFactory: ContractFactory = await ethers.getContractFactory("IglooFiV1VaultFactory");
		
		mockIglooFiGovernance = await (await MockIglooFiGovernance.deploy()).deployed();
		mockSignatureManager = await (await MockSignatureManager.deploy(mockIglooFiGovernance.address)).deployed();
		iglooFiV1VaultFactory = await (await IglooFiV1VaultFactory.deploy(mockIglooFiGovernance.address)).deployed();
	});


	/**
	* @dev recieve
	*/
	describe("Recieving tokens & ethers", async () => {
		it(
			"Should be able to recieve ether..",
			async () => {
				const [, addr1] = await ethers.getSigners();
				
				// Send ether to IglooFiV1VaultFactory contract
				await addr1.sendTransaction({
					to: iglooFiV1VaultFactory.address,
					value: ethers.utils.parseEther("1"),
				});

				await expect(
					await ethers.provider.getBalance(iglooFiV1VaultFactory.address)
				).to.be.greaterThanOrEqual(ethers.utils.parseEther("1"));
			}
		);
	});

	/**
	* @dev Initial values set by constructor
	*/
	describe("Constructor Initialized values", async () => {
		/**
		 * @notice Check if initial values are correct
		*/
		it(
			"Should intialize pause as true..",
			async () => {
				expect(await iglooFiV1VaultFactory.paused()).to.equal(true);
			}
		);

		it(
			"Should initialize `iglooFiGovernance` to `MockIglooFiGovernance` address..",
			async () => {
				expect(await iglooFiV1VaultFactory.iglooFiGovernance()).to.equal(
					mockIglooFiGovernance.address
				);
			}
		);

		it(
			"Should initialize the `fee` to 0..",
			async () => {
				expect(await iglooFiV1VaultFactory.fee()).to.equal(0);
			}
		);
	});


	/**
	 * @dev admin
	*/
	describe("Restriction: DEFAULT_ADMIN_ROLE", async () => {
		/**
		* @dev updatePause
		*/
		describe("updatePause", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(iglooFiV1VaultFactory.connect(addr1).updatePause(false)).to.be.rejectedWith("!auth");
				}
			);

			it(
				"Should be able to set true..",
				async () => {
					await iglooFiV1VaultFactory.updatePause(false);
					
					expect(await iglooFiV1VaultFactory.paused()).to.be.false;
				}
			);

			it(
				"Should be able to set false..",
				async () => {
					await iglooFiV1VaultFactory.updatePause(true);
					
					expect(await iglooFiV1VaultFactory.paused()).to.be.true;

					// Unpause for the rest of the test
					await iglooFiV1VaultFactory.updatePause(false);
				}
			);
		});


		/**
		* @dev updateDefaultSignatureManager
		*/
		describe("updateDefaultSignatureManager", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(
						iglooFiV1VaultFactory.connect(addr1).updateDefaultSignatureManager(ethers.constants.AddressZero)
					).to.be.rejectedWith("!auth");
				}
			);

			it(
				"Should be able to change defaultSignatureManager..",
				async () => {
					await iglooFiV1VaultFactory.updateDefaultSignatureManager(ethers.constants.AddressZero);

					await expect(
						await iglooFiV1VaultFactory.defaultSignatureManager()
					).to.be.equal(ethers.constants.AddressZero);
				}
			);
		});

		/**
		* @dev updateFee
		*/
		describe("updateFee", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(iglooFiV1VaultFactory.connect(addr1).updateFee(2)).to.be.rejectedWith("!auth");
				}
			);

			it(
				"Should update correctly..",
				async () => {
					await iglooFiV1VaultFactory.updateFee(1);

					expect(await iglooFiV1VaultFactory.fee()).to.equal(1);
				}
			);
		});


		/**
		* @dev transferFunds
		*/
		describe("transferFunds", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(
						iglooFiV1VaultFactory.connect(addr1).transferFunds(addr1.address)
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
						iglooFiV1VaultFactory: parseFloat(
							ethers.utils.formatUnits(
								await ethers.provider.getBalance(iglooFiV1VaultFactory.address),
								"ether"
							)
						)
					};

					await iglooFiV1VaultFactory.transferFunds(addr1.address);

					const balanceAfter = {
						addr1: parseFloat(
							ethers.utils.formatUnits(await ethers.provider.getBalance(addr1.address), "ether")
						),
						iglooFiV1VaultFactory: parseFloat(
							ethers.utils.formatUnits(
								await ethers.provider.getBalance(iglooFiV1VaultFactory.address),
								"ether"
							)
						)
					};

					await expect(balanceAfter.addr1).to.be.equal(
						balanceBefore.addr1 + balanceBefore.iglooFiV1VaultFactory
					);
				}
			);
		});
	});


	describe("!Restriction", async () => {
		/**
		* @dev deployVault
		*/
		describe("deployVault", async () => {
			it(
				"Should be able to record deployed IglooFiV1Vault.sol..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					const deployedObj = await iglooFiV1VaultFactory.deployVault(
						addr1.address,
						ethers.constants.AddressZero,
						true,
						2,
						10,
						{ value: 1 }
					);

					expect(await iglooFiV1VaultFactory.iglooFiV1VaultAddress(0)).to.equal(
						(await deployedObj.wait()).events[1].args[0]
					);
				}
			);

			it(
				"Should be able to deploy IglooFiV1Vault.sol with custom signature manager..",
				async () => {
					const [, addr1] = await ethers.getSigners();
					
					const IglooFiV1Vault = await ethers.getContractFactory("IglooFiV1Vault");

					await iglooFiV1VaultFactory.deployVault(
						addr1.address,
						mockSignatureManager.address,
						false,
						2,
						10,
						{ value: 1 }
					);

					// Attach the deployed vault's address
					const iglooFiV1Vault = await IglooFiV1Vault.attach(
						await iglooFiV1VaultFactory.iglooFiV1VaultAddress(1)
					);

					expect(await iglooFiV1Vault.signatureManager()).to.be.equal(mockSignatureManager.address);
				}
			);

			/**
			* @dev IglooFiV1VaultFactory.sol Deployed: IglooFiV1.sol
			*/
			describe("IglooFiV1VaultFactory.sol Deployed: IglooFiV1.sol", async () => {
				it(
					"Should have admin set properly..",
					async () => {
						const [, addr1] = await ethers.getSigners();
						
						const IglooFiV1Vault = await ethers.getContractFactory("IglooFiV1Vault");
						
						// Retreive the deployed vault's address
						const deployedAddress = await iglooFiV1VaultFactory.iglooFiV1VaultAddress(0);

						// Attach the deployed vault's address
						const iglooFiV1Vault = await IglooFiV1Vault.attach(deployedAddress);

						expect(
							await iglooFiV1Vault.hasRole(await iglooFiV1Vault.DEFAULT_ADMIN_ROLE(), addr1.address)
						).to.equal(true);
					}
				);
			});
		});
	});
});