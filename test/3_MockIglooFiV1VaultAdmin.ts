import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";

const { ethers } = require("hardhat");


const stageContracts = async () => {
	const [owner, addr1, addr2] = await ethers.getSigners();

	const IglooFiV1Vault: ContractFactory = await ethers.getContractFactory("IglooFiV1Vault");
	const IglooFiV1VaultFactory: ContractFactory = await ethers.getContractFactory("IglooFiV1VaultFactory");
	const IglooFiV1VaultRecord: ContractFactory = await ethers.getContractFactory("IglooFiV1VaultRecord");
	const MockIglooFiGovernance: ContractFactory = await ethers.getContractFactory("MockIglooFiGovernance");
	const MockAdmin: ContractFactory = await ethers.getContractFactory("MockAdmin");
	const SignatureManager: ContractFactory = await ethers.getContractFactory("SignatureManager");

	// Deploy
	const mockIglooFiGovernance: Contract = await (await MockIglooFiGovernance.deploy()).deployed();
	const iglooFiV1VaultRecord: Contract = await (await IglooFiV1VaultRecord.deploy()).deployed();
	const iglooFiV1VaultFactory: Contract = await (
		await IglooFiV1VaultFactory.deploy(mockIglooFiGovernance.address, iglooFiV1VaultRecord.address)
	).deployed();

	// Deploy a vault
	await iglooFiV1VaultFactory.deployIglooFiV1Vault(
		owner.address,
		[addr1.address, addr2.address],
		ethers.constants.AddressZero,
		true,
		2,
		2,
		5,
		{ value: 1 }
	);

	// Attach the deployed vault's address
	const iglooFiV1Vault: Contract = await IglooFiV1Vault.attach(iglooFiV1VaultFactory.iglooFiV1VaultIdToAddress(0));

	const mockAdmin: Contract = await (await MockAdmin.deploy()).deployed();
	const signatureManager: Contract = await (
		await SignatureManager.deploy(mockIglooFiGovernance.address, iglooFiV1VaultRecord.address)
	).deployed();

	return {
		iglooFiV1Vault,
		iglooFiV1VaultFactory,
		iglooFiV1VaultRecord,
		mockIglooFiGovernance,
		mockAdmin,
		signatureManager
	};
};


describe("MockAdmin.sol - Mock Admin Contract", async () => {
	let iglooFiV1Vault: Contract;
	let iglooFiV1VaultFactory: Contract;
	let iglooFiV1VaultRecord: Contract;
	let mockIglooFiGovernance: Contract;
	let mockAdmin: Contract;
	let signatureManager: Contract;


	before("[before] Set up contracts..", async () => {
		const [, addr1, addr2] = await ethers.getSigners();

		const stagedContracts = await stageContracts();

		iglooFiV1Vault = stagedContracts.iglooFiV1Vault;
		iglooFiV1VaultFactory = stagedContracts.iglooFiV1VaultFactory;
		iglooFiV1VaultRecord = stagedContracts.iglooFiV1VaultRecord;
		mockIglooFiGovernance = stagedContracts.mockIglooFiGovernance;
		mockAdmin = stagedContracts.mockAdmin;
		signatureManager = stagedContracts.signatureManager;

		await iglooFiV1Vault.updateSignatureManager(signatureManager.address);

		// Send ether to IglooFiV1Vault contract
		await addr1.sendTransaction({
			to: iglooFiV1Vault.address,
			value: ethers.utils.parseEther("1")
		});

		await iglooFiV1Vault.connect(addr1).createWithdrawalRequest(
			true,
			false,
			false,
			addr2.address,
			ethers.constants.AddressZero,
			ethers.utils.parseEther(".5"),
			0
		);
	});

	/**
	 * @dev Restriction: DEFAULT_ADMIN_ROLE
	*/
	describe("Restriction: DEFAULT_ADMIN_ROLE", async () => {
		describe("addAdmin()", async () => {
			it("Should allow admin to add a contract-based admin..", async () => {
				await iglooFiV1Vault.addAdmin(mockAdmin.address);
			});
		});

		/**
		 * @dev deleteWithdrawalRequest
		*/
		describe("updateWithdrawalRequestLatestRelevantApproveVoteTime()", async () => {
			it(
				"Should update the latestRelevantApproveVoteTime to ADD seconds..",
				async () => {
					const beforeBlockTimestamp = BigInt((await iglooFiV1Vault.withdrawalRequest(0))[10]);

					await mockAdmin.updateWithdrawalRequestLatestRelevantApproveVoteTime(
						iglooFiV1Vault.address,
						0,
						true,
						4000
					);

					const afterBlockTimestamp = BigInt((await iglooFiV1Vault.withdrawalRequest(0))[10]);

					expect(BigInt(beforeBlockTimestamp + BigInt(4000))).to.be.equal(afterBlockTimestamp);
				}
			);
		});
	});
});
