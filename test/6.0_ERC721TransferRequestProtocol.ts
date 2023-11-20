type UpdateERC721VaultProperty = [
	string,
	number,
	number
];

type ERC721VaultProperty = {
	erc721Token: string,
	voteAgainstRequired: number,
	voteForRequired: number,
}

// Transfer Request Poll
type ERC721TransferRequestPoll = {
	voteAgainstErc721TokenId: string[],
	voteForErc721TokenId: string[],
};

type UpdateERC721TransferRequestPoll = [
	// voteAgainstErc721TokenId
	string[],
	// voteForErc721TokenId
	string[],
];


const { ethers } = require("hardhat");


import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";


const secondsIn7Days = 24 * 60 * 60 * 7;
const secondsIn6Days = 24 * 60 * 60 * 6;


describe("[6.0] YieldSyncV1Vault.sol with YieldSyncV1ERC721TransferRequestProtocol", async () => {
	const initialVoteForRequired: number = 4;
	const initialVoteAgainstRequired: number = 4;

	let mockAdmin: Contract;
	let mockERC20: Contract;
	let mockERC721: Contract;

	let vault: Contract;
	let Registry: Contract;
	let Deployer: Contract;
	let transferRequestProtocol: Contract;
	let mockYieldSyncGovernance: Contract;

	let addr1NFTs: number[] = [];
	let addr2NFTs: number[] = [];


	beforeEach("[beforeEach] Set up contracts..", async () => {
		const [owner, addr1, addr2] = await ethers.getSigners();

		// Contract Deployer
		const MockAdmin: ContractFactory = await ethers.getContractFactory("MockAdmin");
		const MockERC20: ContractFactory = await ethers.getContractFactory("MockERC20");
		const MockERC721: ContractFactory = await ethers.getContractFactory("MockERC721");
		const MockYieldSyncGovernance: ContractFactory = await ethers.getContractFactory("MockYieldSyncGovernance");

		const YieldSyncV1Vault: ContractFactory = await ethers.getContractFactory("YieldSyncV1Vault");
		const YieldSyncV1VaultDeployer: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultDeployer");
		const YieldSyncV1VaultRegistry: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultRegistry");
		const YieldSyncV1ERC721TransferRequestProtocol: ContractFactory = await ethers.getContractFactory(
			"YieldSyncV1ERC721TransferRequestProtocol"
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
		// Deploy YieldSyncV1VaultDeployer
		Deployer = await (
			await YieldSyncV1VaultDeployer.deploy(mockYieldSyncGovernance.address, Registry.address)
		).deployed();

		// Deploy YieldSyncV1ERC721TransferRequestProtocol
		transferRequestProtocol = await (
			await YieldSyncV1ERC721TransferRequestProtocol.deploy(Registry.address)
		).deployed();

		// Set YieldSyncV1Vault properties on TransferRequestProtocol.sol
		await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
			owner.address,
			[mockERC721.address, initialVoteAgainstRequired, initialVoteForRequired,] as UpdateERC721VaultProperty
		);

		// Deploy a vault
		await Deployer.deployYieldSyncV1Vault(
			ethers.constants.AddressZero,
			transferRequestProtocol.address,
			[owner.address,],
			[],
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
		await mockERC721.transferFrom(owner.address, vault.address, 0);

		// Send ERC721 to addr1 contract
		await mockERC721.transferFrom(owner.address, addr1.address, 1);
		await mockERC721.transferFrom(owner.address, addr1.address, 2);
		addr1NFTs = [1, 2];

		// Send ERC721 to addr1 contract
		await mockERC721.transferFrom(owner.address, addr2.address, 3);
		await mockERC721.transferFrom(owner.address, addr2.address, 4);
		addr2NFTs = [3, 4];
	});


	describe("[yieldSyncV1ATransferRequestProtocol] Expected Failures", async () => {
		describe("Initiator must have property set before deploying vault", async () => {
			it(
				"Should fail to deploy a vault without setting initiator property first..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					const vProp: ERC721VaultProperty = await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
						addr1.address
					);

					// Expect values to not be set before testing
					expect(vProp.erc721Token).to.equal(ethers.constants.AddressZero);
					expect(vProp.voteForRequired).to.equal(BigInt(0));
					expect(vProp.voteAgainstRequired).to.equal(BigInt(0));

					// fail to deploy a vault
					await expect(
						Deployer.connect(addr1).deployYieldSyncV1Vault(
							ethers.constants.AddressZero,
							transferRequestProtocol.address,
							[addr1.address,],
							[addr1.address,],
							{ value: 1 }
						)
					).to.be.rejectedWith("!_yieldSyncV1Vault_yieldSyncV1VaultProperty[_initiator].erc721Token");
				}
			);
		});

		describe("When initiator sets properties, erc721Token != address(0)", async () => {
			it(
				"Should fail to set erc721Token on addr1 yieldSyncV1VaultProperty to address(0)..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					// Fail to set vault property with invalid values
					await expect(
						transferRequestProtocol.connect(addr1).yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
							addr1.address,
							[ethers.constants.AddressZero, 1, 1] as UpdateERC721VaultProperty
						)
					).to.be.rejectedWith("!_yieldSyncV1VaultProperty.erc721Token");
				}
			);
		});

		describe("When initiator sets properties, they must be >0", async () => {
			it(
				"Should fail to set voteAgainstRequired on addr1 yieldSyncV1VaultProperty to 0..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					// Fail to set vault property with invalid values
					await expect(
						transferRequestProtocol.connect(addr1).yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
							addr1.address,
							[mockERC721.address, 0, 0] as UpdateERC721VaultProperty
						)
					).to.be.rejectedWith("!_yieldSyncV1VaultProperty.voteAgainstRequired");
				}
			);

			it(
				"Should fail to set voteForRequired on addr1 yieldSyncV1VaultProperty to 0..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					// Fail to set vault property with invalid values
					await expect(
						transferRequestProtocol.connect(addr1).yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
							addr1.address,
							[mockERC721.address, 1, 0,] as UpdateERC721VaultProperty
						)
					).to.be.rejectedWith("!_yieldSyncV1VaultProperty.voteForRequired");
				}
			);
		});
	});

	describe("[yieldSyncV1ATransferRequestProtocol] Initial Values", async () => {
		it(
			`Should intialize voteAgainstRequired as ${initialVoteAgainstRequired}..`,
			async () => {
				const [owner] = await ethers.getSigners();

				const vProp: ERC721VaultProperty = await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
					vault.address
				);

				expect(vProp.voteAgainstRequired).to.equal(BigInt(initialVoteAgainstRequired));
			}
		);

		it(
			`Should intialize voteForRequired as ${initialVoteForRequired}..`,
			async () => {
				const vProp: ERC721VaultProperty = await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
					vault.address
				);

				expect(vProp.voteForRequired).to.equal(BigInt(initialVoteForRequired));
			}
		);
	});

	describe("Restriction: ERC 721 token-holder (1/1)", async () => {
		describe("[transferRequest] For", async () => {
			describe("Requesting Ether", async () => {
				describe("vault_transferRequestId_transferRequestCreate()", async () => {
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
							).to.be.rejectedWith("!_amount");
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
							).to.be.rejectedWith("_forERC20 && _forERC721");
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

							const transferRequest: TransferRequest = await transferRequestProtocol
							.yieldSyncV1Vault_transferRequestId_transferRequest(
								vault.address,
								0
							);

							const transferRequestPoll: ERC721TransferRequestPoll = await transferRequestProtocol
							.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
								vault.address,
								0
							);

							expect(transferRequest.forERC20).to.be.false;
							expect(transferRequest.forERC721).to.be.false;
							expect(transferRequest.creator).to.be.equal(addr1.address);
							expect(transferRequest.token).to.be.equal(ethers.constants.AddressZero);
							expect(transferRequest.tokenId).to.be.equal(0);
							expect(transferRequest.amount).to.be.equal(ethers.utils.parseEther(".5"));
							expect(transferRequest.to).to.be.equal(addr2.address);
							expect(transferRequestPoll.voteForErc721TokenId.length).to.be.equal(0);
							expect(transferRequestPoll.voteAgainstErc721TokenId.length).to.be.equal(0);
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
						"Should be able vote on TransferRequest & add token ids to _transferRequest[].voteForErc721TokenId..",
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
								true,
								addr1NFTs
							);

							const createdTransferRequestPoll: ERC721TransferRequestPoll = await transferRequestProtocol
								.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
									vault.address,
									0
								);

							// Vote count
							expect(createdTransferRequestPoll.voteForErc721TokenId.length).to.be.equal(addr1NFTs.length);

							for (let i = 0; i < addr1NFTs.length; i++) {
								expect(createdTransferRequestPoll.voteForErc721TokenId[i]).to.be.equal(addr1NFTs[i]);

							}
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

							// 1st vote (should yield success)
							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true,
								addr1NFTs
							);

							const transferRequestPoll: ERC721TransferRequestPoll = await transferRequestProtocol
								.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
									vault.address,
									0
								);

							// Vote count
							expect(transferRequestPoll.voteForErc721TokenId.length).to.be.equal(addr1NFTs.length);

							for (let i = 0; i < addr1NFTs.length; i++) {
								expect(transferRequestPoll.voteForErc721TokenId[i]).to.be.equal(addr1NFTs[i]);

							}

							// Attempt 2nd vote
							await expect(
								transferRequestProtocol.connect(
									addr1
								).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
									vault.address,
									0,
									true,
									addr1NFTs
								)
							).to.be.rejectedWith("Already voted");
						}
					);

					it(
						"Should revert with 'Already voted' when attempting to insert same token id into array twice..",
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

							const doubledUpTokenIds: number[] = [...addr1NFTs, ...addr1NFTs];

							// Bad attempt
							await expect(
								transferRequestProtocol.connect(
									addr1
								).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
									vault.address,
									0,
									true,
									doubledUpTokenIds
								)
							).to.be.rejectedWith("Already voted");
						}
					);

					it(
						"Should revert when vote is cast with ids of tokens not owned..",
						async () => {
							const [, addr1, , addr3] = await ethers.getSigners();

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

							// Bad attempt
							await expect(
								transferRequestProtocol.connect(
									addr3
								).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
									vault.address,
									0,
									true,
									addr1NFTs
								)
							).to.be.rejectedWith(
								"IERC721(yieldSyncV1VaultProperty.erc721Token).ownerOf(_tokenIds[i]) != msg.sender"
							);
						}
					);

					it(
						"Should revert when a token has already been voted with but attempted to be voted with again by new owner..",
						async () => {
							const [, addr1, , addr3] = await ethers.getSigners();

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
								true,
								addr1NFTs
							);

							await mockERC721.connect(addr1).transferFrom(addr1.address, addr3.address, addr1NFTs[0]);

							// 1st vote
							await expect(
								transferRequestProtocol.connect(
									addr3
								).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
									vault.address,
									0,
									true,
									[addr1NFTs[0]]
								)
							).to.be.rejectedWith("Already voted");
						}
					);
				});

				describe("vault_transferRequestId_transferRequestProcess()", async () => {
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
								true,
								addr1NFTs
							);

							await expect(
								vault.connect(
									addr1
								).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0)
							).to.be.rejectedWith("TransferRequest pending");
						}
					);

					it(
						"Should process TransferRequest for Ether..",
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
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true,
								addr1NFTs
							);

							await transferRequestProtocol.connect(
								addr2
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true,
								addr2NFTs
							);

							// Fast-forward 6 days
							await ethers.provider.send('evm_increaseTime', [secondsIn6Days]);

							const receiverBalanceBefore: number = ethers.utils.formatUnits(
								await ethers.provider.getBalance(addr2.address)
							);

							await vault.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

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

							// Preset
							await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
								vault.address,
								[
									mockERC721.address,
									2,
									1,
								] as UpdateERC721VaultProperty
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
								true,
								addr1NFTs,
							);

							const receiverBalanceBefore: number = await ethers.provider.getBalance(addr2.address);

							// Fast-forward 7 days
							await ethers.provider.send('evm_increaseTime', [secondsIn7Days]);

							await vault.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

							const receiverBalanceAfter: number = await ethers.provider.getBalance(addr2.address);

							await expect(
								ethers.utils.formatUnits(receiverBalanceAfter)
							).to.be.equal(
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

							const createdTransferRequestPoll: ERC721TransferRequestPoll = await transferRequestProtocol
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
							expect(createdTransferRequestPoll.voteAgainstErc721TokenId.length).to.be.equal(0);
							expect(createdTransferRequestPoll.voteForErc721TokenId.length).to.be.equal(0);
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
						"Should be able vote on TransferRequest and add token ids to _transferRequest[].voteForErc721TokenId..",
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

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true,
								addr1NFTs,
							);

							const createdTransferRequestPoll: ERC721TransferRequestPoll = await transferRequestProtocol
								.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
									vault.address,
									0
								);

							expect(createdTransferRequestPoll.voteForErc721TokenId.length).to.be.equal(addr1NFTs.length);

							for (let i = 0; i < addr1NFTs.length; i++) {
								expect(
									createdTransferRequestPoll.voteForErc721TokenId[i]
								).to.be.equal(
									addr1NFTs[i]
								);
							}
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
								[
									mockERC721.address,
									2,
									1,
								] as UpdateERC721VaultProperty
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
								true,
								addr1NFTs,
							);

							const receiverBalanceBefore: number = await mockERC20.balanceOf(addr2.address);

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

							// Preset
							await transferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyAdminUpdate(
								vault.address,
								[
									mockERC721.address,
									2,
									1,
								] as UpdateERC721VaultProperty
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
								true,
								addr1NFTs
							);

							const receiverBalanceBefore: number = ethers.utils.formatUnits(
								await mockERC20.balanceOf(addr2.address)
							);

							await vault.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

							const receiverBalanceAfter: number = ethers.utils.formatUnits(
								await mockERC20.balanceOf(addr2.address)
							);

							await expect(receiverBalanceAfter).to.be.equal(receiverBalanceBefore);
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

							const createdTransferRequestPoll: ERC721TransferRequestPoll = await transferRequestProtocol
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
							expect(createdTransferRequestPoll.voteAgainstErc721TokenId.length).to.be.equal(0);
							expect(createdTransferRequestPoll.voteForErc721TokenId.length).to.be.equal(0);
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
						"Should be able vote on TransferRequest and add token ids to _transferRequest[].voteForErc721TokenId..",
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
								true,
								addr1NFTs,
							);

							const createdTransferRequestPoll: ERC721TransferRequestPoll = await transferRequestProtocol
								.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
									vault.address,
									0
								);

							expect(createdTransferRequestPoll.voteForErc721TokenId.length).to.be.equal(addr1NFTs.length);

							for (let i = 0; i < addr1NFTs.length; i++) {
								expect(
									createdTransferRequestPoll.voteForErc721TokenId[i]
								).to.be.equal(
									addr1NFTs[i]
								);
							}
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
								[
									mockERC721.address,
									2,
									1,
								] as UpdateERC721VaultProperty
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
								0
							);

							await transferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								vault.address,
								0,
								true,
								addr1NFTs,
							);

							const receiverBalanceBefore: number = await mockERC721.balanceOf(addr2.address);

							await vault.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

							const receiverBalanceAfter: number = await mockERC721.balanceOf(addr2.address);

							await expect(receiverBalanceAfter - receiverBalanceBefore).to.be.equal(1);
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
								[
									mockERC721.address,
									2,
									1,
								] as UpdateERC721VaultProperty
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
								true,
								addr1NFTs,
							);

							const receiverBalanceBefore: number = await mockERC721.balanceOf(addr2.address);

							await vault.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

							const receiverBalanceAfter: number = await mockERC721.balanceOf(addr2.address);

							await expect(
								ethers.utils.formatUnits(receiverBalanceAfter)
							).to.be.equal(
								ethers.utils.formatUnits(receiverBalanceBefore)
							)
						}
					);
				});
			});
		});

		describe("[transferRequest] Against", async () => {
			describe("vault_transferRequestId_transferRequestPollVote()", async () => {
				it(
					"Should be able vote on TransferRequest and add member to _transferRequestPoll[].voteAgainstErc721TokenId..",
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
							false,
							addr1NFTs,
						);

						const transferRequestPoll: ERC721TransferRequestPoll = await transferRequestProtocol
							.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
								vault.address,
								0
							);

						expect(transferRequestPoll.voteAgainstErc721TokenId.length).to.be.equal(addr1NFTs.length);

						for (let i = 0; i < addr1NFTs.length; i++) {
							expect(
								transferRequestPoll.voteAgainstErc721TokenId[i]
							).to.be.equal(
								addr1NFTs[i]
							);
						}
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
							[
								mockERC721.address,
								1,
								2,
							] as UpdateERC721VaultProperty
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
								false,
								addr1NFTs,
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
					).to.be.rejectedWith("!_transferRequest.amount");
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
					).to.be.rejectedWith("_transferRequest.forERC20 && _transferRequest.forERC721");
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
				"Should be able to update ERC721TransferRequestPoll.voteForErc721TokenId..",
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

					const transferRequestPoll: ERC721TransferRequestPoll = await transferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
						vault.address,
						openTRIds[openTRIds.length - 1]
					);


					await transferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestPollAdminUpdate(
						vault.address,
						openTRIds[openTRIds.length - 1],
						[
							["0"],
							transferRequestPoll.voteForErc721TokenId,
						] as UpdateERC721TransferRequestPoll
					);

					const updatedTransferRequestPoll: ERC721TransferRequestPoll = await transferRequestProtocol
						.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
							vault.address,
							openTRIds[openTRIds.length - 1]
						);

					expect(updatedTransferRequestPoll.voteAgainstErc721TokenId.length).to.be.equal(1);
					expect(updatedTransferRequestPoll.voteAgainstErc721TokenId[0]).to.be.equal(0);
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
