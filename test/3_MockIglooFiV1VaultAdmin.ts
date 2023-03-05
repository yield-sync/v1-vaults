import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";

const { ethers } = require("hardhat");


const stageContracts = async () => {
	const [owner] = await ethers.getSigners();

	const IglooFiV1Vault: ContractFactory = await ethers.getContractFactory("IglooFiV1Vault");
	const IglooFiV1VaultFactory: ContractFactory = await ethers.getContractFactory("IglooFiV1VaultFactory");
	const MockIglooFiGovernance: ContractFactory = await ethers.getContractFactory("MockIglooFiGovernance");
	const MockAdmin: ContractFactory = await ethers.getContractFactory("MockAdmin");
	const SignatureManager: ContractFactory = await ethers.getContractFactory("SignatureManager");
	
	// Deploy
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

	const mockAdmin: Contract = await (await MockAdmin.deploy()).deployed();
	const signatureManager: Contract = await (await SignatureManager.deploy(mockIglooFiGovernance.address)).deployed();

	return {
		iglooFiV1VaultFactory,
		iglooFiV1Vault,
		mockIglooFiGovernance,
		mockAdmin,
		signatureManager
	};
};


describe("MockAdmin.sol - Mock Admin Contract", async () => {
	let iglooFiV1VaultFactory: Contract;
	let iglooFiV1Vault: Contract;
	let mockIglooFiGovernance: Contract;
	let mockAdmin: Contract;
	let signatureManager: Contract;


	before("[before] Set up contracts..", async () => {
		const [, addr1, addr2] = await ethers.getSigners();

		const stagedContracts = await stageContracts();

		iglooFiV1Vault = stagedContracts.iglooFiV1Vault;
		iglooFiV1VaultFactory = stagedContracts.iglooFiV1VaultFactory;
		mockIglooFiGovernance = stagedContracts.mockIglooFiGovernance;
		mockAdmin = stagedContracts.mockAdmin;
		signatureManager = stagedContracts.signatureManager;

		await iglooFiV1Vault.addVoter(addr1.address);
		await iglooFiV1Vault.addVoter(addr2.address);

		await iglooFiV1Vault.updateSignatureManager(signatureManager.address);
	});

	/**
	* @dev AccessControlEnumerable
	*/
	describe("AccessControlEnumerable", async () => {
		it("Should allow admin to add a contract-based admin..", async () => {
			await iglooFiV1Vault.grantRole(await iglooFiV1Vault.VOTER(), mockAdmin.address)
		});
	});

		/**
	 * @dev Restriction: DEFAULT_ADMIN_ROLE
	*/
	describe("Restriction: DEFAULT_ADMIN_ROLE", async () => {
	});
});