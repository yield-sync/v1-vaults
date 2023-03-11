import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";

const { ethers } = require("hardhat");


const stageContracts = async () => {
	const [owner, addr1] = await ethers.getSigners();

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
		[addr1.address],
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


describe("IglooFiV1Vault.sol - IglooFi V1 Vault Contract", async () => {
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
});
