import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";

const { ethers } = require("hardhat");


describe("[4] MockAdmin.sol - Mock Admin Contract", async () => {
	let yieldSyncV1Vault: Contract;
	let yieldSyncV1VaultAccessControl: Contract;
	let yieldSyncV1VaultFactory: Contract;
	let yieldSyncV1TransferRequestProtocol: Contract;
	let signatureProtocol: Contract;
	let mockAdmin: Contract;
	let mockDapp: Contract;
	let mockERC20: Contract;
	let mockERC721: Contract;
	let mockYieldSyncGovernance: Contract;


	beforeEach("[before] Set up contracts..", async () => {
		const [owner, addr1, addr2] = await ethers.getSigners();

		/// Contract Factory
		const MockAdmin: ContractFactory = await ethers.getContractFactory("MockAdmin");
		const MockERC20: ContractFactory = await ethers.getContractFactory("MockERC20");
		const MockERC721: ContractFactory = await ethers.getContractFactory("MockERC721");
		const MockDapp: ContractFactory = await ethers.getContractFactory("MockDapp");
		const MockYieldSyncGovernance: ContractFactory = await ethers.getContractFactory("MockYieldSyncGovernance");

		const YieldSyncV1Vault: ContractFactory = await ethers.getContractFactory("YieldSyncV1Vault");
		const YieldSyncV1VaultFactory: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultFactory");
		const YieldSyncV1VaultAccessControl: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultAccessControl");
		const YieldSyncV1SignatureProtocol: ContractFactory = await ethers.getContractFactory("YieldSyncV1SignatureProtocol");
		const YieldSyncV1TransferRequestProtocol: ContractFactory = await ethers.getContractFactory("YieldSyncV1TransferRequestProtocol");


		/// Deploy
		// Mock
		mockDapp = await (await MockDapp.deploy()).deployed();
		mockAdmin = await (await MockAdmin.deploy()).deployed();
		mockERC20 = await (await MockERC20.deploy()).deployed();
		mockERC721 = await (await MockERC721.deploy()).deployed();

		// Expected
		mockYieldSyncGovernance = await (await MockYieldSyncGovernance.deploy()).deployed();
		yieldSyncV1VaultAccessControl = await (await YieldSyncV1VaultAccessControl.deploy()).deployed();

		// Deploy Factory
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

		// Deploy Signature Protocol
		signatureProtocol = await (
			await YieldSyncV1SignatureProtocol.deploy(
				mockYieldSyncGovernance.address,
				yieldSyncV1VaultAccessControl.address
			)
		).deployed();

		await signatureProtocol.update_purposer_signaturesRequired(2);

		// Set Factory -> Transfer Request Protocol
		await yieldSyncV1VaultFactory.defaultTransferRequestProtocolUpdate(yieldSyncV1TransferRequestProtocol.address);

		// Set Factory -> Transfer Request Protocol
		await yieldSyncV1VaultFactory.defaultSignatureProtocolUpdate(signatureProtocol.address);

		// Set YieldSyncV1Vault properties on TransferRequestProtocol.sol
		await yieldSyncV1TransferRequestProtocol.purposeYieldSyncV1VaultProperty([
			2, 2, 5
		]);

		// Deploy a vault
		await yieldSyncV1VaultFactory.deployYieldSyncV1Vault(
			ethers.constants.AddressZero,
			ethers.constants.AddressZero,
			[owner.address],
			[addr1.address, addr2.address],
			true,
			true,
			{ value: 1 }
		);

		// Attach the deployed vault's address
		yieldSyncV1Vault = await YieldSyncV1Vault.attach(
			await yieldSyncV1VaultFactory.yieldSyncV1VaultId_yieldSyncV1VaultAddress(0)
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

	/**
	 * @dev Restriction: DEFAULT_ADMIN_ROLE
	*/
	describe("Restriction: DEFAULT_ADMIN_ROLE", async () => {
		describe("adminAdd()", async () => {
			it("Should allow admin to add a contract-based admin..", async () => {
				await yieldSyncV1Vault.adminAdd(mockAdmin.address);
			});
		});

		/**
		 * @dev deleteTransferRequest
		*/
		describe("updateTransferRequestLatestRelevantForVoteTime()", async () => {
			it(
				"Should update the latestRelevantForVoteTime to ADD seconds..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await yieldSyncV1Vault.adminAdd(mockAdmin.address);

					await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
						yieldSyncV1Vault.address,
						false,
						false,
						addr2.address,
						ethers.constants.AddressZero,
						ethers.utils.parseEther(".5"),
						0
					);

					const beforeBlockTimestamp = BigInt((
						await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestVote(
							yieldSyncV1Vault.address,
							0
						)
					).latestRelevantForVoteTime);

					await mockAdmin.updateTransferRequestVoteLatestRelevantForVoteTime(
						yieldSyncV1TransferRequestProtocol.address,
						yieldSyncV1Vault.address,
						0,
						true,
						4000
					);

					const afterBlockTimestamp = BigInt((
						await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestVote(
							yieldSyncV1Vault.address,
							0
						)
					).latestRelevantForVoteTime);

					expect(BigInt(beforeBlockTimestamp + BigInt(4000))).to.be.equal(afterBlockTimestamp);
				}
			);
		});
	});
});
