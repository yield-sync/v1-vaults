// Trandfer Request Status
type TransferRequestStatus = {
	readyToBeProcessed: boolean,
	approved: boolean,
	message: string,
};

type UpdateV1BVaultProperty = [
	// voteAgainstRequired
	number,
	// voteForRequired
	number,
	// maxVotePeriodSeconds
	number,
	// minVotePeriodSeconds
	number,
];

// Vault properties
type V1BVaultProperty = {
	voteAgainstRequired: number,
	voteForRequired: number,
	maxVotePeriodSeconds: number,
	minVotePeriodSeconds: number,
}

// Transfer Request Poll
type V1BTransferRequestPoll = {
	voteCloseTimestamp: number,
	voteAgainstMembers: string[],
	voteForMembers: string[],
};

type UpdateV1BTransferRequestPoll = [
	// latestForVoteTime
	number | bigint,
	// voteAgainstMembers
	string[],
	// voteForMembers
	string[],
];


const { ethers } = require("hardhat");


import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";


const secondsIn8Days = 24 * 60 * 60 * 8;
const secondsIn7Days = 24 * 60 * 60 * 7;
const secondsIn6Days = 24 * 60 * 60 * 6;
const secondsIn5Days = 24 * 60 * 60 * 5;


describe("[5.0] YieldSyncV1Vault.sol with YieldSyncV1BTransferRequestProtocol", async () => {
	let mockAdmin: Contract;
	let mockERC20: Contract;
	let mockERC721: Contract;

	let vault: Contract;
	let Registry: Contract;
	let Deployer: Contract;
	let transferRequestProtocol: Contract;
	let mockYieldSyncGovernance: Contract;

	beforeEach("[beforeEach] Set up contracts..", async () => {
		const [owner, addr1] = await ethers.getSigners();

		// Contract Deployer
		const MockAdmin: ContractFactory = await ethers.getContractFactory("MockAdmin");
		const MockERC20: ContractFactory = await ethers.getContractFactory("MockERC20");
		const MockERC721: ContractFactory = await ethers.getContractFactory("MockERC721");
		const MockYieldSyncGovernance: ContractFactory = await ethers.getContractFactory("MockYieldSyncGovernance");

		const YieldSyncV1Vault: ContractFactory = await ethers.getContractFactory("YieldSyncV1Vault");
		const YieldSyncV1VaultDeployer: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultDeployer");
		const YieldSyncV1VaultRegistry: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultRegistry");
		const YieldSyncV1BTransferRequestProtocol: ContractFactory = await ethers.getContractFactory("YieldSyncV1BTransferRequestProtocol");

		/// Mock
		// Governance and test contracts
		mockAdmin = await (await MockAdmin.deploy()).deployed();
		mockERC20 = await (await MockERC20.deploy()).deployed();
		mockERC721 = await (await MockERC721.deploy()).deployed();
		mockYieldSyncGovernance = await (await MockYieldSyncGovernance.deploy()).deployed();

		/// Core
		// Deploy YieldSyncV1VaultRegistry
		Registry = await (await YieldSyncV1VaultRegistry.deploy()).deployed();
		// Deploy YieldSyncV1VaultDeployer
		Deployer = await (
			await YieldSyncV1VaultDeployer.deploy(mockYieldSyncGovernance.address, Registry.address)
		).deployed();

		// Deploy YieldSyncV1BTransferRequestProtocol
		transferRequestProtocol = await (await YieldSyncV1BTransferRequestProtocol.deploy(Registry.address)).deployed();

		// Set YieldSyncV1Vault properties on TransferRequestProtocol.sol
		await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
			owner.address,
			[2, 2, secondsIn7Days, secondsIn6Days] as UpdateV1BVaultProperty
		);

		// Deploy a vault
		await Deployer.deployYieldSyncV1Vault(
			ethers.constants.AddressZero,
			transferRequestProtocol.address,
			[owner.address],
			[addr1.address],
			{ value: 1 }
		);

		// Attach the deployed vault's address
		vault = await YieldSyncV1Vault.attach(await Deployer.yieldSyncV1VaultId_yieldSyncV1Vault(0));

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

					const vProp: V1BVaultProperty = await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
						addr1.address
					);

					expect(vProp.voteForRequired).to.equal(BigInt(0));
					expect(vProp.voteAgainstRequired).to.equal(BigInt(0));
					expect(vProp.maxVotePeriodSeconds).to.equal(0);
					expect(vProp.minVotePeriodSeconds).to.equal(0);

					// fail to deploy a vault
					await expect(
						Deployer.connect(addr1).deployYieldSyncV1Vault(
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

		describe("When initiator sets properties, the following must be > 0", async () => {
			it(
				"Should fail to set voteAgainstRequired to 0..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					// fail to deploy a vault
					await expect(
						transferRequestProtocol.connect(addr1).yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
							addr1.address,
							[0, 0, secondsIn7Days, secondsIn6Days] as UpdateV1BVaultProperty
						)
					).to.be.rejectedWith("!yieldSyncV1VaultProperty.voteAgainstRequired");
				}
			);

			it(
				"Should fail to set voteForRequired to 0..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					// fail to deploy a vault
					await expect(
						transferRequestProtocol.connect(addr1).yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
							addr1.address,
							[1, 0, secondsIn7Days, secondsIn6Days] as UpdateV1BVaultProperty
						)
					).to.be.rejectedWith("!yieldSyncV1VaultProperty.voteForRequired");
				}
			);
		});
	});


	describe("[yieldSyncV1BTransferRequestProtocol] Initial Values", async () => {
		it(
			"Should intialize voteAgainstRequired as 2..",
			async () => {
				const vProp: V1BVaultProperty = await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
					vault.address
				);

				expect(vProp.voteForRequired).to.equal(BigInt(2));
			}
		);

		it(
			"Should intialize voteForRequired as 2..",
			async () => {
				const vProp: V1BVaultProperty = await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
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
						[123, 456, 789, 987] as UpdateV1BVaultProperty
					)
				).to.be.rejected;
			}
		);

		it("Should allow admin to update vault propreties..", async () => {
			const [owner] = await ethers.getSigners();

			// Preset
			await transferRequestProtocol.connect(owner).yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
				vault.address,
				[123, 456, 789, 987] as UpdateV1BVaultProperty
			);

			const vProp: V1BVaultProperty = await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
				vault.address
			);

			expect(vProp.voteAgainstRequired).to.equal(123);
			expect(vProp.voteForRequired).to.equal(456);
			expect(vProp.maxVotePeriodSeconds).to.equal(789);
			expect(vProp.minVotePeriodSeconds).to.equal(987);
		});
	});

	describe("Restriction: member (1/1)", async () => {
		describe("[transferRequest] For", async () => {
			describe("Requesting Ether", async () => {
				describe("vault_transferRequestId_transferRequestCreate()", async () => {
					describe("Expected failures", async () => {
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
										0,
										(await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days
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
										0,
										(await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days
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
										0,
										(await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days
									)
								).to.be.rejectedWith("forERC20 && forERC721");
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
										0,
										(await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days
									)
								).to.be.rejectedWith("forERC20 && forERC721");
							}
						);

						it(
							"Should revert when voteCloseTimestamp exceeds maxVotePeriodSeconds..",
							async () => {
								const [, addr1] = await ethers.getSigners();

								await expect(
									transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
										vault.address,
										false,
										false,
										addr1.address,
										ethers.constants.AddressZero,
										1,
										0,
										(await ethers.provider.getBlock("latest")).timestamp + secondsIn8Days
									)
								).to.be.rejectedWith("!voteCloseTimestamp");
							}
						);

						it(
							"Should revert when voteCloseTimestamp less than minVotePeriodSeconds..",
							async () => {
								const [, addr1] = await ethers.getSigners();

								await expect(
									transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
										vault.address,
										false,
										false,
										addr1.address,
										ethers.constants.AddressZero,
										1,
										0,
										(await ethers.provider.getBlock("latest")).timestamp + secondsIn5Days
									)
								).to.be.rejectedWith("!voteCloseTimestamp");
							}
						);
					});

					it(
						"Should be able to create a TransferRequest for Ether..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								false,
								addr2.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0,
								voteCloseTimestamp
							);

							const createdTransferRequest: TransferRequest = await transferRequestProtocol
							.yieldSyncV1Vault_transferRequestId_transferRequest(
								vault.address,
								0
							);

							const createdTransferRequestPoll: V1BTransferRequestPoll = await transferRequestProtocol
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

							expect(createdTransferRequestPoll.voteCloseTimestamp).to.be.equal(voteCloseTimestamp);
							expect(createdTransferRequestPoll.voteAgainstMembers.length).to.be.equal(0);
							expect(createdTransferRequestPoll.voteForMembers.length).to.be.equal(0);
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
								0,
								(await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days
							);

							const openTRIds: OpenTransferRequestIds = await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
								vault.address
							);

							expect(openTRIds.length).to.be.equal(1);
							expect(openTRIds[0]).to.be.equal(0);
						}
					);
				});

				describe("yieldSyncV1Vault_transferRequestId_transferRequestDelete()", async () => {
					it(
						"[auth] Should not allow !creator to delete TransferRequest..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await vault.memberAdd(addr2.address)

							await transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								false,
								addr2.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0,
								(await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days
							);

							const beforeOpenTRIds: OpenTransferRequestIds = await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
								vault.address
							);

							expect(beforeOpenTRIds.length).to.be.equal(1);
							expect(beforeOpenTRIds[0]).to.be.equal(0);


							await expect(
								transferRequestProtocol.connect(addr2).yieldSyncV1Vault_transferRequestId_transferRequestDelete(
									vault.address,
									0
								)
							).to.be.rejectedWith("_yieldSyncV1Vault_transferRequestId_transferRequest[yieldSyncV1Vault][transferRequestId].creator != msg.sender");

							const openTRIds: OpenTransferRequestIds = await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
								vault.address
							);

							expect(openTRIds.length).to.be.equal(1);
							expect(beforeOpenTRIds[0]).to.be.equal(0);
						}
					);

					it(
						"Should be able to delete a TransferRequest..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								false,
								addr2.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0,
								(await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days
							);

							const beforeOpenTRIds: OpenTransferRequestIds = await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
								vault.address
							);

							expect(beforeOpenTRIds.length).to.be.equal(1);
							expect(beforeOpenTRIds[0]).to.be.equal(0);


							await transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestDelete(
								vault.address,
								0
							);

							const openTRIds: OpenTransferRequestIds = await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
								vault.address
							);

							expect(openTRIds.length).to.be.equal(0);
						}
					);
				});

				describe("vault_transferRequestId_transferRequestPollVote()", async () => {
					it(
						"[auth] Should revert when unauthorized msg.sender calls..",
						async () => {
							const [, addr1, , , addr4] = await ethers.getSigners();

							const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0,
								voteCloseTimestamp
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

							const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0,
								voteCloseTimestamp
							);

							// Vote
							await transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true
							)

							const createdTransferRequestPoll: V1BTransferRequestPoll = await transferRequestProtocol
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

							const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0,
								voteCloseTimestamp
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
							).to.be.rejectedWith("votedForPreviously");
						}
					);
				});

				describe("vault_transferRequestId_transferRequestProcess()", async () => {
					it(
						"[auth] Should revert when unauthorized msg.sender calls..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0,
								voteCloseTimestamp
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
						"Should fail to process TransferRequest because not enough time has passed..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							// Preset
							await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
								vault.address,
								[2, 1, secondsIn7Days, secondsIn6Days] as UpdateV1BVaultProperty
							);

							const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0,
								voteCloseTimestamp
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
								vault.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0)
							).to.be.rejectedWith("Voting not closed");
						}
					);

					it(
						"Should fail to process TransferRequest because not enough votes..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							// Balance Before
							const receiverBalanceBefore: number = ethers.utils.formatUnits(
								await ethers.provider.getBalance(addr2.address)
							);

							const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								false,
								addr2.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0,
								voteCloseTimestamp
							);

							// 1st vote
							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true
							);

							// Fast-forward 6 days
							await ethers.provider.send('evm_increaseTime', [secondsIn7Days]);

							await vault.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

							// Balance After
							const receiverBalanceAfter: number = ethers.utils.formatUnits(
								await ethers.provider.getBalance(addr2.address)
							);

							expect(receiverBalanceBefore).to.be.equal(receiverBalanceAfter);
						}
					);

					it(
						"Should process TransferRequest for Ether..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							const receiverBalanceBefore: number = ethers.utils.formatUnits(
								await ethers.provider.getBalance(addr2.address)
							);

							const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

							// Preset
							await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
								vault.address,
								[2, 1, secondsIn7Days, secondsIn6Days] as UpdateV1BVaultProperty
							);

							// Create transferRequest
							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								false,
								addr2.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0,
								voteCloseTimestamp
							);

							// 1st vote
							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true
							);

							// Fast-forward 7 days
							await ethers.provider.send('evm_increaseTime', [secondsIn7Days]);

							await vault.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

							const receiverBalanceAfter: number = ethers.utils.formatUnits(
								await ethers.provider.getBalance(addr2.address)
							);

							await expect(receiverBalanceAfter - receiverBalanceBefore).to.be.equal(.5);

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

							const receiverBalanceBefore: number = await ethers.provider.getBalance(addr2.address);

							const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

							// Preset
							await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
								vault.address,
								[2, 1, secondsIn7Days, secondsIn6Days] as UpdateV1BVaultProperty
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
								0,
								voteCloseTimestamp
							);

							const openTRIds: OpenTransferRequestIds = await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
								vault.address
							)

							expect(openTRIds.length).to.be.equal(1);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true
							);

							// Fast-forward 7 days
							await ethers.provider.send('evm_increaseTime', [secondsIn7Days]);

							await vault.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

							const receiverBalanceAfter: number = await ethers.provider.getBalance(addr2.address);

							await expect(ethers.utils.formatUnits(receiverBalanceAfter)).to.be.equal(
								ethers.utils.formatUnits(receiverBalanceBefore)
							);

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

							const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0,
								voteCloseTimestamp
							);

							const createdTransferRequest: TransferRequest = await transferRequestProtocol
								.yieldSyncV1Vault_transferRequestId_transferRequest(
									vault.address,
									0
								);

							const createdTransferRequestPoll: V1BTransferRequestPoll = await transferRequestProtocol
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

							expect(createdTransferRequestPoll.voteCloseTimestamp).to.be.equal(voteCloseTimestamp);
							expect(createdTransferRequestPoll.voteAgainstMembers.length).to.be.equal(0);
							expect(createdTransferRequestPoll.voteForMembers.length).to.be.equal(0);
						}
					);

					it(
						"Should have '0' in _openTransferRequestIds[0]..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0,
								voteCloseTimestamp
							);

							const openTRIds: OpenTransferRequestIds = await transferRequestProtocol
								.yieldSyncV1Vault_openTransferRequestIds(
									vault.address
								);

							expect(openTRIds[0]).to.be.equal(0);
						}
					);

					it(
						"Should have length _openTransferRequestIds of 1..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0,
								voteCloseTimestamp
							);

							const openTRIds: OpenTransferRequestIds = await transferRequestProtocol
								.yieldSyncV1Vault_openTransferRequestIds(
									vault.address
								);

							expect(openTRIds.length).to.be.equal(1);
						}
					);
				});

				describe("vault_transferRequestId_transferRequestPollVote()", async () => {
					it(
						"Should be able vote on TransferRequest and add member to _transferRequest[].voteForMembers..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

							// Preset
							await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
								vault.address,
								[2, 1, secondsIn7Days, secondsIn6Days] as UpdateV1BVaultProperty
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
								0,
								voteCloseTimestamp
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true
							);

							const createdTransferRequestPoll: V1BTransferRequestPoll = await transferRequestProtocol
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

							const receiverBalanceBefore: number = await mockERC20.balanceOf(addr2.address);

							const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

							// Preset
							await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
								vault.address,
								[2, 1, secondsIn7Days, secondsIn6Days] as UpdateV1BVaultProperty
							);

							// Create
							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0,
								voteCloseTimestamp
							);

							// 1st vote
							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true
							);

							// Fast-forward 6 days
							await ethers.provider.send('evm_increaseTime', [secondsIn7Days]);

							await vault.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

							const receiverBalanceAfter: number = await mockERC20.balanceOf(addr2.address);

							await expect(receiverBalanceAfter - receiverBalanceBefore).to.be.equal(50);
						}
					);
				});

				describe("invalid ERC20 transferRequest", async () => {
					it(
						"Should fail to process request but delete transferRequest..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							const receiverBalanceBefore: number = ethers.utils.formatUnits(
								await mockERC20.balanceOf(addr2.address)
							);

							const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

							// Preset
							await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
								vault.address,
								[2, 1, secondsIn7Days, secondsIn6Days] as UpdateV1BVaultProperty
							);

							// Create transferRequest
							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								true,
								false,
								addr2.address,
								mockERC20.address,
								51,
								0,
								voteCloseTimestamp
							);

							// 1st vote
							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true
							);

							// Fast-forward 7 days
							await ethers.provider.send('evm_increaseTime', [secondsIn7Days]);

							await vault.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

							const receiverBalanceAfter: number = ethers.utils.formatUnits(
								await mockERC20.balanceOf(addr2.address)
							);

							await expect(receiverBalanceAfter).to.be.equal(receiverBalanceBefore);

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

			describe("Requesting ERC721 tokens", async () => {
				describe("vault_transferRequestId_transferRequestCreate", async () => {
					it(
						"Should be able to create a TransferRequest for ERC721 token..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								1,
								voteCloseTimestamp
							);

							const createdTransferRequest: TransferRequest = await transferRequestProtocol
								.yieldSyncV1Vault_transferRequestId_transferRequest(
									vault.address,
									0
								);

							const createdTransferRequestPoll: V1BTransferRequestPoll = await transferRequestProtocol
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

							expect(createdTransferRequestPoll.voteCloseTimestamp).to.be.equal(voteCloseTimestamp);
							expect(createdTransferRequestPoll.voteAgainstMembers.length).to.be.equal(0);
							expect(createdTransferRequestPoll.voteForMembers.length).to.be.equal(0);
						}
					);

					it(
						"Should have '0' in _openTransferRequestIds[0]..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

							await transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								1,
								voteCloseTimestamp
							);

							const openTRIds: OpenTransferRequestIds = await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
								vault.address
							);

							expect(openTRIds.length).to.be.equal(1);
							expect(openTRIds[0]).to.be.equal(0);
						}
					);
				});

				describe("vault_transferRequestId_transferRequestPollVote", async () => {
					it(
						"Should be able vote on TransferRequest and add member to _transferRequest[].voteForMembers..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								1,
								voteCloseTimestamp
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true
							);

							const createdTransferRequestPoll: V1BTransferRequestPoll = await transferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
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

							const receiverBalanceBefore: number = await mockERC721.balanceOf(addr2.address);

							const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

							// Preset
							await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
								vault.address,
								[2, 1, secondsIn7Days, secondsIn6Days] as UpdateV1BVaultProperty
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
								1,
								voteCloseTimestamp
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true
							);

							// Fast-forward 6 days
							await ethers.provider.send('evm_increaseTime', [secondsIn7Days]);

							await vault.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

							const receiverBalanceAfter: number = await mockERC721.balanceOf(addr2.address);

							await expect(receiverBalanceAfter - receiverBalanceBefore).to.be.equal(1);

							const openTRIds: OpenTransferRequestIds = await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
								vault.address
							);

							expect(openTRIds.length).to.be.equal(0);
						}
					);
				});

				describe("invalid ERC721 transferRequest", async () => {
					it(
						"Should fail to process request but delete transferRequest..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

							// Preset
							await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
								vault.address,
								[2, 1, secondsIn7Days, secondsIn6Days] as UpdateV1BVaultProperty
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
								2,
								voteCloseTimestamp
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

							const receiverBalanceBefore: number = await mockERC721.balanceOf(addr2.address);

							await vault.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

							const receiverBalanceAfter: number = await mockERC721.balanceOf(addr2.address);

							await expect(
								ethers.utils.formatUnits(receiverBalanceAfter)
							).to.be.equal(ethers.utils.formatUnits(receiverBalanceBefore))
						}
					);
				});
			});
		});

		describe("[transferRequest] Against", async () => {
			describe("vault_transferRequestId_transferRequestPollVote()", async () => {
				it(
					"Should be able vote on TransferRequest and add member to _transferRequest[].voteAgainstMembers..",
					async () => {
						const [, addr1, addr2] = await ethers.getSigners();

						const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

						await transferRequestProtocol.connect(
							addr1
						).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
							vault.address,
							false,
							false,
							addr2.address,
							ethers.constants.AddressZero,
							ethers.utils.parseEther(".5"),
							0,
							voteCloseTimestamp
						)

						await transferRequestProtocol.connect(
							addr1
						).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
							vault.address,
							0,
							false
						);

						const createdTransferRequestPoll: V1BTransferRequestPoll = await transferRequestProtocol
						.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
							vault.address,
							0
						);

						expect(createdTransferRequestPoll.voteAgainstMembers.length).to.be.equal(1);
						expect(createdTransferRequestPoll.voteAgainstMembers[0]).to.be.equal(addr1.address);
					}
				);

				it(
					"Should be able to vote AGAINST, wait for voting to close and have status set properly..",
					async () => {
						const [, addr1, addr2] = await ethers.getSigners();

						const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

						// Preset
						await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
							vault.address,
							[1, 2, secondsIn7Days, secondsIn6Days] as UpdateV1BVaultProperty
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
							0,
							voteCloseTimestamp
						)

						await transferRequestProtocol.connect(
							addr1
						).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
							vault.address,
							0,
							false
						);

						// Fast-forward 7 days
						await ethers.provider.send('evm_increaseTime', [secondsIn7Days]);

						const createdTransferRequestPoll: V1BTransferRequestPoll = await transferRequestProtocol
						.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
							vault.address,
							0
						);

						// Send ether to update state of chain
						await addr1.sendTransaction({
							to: vault.address,
							value: ethers.utils.parseEther(".000000001")
						});

						const status: TransferRequestStatus = await transferRequestProtocol
						.yieldSyncV1Vault_transferRequestId_transferRequestStatus(
							vault.address,
							0
						);

						expect(status.readyToBeProcessed).to.be.true;
						expect(status.approved).to.be.false;
						expect(status.message).to.be.equal("TransferRequest denied");
					}
				)
			});

			describe("processTransferRequest()", async () => {
				it(
					"Should delete transferRequest due to againstVoteCount met..",
					async () => {
						const [, addr1, addr2] = await ethers.getSigners();

						const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

						// Preset
						await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
							vault.address,
							[1, 2, secondsIn7Days, secondsIn6Days] as UpdateV1BVaultProperty
						);

						await transferRequestProtocol.connect(addr1)
							.yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								vault.address,
								false,
								false,
								addr2.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0,
								voteCloseTimestamp
							)

						await transferRequestProtocol.connect(
							addr1
						).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
							vault.address,
							0,
							false
						);

						// Fast-forward 7 days
						await ethers.provider.send('evm_increaseTime', [secondsIn7Days]);

						await vault.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

						const openTRIds: OpenTransferRequestIds = await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
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

					const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

					await transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
							vault.address,
							true,
							false,
							addr2.address,
							mockERC20.address,
							50,
							0,
							voteCloseTimestamp
						);

					await transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
							vault.address,
							true,
							false,
							addr2.address,
							mockERC20.address,
							50,
							0,
							voteCloseTimestamp
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

					const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

					await transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
						vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0,
						voteCloseTimestamp
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

					const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

					await transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
						vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0,
						voteCloseTimestamp
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

					const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

					await transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
						vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0,
						voteCloseTimestamp
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
				"Should be able to update TransferRequestPoll.voteForMembers..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

					await transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
						vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0,
						voteCloseTimestamp
					);

					const openTRIds: OpenTransferRequestIds = await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
						vault.address
					);

					const transferRequestPoll: V1BTransferRequestPoll = await transferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
						vault.address,
						openTRIds[openTRIds.length - 1]
					);


					await transferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestPollAdminUpdate(
						vault.address,
						openTRIds[openTRIds.length - 1],
						[
							voteCloseTimestamp,
							transferRequestPoll.voteAgainstMembers,
							[addr2.address],
						] as UpdateV1BTransferRequestPoll
					);

					const updatedTransferRequestPoll: V1BTransferRequestPoll = await transferRequestProtocol
						.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
							vault.address,
							openTRIds[openTRIds.length - 1]
						);

					expect(updatedTransferRequestPoll.voteForMembers[0]).to.be.equal(addr2.address);
				}
			);

			it(
				"Should be able to update TransferRequestPoll.latestForVoteTime..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					const voteCloseTimestampAfter = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

					await transferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
						vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0,
						(await ethers.provider.getBlock("latest")).timestamp + secondsIn6Days + 10
					);

					const openTRIds: OpenTransferRequestIds = await transferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
						vault.address
					);

					// Get the latest transferRequest
					const transferRequestPoll: V1BTransferRequestPoll = await transferRequestProtocol
						.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
							vault.address,
							openTRIds[openTRIds.length - 1]
						);

					await transferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestPollAdminUpdate(
						vault.address,
						openTRIds[openTRIds.length - 1],
						[
							voteCloseTimestampAfter,
							transferRequestPoll.voteAgainstMembers,
							transferRequestPoll.voteForMembers,
						] as UpdateV1BTransferRequestPoll
					);

					const updatedTransferRequestPoll: V1BTransferRequestPoll = await transferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
						vault.address,
						openTRIds[openTRIds.length - 1]
					);

					expect(updatedTransferRequestPoll.voteCloseTimestamp).to.be.equal(voteCloseTimestampAfter);
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

					const voteCloseTimestamp = (await ethers.provider.getBlock("latest")).timestamp + secondsIn7Days;

					await transferRequestProtocol.connect(
						addr1
					).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
						vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0,
						voteCloseTimestamp
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
