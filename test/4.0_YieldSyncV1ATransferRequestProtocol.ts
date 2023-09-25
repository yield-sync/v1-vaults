// Transfer Request Poll
type TransferRequestPoll = {
	latestForVoteTime: number,
	voteAgainstMembers: string[],
	voteForMembers: string[],
};

type UpdateTransferRequestPoll = [
	// latestForVoteTime
	number | bigint,
	// voteAgainstMembers
	string[],
	// voteForMembers
	string[],
];

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


const secondsIn7Days = 24 * 60 * 60 * 7;
const secondsIn6Days = 24 * 60 * 60 * 6;


describe("[4.0] YieldSyncV1Vault.sol with YieldSyncV1ATransferRequestProtocol", async () => {
	let mockAdmin: Contract;
	let mockERC20: Contract;
	let mockERC721: Contract;

	let vault: Contract;
	let Registry: Contract;
	let factory: Contract;
	let transferRequestProtocol: Contract;
	let mockYieldSyncGovernance: Contract;

	beforeEach("[beforeEach] Set up contracts..", async () => {
		const [owner, addr1] = await ethers.getSigners();

		// Contract Factory
		const MockAdmin: ContractFactory = await ethers.getContractFactory("MockAdmin");
		const MockERC20: ContractFactory = await ethers.getContractFactory("MockERC20");
		const MockERC721: ContractFactory = await ethers.getContractFactory("MockERC721");
		const MockYieldSyncGovernance: ContractFactory = await ethers.getContractFactory("MockYieldSyncGovernance");

		const YieldSyncV1Vault: ContractFactory = await ethers.getContractFactory("YieldSyncV1Vault");
		const YieldSyncV1VaultFactory: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultFactory");
		const YieldSyncV1VaultRegistry: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultRegistry");
		const YieldSyncV1ATransferRequestProtocol: ContractFactory = await ethers.getContractFactory(
			"YieldSyncV1ATransferRequestProtocol"
		);

		/// Mock
		// Governance and test contracts
		mockAdmin = await (await MockAdmin.deploy()).deployed();
		mockERC20 = await (await MockERC20.deploy()).deployed();
		mockERC721 = await (await MockERC721.deploy()).deployed();
		mockYieldSyncGovernance = await (await MockYieldSyncGovernance.deploy()).deployed();

		/// Core
		// Deploy YieldSyncV1VaultRegistry
		Registry = await (await YieldSyncV1VaultRegistry.deploy()).deployed();
		// Deploy YieldSyncV1VaultFactory
		factory = await (
			await YieldSyncV1VaultFactory.deploy(mockYieldSyncGovernance.address, Registry.address)
		).deployed();

		// Deploy YieldSyncV1ATransferRequestProtocol
		transferRequestProtocol = await (
			await YieldSyncV1ATransferRequestProtocol.deploy(Registry.address)
		).deployed();

		// Set YieldSyncV1Vault properties on TransferRequestProtocol.sol
		await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
			owner.address,
			[2, 2, secondsIn6Days] as UpdateVaultProperty
		);

		// Deploy a vault
		await factory.deployYieldSyncV1Vault(
			ethers.constants.AddressZero,
			transferRequestProtocol.address,
			[owner.address],
			[addr1.address],
			{ value: 1 }
		);

		// Attach the deployed vault's address
		vault = await YieldSyncV1Vault.attach(await factory.yieldSyncV1VaultId_yieldSyncV1Vault(0));

		// Send ether to YieldSyncV1Vault contract
		await addr1.sendTransaction({
			to: vault.address,
			value: ethers.utils.parseEther(".5")
		});

		// Send ERC20 to YieldSyncV1Vault contract
		await mockERC20.transfer(vault.address, 50);

		// Send ERC721 to YieldSyncV1Vault contract
		await mockERC721.transferFrom(owner.address, vault.address, 1);
	});


	describe("[yieldSyncV1ATransferRequestProtocol] Expected Failures", async () => {
		describe("Initiator must have property set before deploying vault", async () => {
			it(
				"Should fail to deploy a vault without setting initiator property first..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					const vProp: VaultProperty = await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
						addr1.address
					);

					expect(vProp.voteForRequired).to.equal(BigInt(0));
					expect(vProp.voteAgainstRequired).to.equal(BigInt(0));

					// fail to deploy a vault
					await expect(
						factory.connect(addr1).deployYieldSyncV1Vault(
							ethers.constants.AddressZero,
							transferRequestProtocol.address,
							[addr1.address],
							[addr1.address],
							{ value: 1 }
						)
					).to.be.rejectedWith("!_yieldSyncV1Vault_yieldSyncV1VaultProperty[initiator].voteAgainstRequired");
				}
			);
		});

		describe("When initiator sets properties, they must be >0", async () => {
			it(
				"Should fail to set voteAgainstRequired on addr1 yieldSyncV1VaultProperty to 0..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					// fail to deploy a vault
					await expect(
						transferRequestProtocol.connect(addr1).yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
							addr1.address,
							[0, 0, secondsIn6Days] as UpdateVaultProperty
						)
					).to.be.rejectedWith("!yieldSyncV1VaultProperty.voteAgainstRequired");
				}
			);

			it(
				"Should fail to set voteForRequired on addr1 yieldSyncV1VaultProperty to 0..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					// fail to deploy a vault
					await expect(
						transferRequestProtocol.connect(addr1).yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
							addr1.address,
							[1, 0, secondsIn6Days] as UpdateVaultProperty
						)
					).to.be.rejectedWith("!yieldSyncV1VaultProperty.voteForRequired");
				}
			);
		});
	});

	describe("[yieldSyncV1ATransferRequestProtocol] Initial Values", async () => {
		it(
			"Should intialize voteAgainstRequired as 2..",
			async () => {
				const vProp: VaultProperty = await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
					vault.address
				);

				expect(vProp.voteForRequired).to.equal(BigInt(2));
			}
		);

		it(
			"Should intialize voteForRequired as 2..",
			async () => {
				const vProp: VaultProperty = await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
					vault.address
				);

				expect(vProp.voteAgainstRequired).to.equal(BigInt(2));
			}
		);
	});

	describe("Restriction: admin (1/2)", async () => {
		it(
			"[auth] Should revert when unauthorized msg.sender calls..",
			async () => {
				const [, , , , addr4] = await ethers.getSigners();

				await expect(
					transferRequestProtocol.connect(addr4).yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
						vault.address,
						[123, 456, 789] as UpdateVaultProperty
					)
				).to.be.rejected;
			}
		);

		it("Should allow admin to update vault propreties..", async () => {
			const [owner] = await ethers.getSigners();

			// Preset
			await transferRequestProtocol.connect(owner).yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
				vault.address,
				[123, 456, 789] as UpdateVaultProperty
			);

			const vProp: VaultProperty = await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
				vault.address
			);

			expect(vProp.voteAgainstRequired).to.equal(123);
			expect(vProp.voteForRequired).to.equal(456);
			expect(vProp.transferDelaySeconds).to.equal(789);
		});
	});

	describe("Restriction: member (1/1)", async () => {
		describe("[transferRequest] For", async () => {
			describe("Requesting Ether", async () => {
				describe("vault_transferRequestId_transferRequestCreate()", async () => {
					it(
						"[auth] Should revert when unauthorized msg.sender calls..",
						async () => {
							const [, , , , addr4] = await ethers.getSigners();

							await expect(
								transferRequestProtocol.connect(
									addr4
								).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
									vault.address,
									false,
									false,
									addr4.address,
									ethers.constants.AddressZero,
									ethers.utils.parseEther(".5"),
									0
								)
							).to.be.rejected;
						}
					);

					it(
						"Should revert when amount is set to 0 or less..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							await expect(
								transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
									vault.address,
									false,
									false,
									addr1.address,
									ethers.constants.AddressZero,
									0,
									0
								)
							).to.be.rejectedWith("!amount");
						}
					);

					it(
						"Should revert when forERC20 and forERC721 are BOTH true..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							await expect(
								transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
									vault.address,
									true,
									true,
									addr1.address,
									ethers.constants.AddressZero,
									1,
									0
								)
							).to.be.rejectedWith("forERC20 && forERC721");
						}
					);

					it(
						"Should be able to create a TransferRequest for Ether..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								false,
								addr2.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							const createdTransferRequest: TransferRequest = await transferRequestProtocol
							.yieldSyncV1Vault_transferRequestId_transferRequest(
								vault.address,
								0
							);

							const createdTransferRequestPoll: TransferRequestPoll = await transferRequestProtocol
							.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
								vault.address,
								0
							);

							expect(createdTransferRequest.forERC20).to.be.false;
							expect(createdTransferRequest.forERC721).to.be.false;
							expect(createdTransferRequest.creator).to.be.equal(addr1.address);
							expect(createdTransferRequest.token).to.be.equal(ethers.constants.AddressZero);
							expect(createdTransferRequest.tokenId).to.be.equal(0);
							expect(createdTransferRequest.amount).to.be.equal(ethers.utils.parseEther(".5"));
							expect(createdTransferRequest.to).to.be.equal(addr2.address);
							expect(createdTransferRequestPoll.voteForMembers.length).to.be.equal(0);
							expect(createdTransferRequestPoll.voteAgainstMembers.length).to.be.equal(0);
						}
					);

					it(
						"Should have '0' in _openTransferRequestIds[0]..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							const openTRIds: OpenTransferRequestIds = await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
								vault.address
							);

							expect(openTRIds.length).to.be.equal(1);
							expect(openTRIds[0]).to.be.equal(0);
						}
					);
				});

				describe("vault_transferRequestId_transferRequestPollVote()", async () => {
					it(
						"[auth] Should revert when unauthorized msg.sender calls..",
						async () => {
							const [, addr1, , , addr4] = await ethers.getSigners();

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							await expect(
								transferRequestProtocol.connect(
									addr4
								).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
									vault.address,
									0,
									true
								)
							).to.be.rejected;
						}
					);

					it(
						"Should be able vote on TransferRequest & add member to _transferRequest[].votedMembers..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							// Vote
							await transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true
							)

							const createdTransferRequestPoll: TransferRequestPoll = await transferRequestProtocol
								.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
									vault.address,
									0
								);

							// Vote count
							expect(createdTransferRequestPoll.voteForMembers.length).to.be.equal(1);
							// Voted members
							expect(createdTransferRequestPoll.voteForMembers[0]).to.be.equal(addr1.address);
						}
					);

					it(
						"Should revert with 'Already voted' when attempting to vote again..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							// 1st vote
							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true
							)

							// Attempt 2nd vote
							await expect(
								transferRequestProtocol.connect(
									addr1
								).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
									vault.address,
									0,
									true
								)
							).to.be.rejectedWith("Already voted");
						}
					);
				});

				describe("vault_transferRequestId_transferRequestProcess()", async () => {
					it(
						"[auth] Should revert when unauthorized msg.sender calls..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true
							);

							await expect(
								vault.connect(
									addr2
								).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0)
							).to.be.rejected;
						}
					);

					it(
						"Should fail to process TransferRequest because not enough votes..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true
							);

							await expect(
								vault.connect(
									addr1
								).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0)
							).to.be.rejectedWith("TransferRequest pending");
						}
					);

					it(
						"Should fail to process TransferRequest because not enough time has passed..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							// Preset
							await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
								vault.address,
								[2, 1, secondsIn7Days] as UpdateVaultProperty
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true
							);

							// Fast-forward 6 days
							await ethers.provider.send('evm_increaseTime', [secondsIn6Days]);

							await expect(
								vault.connect(
									addr1
								).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0)
							).to.be.rejectedWith("TransferRequest approved and waiting delay");
						}
					);

					it(
						"Should process TransferRequest for Ether..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							// Preset
							await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
								vault.address,
								[2, 1, secondsIn6Days] as UpdateVaultProperty
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								false,
								addr2.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true
							);

							// Fast-forward 6 days
							await ethers.provider.send('evm_increaseTime', [secondsIn6Days]);

							const recieverBalanceBefore: number = ethers.utils.formatUnits(
								await ethers.provider.getBalance(addr2.address)
							);

							await vault.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

							const recieverBalanceAfter: number = ethers.utils.formatUnits(
								await ethers.provider.getBalance(addr2.address)
							);

							await expect(recieverBalanceAfter - recieverBalanceBefore).to.be.equal(.5);

							const openTRIds: OpenTransferRequestIds = await transferRequestProtocol
								.yieldSyncV1Vault_openTransferRequestIds(
									vault.address
								);

							expect(openTRIds.length).to.be.equal(0);
						}
					);
				});

				describe("Invalid ERC20 transferRequest", async () => {
					it(
						"Should fail to process request AND delete transferRequest after..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							// Preset
							await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
								vault.address,
								[2, 1, secondsIn7Days] as UpdateVaultProperty
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								false,
								addr2.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".6"),
								0
							);

							expect(
								(
									await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
										vault.address
									)
								).length
							).to.be.equal(1);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true
							);

							const recieverBalanceBefore: number = await ethers.provider.getBalance(addr2.address);

							// Fast-forward 7 days
							await ethers.provider.send('evm_increaseTime', [secondsIn7Days]);

							await vault.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

							const recieverBalanceAfter: number = await ethers.provider.getBalance(addr2.address);

							await expect(
								ethers.utils.formatUnits(recieverBalanceAfter)
							).to.be.equal(ethers.utils.formatUnits(recieverBalanceBefore));

							expect(
								(
									await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
										vault.address
									)
								).length
							).to.be.equal(0);
						}
					);
				});
			});

			describe("Requesting ERC20 tokens", async () => {
				describe("vault_transferRequestId_transferRequestCreate()", async () => {
					it(
						"Should be able to create a TransferRequest for ERC20 token..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0
							);

							const createdTransferRequest: TransferRequest = await transferRequestProtocol
								.yieldSyncV1Vault_transferRequestId_transferRequest(
									vault.address,
									0
								);

							const createdTransferRequestPoll: TransferRequestPoll = await transferRequestProtocol
								.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
									vault.address,
									0
								);

							expect(createdTransferRequest.forERC20).to.be.true;
							expect(createdTransferRequest.forERC721).to.be.false;
							expect(createdTransferRequest.creator).to.be.equal(addr1.address);
							expect(createdTransferRequest.token).to.be.equal(mockERC20.address);
							expect(createdTransferRequest.tokenId).to.be.equal(0);
							expect(createdTransferRequest.amount).to.be.equal(50);
							expect(createdTransferRequest.to).to.be.equal(addr2.address);
							expect(createdTransferRequestPoll.voteAgainstMembers.length).to.be.equal(0);
							expect(createdTransferRequestPoll.voteForMembers.length).to.be.equal(0);
						}
					);

					it(
						"Should have '0' in _openTransferRequestIds[0]..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0
							);

							expect(
								(
									await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
										vault.address
									)
								)[0]
							).to.be.equal(0);
						}
					);

					it(
						"Should have length _openTransferRequestIds of 1..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0
							);

							expect(
								(
									await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
										vault.address
									)
								).length
							).to.be.equal(1);
						}
					);
				});

				describe("vault_transferRequestId_transferRequestPollVote()", async () => {
					it(
						"Should be able vote on TransferRequest and add member to _transferRequest[].votedMembers..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							// Preset
							await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
								vault.address,
								[2, 1, secondsIn7Days] as UpdateVaultProperty
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true
							);

							const createdTransferRequestPoll: TransferRequestPoll = await transferRequestProtocol
								.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
									vault.address,
									0
								);

							expect(createdTransferRequestPoll.voteForMembers.length).to.be.equal(1);
							expect(createdTransferRequestPoll.voteForMembers[0]).to.be.equal(addr1.address);
						}
					);
				});

				describe("processTransferRequest()", async () => {
					it(
						"Should process TransferRequest for ERC20 token..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							// Preset
							await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
								vault.address,
								[2, 1, secondsIn6Days] as UpdateVaultProperty
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true
							);

							const recieverBalanceBefore: number = await mockERC20.balanceOf(addr2.address);

							// Fast-forward 6 days
							await ethers.provider.send('evm_increaseTime', [secondsIn6Days]);

							await vault.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

							const recieverBalanceAfter: number = await mockERC20.balanceOf(addr2.address);

							await expect(recieverBalanceAfter - recieverBalanceBefore).to.be.equal(50);
						}
					);
				});

				describe("invalid ERC20 transferRequest", async () => {
					it(
						"Should fail to process request but delete transferRequest..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							// Preset
							await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
								vault.address,
								[
									2,
									1,
									secondsIn6Days
								]
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								true,
								false,
								addr2.address,
								mockERC20.address,
								51,
								0
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true
							);

							const recieverBalanceBefore: number = ethers.utils.formatUnits(
								await mockERC20.balanceOf(addr2.address)
							);

							// Fast-forward 7 days
							await ethers.provider.send('evm_increaseTime', [secondsIn7Days]);

							await vault.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

							const recieverBalanceAfter: number = ethers.utils.formatUnits(
								await mockERC20.balanceOf(addr2.address)
							);

							await expect(recieverBalanceAfter).to.be.equal(recieverBalanceBefore);
						}
					);
				});
			});

			describe("Requesting ERC721 tokens", async () => {
				describe("vault_transferRequestId_transferRequestCreate", async () => {
					it(
						"Should be able to create a TransferRequest for ERC721 token..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								1
							);

							const createdTransferRequest: TransferRequest = await transferRequestProtocol
								.yieldSyncV1Vault_transferRequestId_transferRequest(
									vault.address,
									0
								);

							const createdTransferRequestPoll: TransferRequestPoll = await transferRequestProtocol
								.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
									vault.address,
									0
								);

							expect(createdTransferRequest.forERC20).to.be.false;
							expect(createdTransferRequest.forERC721).to.be.true;
							expect(createdTransferRequest.creator).to.be.equal(addr1.address);
							expect(createdTransferRequest.token).to.be.equal(mockERC721.address);
							expect(createdTransferRequest.tokenId).to.be.equal(1);
							expect(createdTransferRequest.amount).to.be.equal(1);
							expect(createdTransferRequest.to).to.be.equal(addr2.address);
							expect(createdTransferRequestPoll.voteAgainstMembers.length).to.be.equal(0);
							expect(createdTransferRequestPoll.voteForMembers.length).to.be.equal(0);
						}
					);

					it(
						"Should have '0' in _openTransferRequestIds[0]..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								1
							);

							const openTRIds: OpenTransferRequestIds = await transferRequestProtocol
								.yieldSyncV1Vault_openTransferRequestIds(
									vault.address
								);

							expect(openTRIds.length).to.be.equal(1);
							expect(openTRIds[0]).to.be.equal(0);
						}
					);
				});

				describe("vault_transferRequestId_transferRequestPollVote", async () => {
					it(
						"Should be able vote on TransferRequest and add member to _transferRequest[].votedMembers..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								1
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true
							);

							const createdTransferRequestPoll: TransferRequestPoll = await transferRequestProtocol
								.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
									vault.address,
									0
								);

							expect(createdTransferRequestPoll.voteForMembers.length).to.be.equal(1);
							expect(createdTransferRequestPoll.voteForMembers[0]).to.be.equal(addr1.address);
						}
					);
				});

				describe("processTransferRequest", async () => {
					it(
						"Should process TransferRequest for ERC721 token..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							// Preset
							await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
								vault.address,
								[2, 1, secondsIn6Days] as UpdateVaultProperty
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								1
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true
							);

							// Fast-forward 6 days
							await ethers.provider.send('evm_increaseTime', [secondsIn6Days]);

							const recieverBalanceBefore: number = await mockERC721.balanceOf(addr2.address);

							await vault.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

							const recieverBalanceAfter: number = await mockERC721.balanceOf(addr2.address);

							await expect(recieverBalanceAfter - recieverBalanceBefore).to.be.equal(1);
						}
					);
				});

				describe("invalid ERC721 transferRequest", async () => {
					it(
						"Should fail to process request but delete transferRequest..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							// Preset
							await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
								vault.address,
								[2, 1, secondsIn6Days] as UpdateVaultProperty
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								2
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true
							);

							// Fast-forward 7 days
							await ethers.provider.send('evm_increaseTime', [secondsIn7Days]);

							const recieverBalanceBefore: number = await mockERC721.balanceOf(addr2.address);

							await vault.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

							const recieverBalanceAfter: number = await mockERC721.balanceOf(addr2.address);

							await expect(
								ethers.utils.formatUnits(recieverBalanceAfter)
							).to.be.equal(ethers.utils.formatUnits(recieverBalanceBefore))
						}
					);
				});
			});
		});

		describe("[transferRequest] Against", async () => {
			describe("vault_transferRequestId_transferRequestPollVote()", async () => {
				it(
					"Should be able vote on TransferRequest and add member to _transferRequest[].votedMembers..",
					async () => {
						const [, addr1, addr2] = await ethers.getSigners();

						await transferRequestProtocol.connect(
							addr1
						).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
							vault.address,
							false,
							false,
							addr2.address,
							ethers.constants.AddressZero,
							ethers.utils.parseEther(".5"),
							0
						)

						await transferRequestProtocol.connect(
							addr1
						).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
							vault.address,
							0,
							false
						);

						const createdTransferRequestPoll: TransferRequestPoll = await transferRequestProtocol
							.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
								vault.address,
								0
							);

						expect(createdTransferRequestPoll.voteAgainstMembers.length).to.be.equal(1);
						expect(createdTransferRequestPoll.voteAgainstMembers[0]).to.be.equal(addr1.address);
					}
				);
			});

			describe("processTransferRequest()", async () => {
				it(
					"Should delete transferRequest due to againstVoteCount met..",
					async () => {
						const [, addr1, addr2] = await ethers.getSigners();

						// Preset
						await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
							vault.address,
							[1, 2, secondsIn6Days] as UpdateVaultProperty
						);

						await transferRequestProtocol.connect(addr1)
							.yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								false,
								addr2.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							)

						await transferRequestProtocol.connect(addr1)
							.yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								false
							);

						await vault.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

						const openTRIds: OpenTransferRequestIds = await transferRequestProtocol
							.yieldSyncV1Vault_openTransferRequestIds(
								vault.address
							);

						expect(openTRIds.length).to.be.equal(0);

						await expect(
							transferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
								vault.address,
								0
							)
						).to.be.rejectedWith("No TransferRequest found");
					}
				);
			});
		});

		describe("openTRIds()", async () => {
			it(
				"Should be able to keep record of multiple open TransferRequest Ids..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
							vault.address,
							true,
							false,
							addr2.address,
							mockERC20.address,
							50,
							0
						);

					await transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
							vault.address,
							true,
							false,
							addr2.address,
							mockERC20.address,
							50,
							0
						);

					const openTRIds: OpenTransferRequestIds = await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
						vault.address
					);

					expect(openTRIds[0]).to.be.equal(0);
					expect(openTRIds[1]).to.be.equal(1);
				}
			);
		});
	});


	describe("Restriction: admin (2/2)", async () => {
		describe("vault_transferRequestId_transferRequestUpdate()", async () => {
			it(
				"Should revert when amount is set to 0 or less..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
						vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const openTRIds: OpenTransferRequestIds = await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
						vault.address
					);

					const transferRequest: TransferRequest = await transferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequest(
						vault.address,
						openTRIds[openTRIds.length - 1]
					);

					const updatedTR: UpdateTransferRequest = [
						transferRequest.forERC20,
						transferRequest.forERC721,
						transferRequest.creator,
						transferRequest.to,
						transferRequest.token,
						0,
						transferRequest.created,
						transferRequest.tokenId,
					];

					await expect(
						transferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestAdminUpdate(
							vault.address,
							openTRIds[openTRIds.length - 1],
							updatedTR
						)
					).to.be.rejectedWith("!transferRequest.amount");
				}
			);

			it(
				"Should revert when forERC20 and forERC721 are BOTH true..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
						vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const openTRIds: OpenTransferRequestIds = await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
						vault.address
					);

					const transferRequest: TransferRequest = await transferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequest(
						vault.address,
						openTRIds[openTRIds.length - 1]
					);

					const updatedTR: UpdateTransferRequest = [
						true,
						true,
						transferRequest.creator,
						transferRequest.to,
						transferRequest.token,
						transferRequest.amount - 10,
						transferRequest.created,
						transferRequest.tokenId,
					];

					await expect(
						transferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestAdminUpdate(
							vault.address,
							openTRIds[openTRIds.length - 1],
							updatedTR
						)
					).to.be.rejectedWith("transferRequest.forERC20 && transferRequest.forERC721");
				}
			);

			it(
				"Should be able to update TransferRequest.amount..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
						vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const openTRIds: OpenTransferRequestIds = await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
						vault.address
					);

					const transferRequest: TransferRequest = await transferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequest(
						vault.address,
						openTRIds[openTRIds.length - 1]
					);

					const updatedTR: UpdateTransferRequest = [
						transferRequest.forERC20,
						transferRequest.forERC721,
						transferRequest.creator,
						transferRequest.to,
						transferRequest.token,
						transferRequest.amount - 10,
						transferRequest.created,
						transferRequest.tokenId,
					];

					await transferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestAdminUpdate(
						vault.address,
						openTRIds[openTRIds.length - 1],
						updatedTR
					);

					const updatedTransferRequest: TransferRequest = await transferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequest(
						vault.address,
						openTRIds[openTRIds.length - 1]
					);

					expect(updatedTransferRequest.amount).to.be.equal(transferRequest.amount - 10);
				}
			);
		});

		describe("vault_transferRequestId_transferRequestPollUpdate()", async () => {
			it(
				"Should be able to update TransferRequestPoll.forVoteCount..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
						vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const openTRIds: OpenTransferRequestIds = await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
						vault.address
					);

					const transferRequestPoll: TransferRequestPoll = await transferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
						vault.address,
						openTRIds[openTRIds.length - 1]
					);


					await transferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestPollAdminUpdate(
						vault.address,
						openTRIds[openTRIds.length - 1],
						[
							transferRequestPoll.latestForVoteTime,
							[addr2.address],
							transferRequestPoll.voteForMembers,
						] as UpdateTransferRequestPoll
					);

					const updatedTransferRequestPoll: TransferRequestPoll = await transferRequestProtocol
						.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
							vault.address,
							openTRIds[openTRIds.length - 1]
						);

					expect(updatedTransferRequestPoll.voteAgainstMembers.length).to.be.equal(1);
					expect(updatedTransferRequestPoll.voteAgainstMembers[0]).to.be.equal(addr2.address);
				}
			);

			it(
				"Should be able to update TransferRequestPoll.latestForVoteTime..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await transferRequestProtocol.connect(addr1)
						.yieldSyncV1Vault_transferRequestId_transferRequestCreate(
							vault.address,
							true,
							false,
							addr2.address,
							mockERC20.address,
							999,
							0
						);

					const openTRIds: OpenTransferRequestIds = await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
						vault.address
					);

					const transferRequestPoll: TransferRequestPoll = await transferRequestProtocol
						.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
							vault.address,
							openTRIds[openTRIds.length - 1]
						);

					await transferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestPollAdminUpdate(
						vault.address,
						openTRIds[openTRIds.length - 1],
						[
							BigInt(transferRequestPoll.latestForVoteTime) + BigInt(10),
							transferRequestPoll.voteAgainstMembers,
							transferRequestPoll.voteForMembers,
						] as UpdateTransferRequestPoll
					);

					expect(
						BigInt(transferRequestPoll.latestForVoteTime) + BigInt(10)
					).to.be.greaterThanOrEqual(
						BigInt(
							(
								await transferRequestProtocol
									.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
										vault.address,
										openTRIds[openTRIds.length - 1]
									)
							).latestForVoteTime
						)
					);
				}
			);
		});

		describe("vault_transferRequestId_transferRequestDelete()", async () => {
			it(
				"[auth] Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(
						transferRequestProtocol.connect(
							addr1
						).yieldSyncV1Vault_transferRequestId_transferRequestAdminDelete(2)
					).to.be.rejected;
				}
			);

			it(
				"Should be able to delete TransferRequest..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await transferRequestProtocol.connect(
						addr1
					).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
						vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const b4TransferRequests: OpenTransferRequestIds = await transferRequestProtocol
						.yieldSyncV1Vault_openTransferRequestIds(
							vault.address
						);


					await transferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestAdminDelete(
						vault.address,
						b4TransferRequests[b4TransferRequests.length - 1]
					);

					expect(b4TransferRequests.length - 1).to.be.equal(
						(
							await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
								vault.address
							)
						).length
					);

					await expect(
						transferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
							vault.address,
							b4TransferRequests[b4TransferRequests.length - 1]
						)
					).to.be.rejectedWith("No TransferRequest found");
				}
			);
		});
	});
});
