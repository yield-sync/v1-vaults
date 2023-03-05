import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";

const { ethers } = require("hardhat");


const stageContracts = async () => {
	const [owner] = await ethers.getSigners();

	const IglooFiV1Vault: ContractFactory = await ethers.getContractFactory("IglooFiV1Vault");
	const IglooFiV1VaultFactory: ContractFactory = await ethers.getContractFactory("IglooFiV1VaultFactory");
	const MockIglooFiGovernance: ContractFactory = await ethers.getContractFactory("MockIglooFiGovernance");
	const MockIglooFiV1VaultAdmin: ContractFactory = await ethers.getContractFactory("MockIglooFiV1VaultAdmin");
	const SignatureManager: ContractFactory = await ethers.getContractFactory("SignatureManager");
	
	const mockIglooFiGovernance: Contract = await (await MockIglooFiGovernance.deploy()).deployed();
	const iglooFiV1VaultFactory: Contract = await (
		await IglooFiV1VaultFactory.deploy(mockIglooFiGovernance.address)
	).deployed();
	
	await iglooFiV1VaultFactory.updatePause(false);
	
	// Deploy a vault
	await iglooFiV1VaultFactory.deployIglooFiV1Vault(
		owner.address,
		ethers.constants.AddressZero,
		true,
		2,
		5,
		{ value: 1 }
	);

	// Attach the deployed vault's address
	const iglooFiV1Vault: Contract = await IglooFiV1Vault.attach(iglooFiV1VaultFactory.iglooFiV1VaultAddress(0));

	const mockIglooFiV1VaultAdmin: Contract = await (await MockIglooFiV1VaultAdmin.deploy()).deployed();
	const signatureManager: Contract = await (await SignatureManager.deploy(mockIglooFiGovernance.address)).deployed();

	return {
		iglooFiV1VaultFactory,
		iglooFiV1Vault,
		mockIglooFiGovernance,
		mockIglooFiV1VaultAdmin,
		signatureManager
	};
};


describe("IglooFiV1Vault.sol - IglooFi V1 Vault Contract", async () => {
	let iglooFiV1VaultFactory: Contract;
	let iglooFiV1Vault: Contract;
	let mockIglooFiGovernance: Contract;
	let mockIglooFiV1VaultAdmin: Contract;
	let signatureManager: Contract;


	before("[before] Set up contracts..", async () => {
		const stagedContracts = await stageContracts();

		iglooFiV1Vault = stagedContracts.iglooFiV1Vault;
		iglooFiV1VaultFactory = stagedContracts.iglooFiV1VaultFactory;
		mockIglooFiGovernance = stagedContracts.mockIglooFiGovernance;
		mockIglooFiV1VaultAdmin = stagedContracts.mockIglooFiV1VaultAdmin;
		signatureManager = stagedContracts.signatureManager;
	});

	/**
	* @dev AccessControlEnumerable
	*/
	describe("AccessControlEnumerable", async () => {
		it("Should allow admin to add a contract-based admin..", async () => {
			await iglooFiV1Vault.grantRole(await iglooFiV1Vault.VOTER(), mockIglooFiV1VaultAdmin.address)
		});
	});

		/**
	 * @dev Restriction: DEFAULT_ADMIN_ROLE
	*/
	describe("Restriction: DEFAULT_ADMIN_ROLE", async () => {
		describe("updateSignatureManager", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(
						iglooFiV1Vault.connect(addr1).updateSignatureManager(addr1.address)
					).to.be.rejected;
				}
			);

			it(
				"Should be able to set a signature manager contract..",
				async () => {

					await iglooFiV1Vault.updateSignatureManager(signatureManager.address);
					
					expect(await iglooFiV1Vault.signatureManager()).to.be.equal(signatureManager.address);
				}
			);
		});
	});
});