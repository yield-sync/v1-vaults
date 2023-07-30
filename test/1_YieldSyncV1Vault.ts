const { ethers } = require("hardhat");


import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";


const sevenDaysInSeconds = 7 * 24 * 60 * 60;
const sixDaysInSeconds = 6 * 24 * 60 * 60;


describe("[1] YieldSyncV1Vault.sol", async () => {
	let mockAdmin: Contract;
	let mockERC20: Contract;
	let mockERC721: Contract;
	let mockTransferRequestProtocol: Contract;

	let yieldSyncV1Vault: Contract;
	let yieldSyncV1VaultAccessControl: Contract;
	let yieldSyncV1VaultFactory: Contract;
	let yieldSyncV1ATransferRequestProtocol: Contract;
	let signatureProtocol: Contract;
	let mockYieldSyncGovernance: Contract;


	beforeEach("[before] Set up contracts..", async () => {
		const [owner, addr1] = await ethers.getSigners();


		// Contract Factory
		const MockAdmin: ContractFactory = await ethers.getContractFactory("MockAdmin");
		const MockERC20: ContractFactory = await ethers.getContractFactory("MockERC20");
		const MockERC721: ContractFactory = await ethers.getContractFactory("MockERC721");
		const MockTransferRequestProtocol: ContractFactory = await ethers.getContractFactory("MockTransferRequestProtocol");
		const MockYieldSyncGovernance: ContractFactory = await ethers.getContractFactory("MockYieldSyncGovernance");

		const YieldSyncV1Vault: ContractFactory = await ethers.getContractFactory("YieldSyncV1Vault");
		const YieldSyncV1VaultFactory: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultFactory");
		const YieldSyncV1VaultAccessControl: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultAccessControl");
		const YieldSyncV1ASignatureProtocol: ContractFactory = await ethers.getContractFactory("YieldSyncV1ASignatureProtocol");
		const YieldSyncV1ATransferRequestProtocol: ContractFactory = await ethers.getContractFactory("YieldSyncV1ATransferRequestProtocol");


		/// Mock
		// Governance and test contracts
		mockAdmin = await (await MockAdmin.deploy()).deployed();
		mockERC20 = await (await MockERC20.deploy()).deployed();
		mockERC721 = await (await MockERC721.deploy()).deployed();
		mockYieldSyncGovernance = await (await MockYieldSyncGovernance.deploy()).deployed();

		/// Core
		// Deploy YieldSyncV1VaultAccessControl
		yieldSyncV1VaultAccessControl = await (await YieldSyncV1VaultAccessControl.deploy()).deployed();
		// Deploy YieldSyncV1VaultFactory
		yieldSyncV1VaultFactory = await (
			await YieldSyncV1VaultFactory.deploy(mockYieldSyncGovernance.address, yieldSyncV1VaultAccessControl.address)
		).deployed();

		// Deploy YieldSyncV1ATransferRequestProtocol
		yieldSyncV1ATransferRequestProtocol = await (
			await YieldSyncV1ATransferRequestProtocol.deploy(yieldSyncV1VaultAccessControl.address)
		).deployed();

		// Deploy mockSignatureProtocol
		mockTransferRequestProtocol = await (
			await MockTransferRequestProtocol.deploy(yieldSyncV1VaultAccessControl.address)
		).deployed();

		// Deploy Signature Protocol
		signatureProtocol = await (
			await YieldSyncV1ASignatureProtocol.deploy(
				mockYieldSyncGovernance.address,
				yieldSyncV1VaultAccessControl.address
			)
		).deployed();

		// Set YieldSyncV1Vault properties on TransferRequestProtocol.sol
		await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate(
			owner.address,
			[2, 2, sixDaysInSeconds] as UpdateVaultProperty
		);

		// Preset - Set purposer signature
		await signatureProtocol.yieldSyncV1Vault_signaturesRequiredUpdate(1);

		// Deploy a vault
		await yieldSyncV1VaultFactory.deployYieldSyncV1Vault(
			signatureProtocol.address,
			yieldSyncV1ATransferRequestProtocol.address,
			[owner.address],
			[addr1.address],
			{ value: 1 }
		);

		// Attach the deployed vault's address
		yieldSyncV1Vault = await YieldSyncV1Vault.attach(
			await yieldSyncV1VaultFactory.yieldSyncV1VaultId_yieldSyncV1Vault(0)
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


	describe("Receiving tokens & ethers", async () => {
		it(
			"Should be able to recieve ether..",
			async () => {
				await expect(
					await ethers.provider.getBalance(yieldSyncV1Vault.address)
				).to.be.greaterThanOrEqual(ethers.utils.parseEther(".5"));
			}
		);

		it(
			"Should be able to recieve ERC20 tokens..",
			async () => {
				expect(await mockERC20.balanceOf(yieldSyncV1Vault.address)).to.equal(50);
			}
		);

		it(
			"Should be able to recieve ERC721 tokens..",
			async () => {
				expect(await mockERC721.balanceOf(yieldSyncV1Vault.address)).to.equal(1);
			}
		);
	});


	describe("Initial Values", async () => {
		it(
			"Should intialize againstVoteRequired as 2..",
			async () => {
				const vProp: VaultProperty = await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
					yieldSyncV1Vault.address
				);

				expect(vProp.forVoteRequired).to.equal(BigInt(2));
			}
		);

		it(
			"Should intialize forVoteRequired as 2..",
			async () => {
				const vProp: VaultProperty = await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
					yieldSyncV1Vault.address
				);

				expect(vProp.againstVoteRequired).to.equal(BigInt(2));
			}
		);

		it(
			"Should initialize transferDelaySeconds as sixDaysInSeconds..",
			async () => {
				const vProp: VaultProperty = await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
					yieldSyncV1Vault.address
				);

				expect(vProp.transferDelaySeconds).to.equal(BigInt(sixDaysInSeconds));
			}
		);

		it(
			"Should have admin set properly..",
			async () => {
				const [owner] = await ethers.getSigners();

				expect(
					(
						await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_participant_access(
							yieldSyncV1Vault.address,
							owner.address,
						)
					).admin
				).to.be.true;

				expect(
					(await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_admins(yieldSyncV1Vault.address))[0]
				).to.be.equal(owner.address);

				expect(
					(await yieldSyncV1VaultAccessControl.admin_yieldSyncV1Vaults(owner.address))[0]
				).to.be.equal(yieldSyncV1Vault.address);
			}
		);

		it(
			"Should have added members correctly..",
			async () => {
				const [, addr1] = await ethers.getSigners();

				expect(
					(await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_participant_access(
						yieldSyncV1Vault.address,
						addr1.address,
					))[1]
				).to.be.true;

				expect(
					(await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_members(yieldSyncV1Vault.address))[0]
				).to.be.equal(addr1.address);

				expect(
					(await yieldSyncV1VaultAccessControl.member_yieldSyncV1Vaults(addr1.address))[0]
				).to.be.equal(yieldSyncV1Vault.address);
			}
		);
	});


	describe("Restriction: admin (1/2)", async () => {
		describe("adminAdd()", async () => {
			it(
				"Should allow admin to add another admin..",
				async () => {
					const [, , , , addr4] = await ethers.getSigners();

					await yieldSyncV1Vault.adminAdd(addr4.address);

					expect(
						(await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_participant_access(
							yieldSyncV1Vault.address,
							addr4.address,
						))[0]
					).to.be.true;

					expect(
						(await yieldSyncV1VaultAccessControl.admin_yieldSyncV1Vaults(addr4.address))[0]
					).to.be.equal(yieldSyncV1Vault.address);


					expect(
						(await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_admins(yieldSyncV1Vault.address))[1]
					).to.be.equal(addr4.address);
				}
			);

			it(
				"Should allow admin to add a contract-based admin..",
				async () => {
					await yieldSyncV1Vault.adminAdd(mockAdmin.address);

					expect(
						(await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_participant_access(
							yieldSyncV1Vault.address,
							mockAdmin.address,
						))[0]
					).to.be.true;

					expect(
						(await yieldSyncV1VaultAccessControl.admin_yieldSyncV1Vaults(mockAdmin.address))[0]
					).to.be.equal(yieldSyncV1Vault.address);


					expect(
						(await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_admins(yieldSyncV1Vault.address))[1]
					).to.be.equal(mockAdmin.address);
				}
			);
		});

		describe("memberAdd()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await expect(yieldSyncV1Vault.connect(addr1).memberAdd(addr2.address)).to.be.rejected;
				}
			);

			it(
				"Should NOT be able to set up MEMBER role for an address that already is member..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(yieldSyncV1Vault.memberAdd(addr1.address)).to.be.rejectedWith("Already member");
				}
			);

			it(
				"Should be able to set up MEMBER role for an address..",
				async () => {
					const [, , addr2] = await ethers.getSigners();

					await yieldSyncV1Vault.memberAdd(addr2.address);

					expect(
						(await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_participant_access(
							yieldSyncV1Vault.address,
							addr2.address,
						))[1]
					).to.be.true;

					expect(
						(await yieldSyncV1VaultAccessControl.member_yieldSyncV1Vaults(addr2.address))[0]
					).to.be.equal(yieldSyncV1Vault.address);


					expect(
						(await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_members(yieldSyncV1Vault.address))[1]
					).to.be.equal(addr2.address);
				}
			);
		});

		describe("memberRemove()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(yieldSyncV1Vault.connect(addr1).memberRemove(addr1.address)).to.be.rejected;
				}
			);

			it(
				"Should be able to remove address from MEMBER role..",
				async () => {
					const [, , , , addr5] = await ethers.getSigners();

					await yieldSyncV1Vault.memberAdd(addr5.address)

					expect(
						(await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_participant_access(
							yieldSyncV1Vault.address,
							addr5.address,
						))[1]
					).to.be.true;

					await yieldSyncV1Vault.memberRemove(addr5.address)

					expect(
						(await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_participant_access(
							yieldSyncV1Vault.address,
							addr5.address,
						))[1]
					).to.be.false;
				}
			);
		});

		describe("signatureProtocolUpdate()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					// Preset
					await signatureProtocol.yieldSyncV1Vault_signaturesRequiredUpdate(2);

					await expect(
						yieldSyncV1Vault.connect(addr1).signatureProtocolUpdate(addr1.address)
					).to.be.rejected;
				}
			);

			it(
				"Should be able to set a signature manager contract..",
				async () => {
					// Preset
					await signatureProtocol.yieldSyncV1Vault_signaturesRequiredUpdate(2);

					await yieldSyncV1Vault.signatureProtocolUpdate(signatureProtocol.address);

					expect(await yieldSyncV1Vault.signatureProtocol()).to.be.equal(signatureProtocol.address);
				}
			);
		});

		describe("transferRequestProtocolUpdate()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					// Set YieldSyncV1Vault properties on TransferRequestProtocol.sol
					await mockTransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate(
						yieldSyncV1Vault.address,
						[
							2, 2, sixDaysInSeconds
						]
					);

					await expect(
						yieldSyncV1Vault.connect(addr1).transferRequestProtocolUpdate(addr1.address)
					).to.be.rejected;
				}
			);

			it(
				"Should be able to set a transferRequestProtocol contract..",
				async () => {
					const [admin] = await ethers.getSigners();

					// Set YieldSyncV1Vault properties for admin
					await mockTransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate(
						admin.address,
						[2, 2, sixDaysInSeconds]
					);

					await yieldSyncV1Vault.transferRequestProtocolUpdate(mockTransferRequestProtocol.address);

					expect(await yieldSyncV1Vault.transferRequestProtocol()).to.be.equal(
						mockTransferRequestProtocol.address
					);

					const vaultProperties: VaultProperty = await mockTransferRequestProtocol
					.yieldSyncV1Vault_yieldSyncV1VaultProperty(
						yieldSyncV1Vault.address
					);

					expect(vaultProperties.forVoteRequired).to.equal(BigInt(2));
					expect(vaultProperties.againstVoteRequired).to.equal(BigInt(2));
					expect(vaultProperties.transferDelaySeconds).to.equal(BigInt(sixDaysInSeconds));
				}
			);
		});

		describe("YieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(
						yieldSyncV1ATransferRequestProtocol.connect(
							addr1
						).yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate(
							yieldSyncV1Vault.address,
							[
								1,
								2,
								sixDaysInSeconds
							]
						)
					).to.be.rejected;
				}
			);

			it(
				"Should be able to update againstVoteRequired..",
				async () => {
					await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate(
						yieldSyncV1Vault.address,
						[
							1,
							2,
							sixDaysInSeconds
						]
					)

					const vProp: VaultProperty = await yieldSyncV1ATransferRequestProtocol
					.yieldSyncV1Vault_yieldSyncV1VaultProperty(
						yieldSyncV1Vault.address
					);

					expect(vProp.againstVoteRequired).to.equal(BigInt(1));
					expect(vProp.forVoteRequired).to.equal(BigInt(2));
					expect(vProp.transferDelaySeconds).to.equal(BigInt(sixDaysInSeconds));
				}
			);

			it(
				"Should be able to update againstVoteRequired..",
				async () => {
					await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate(
						yieldSyncV1Vault.address,
						[
							2,
							1,
							sixDaysInSeconds
						]
					)

					const vProp: VaultProperty = await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
						yieldSyncV1Vault.address
					);

					expect(vProp.againstVoteRequired).to.equal(BigInt(2));
					expect(vProp.forVoteRequired).to.equal(BigInt(1));
					expect(vProp.transferDelaySeconds).to.equal(BigInt(sixDaysInSeconds));
				}
			);

			it(
				"Should be able to update transferDelaySeconds..",
				async () => {
					// Preset
					await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate(
						yieldSyncV1Vault.address,
						[
							2,
							2,
							10
						]
					)

					const vProp: VaultProperty = await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
						yieldSyncV1Vault.address
					);

					expect(vProp.againstVoteRequired).to.equal(BigInt(2));
					expect(vProp.forVoteRequired).to.equal(BigInt(2));
					expect(vProp.transferDelaySeconds).to.equal(BigInt(10));
				}
			);
		});
	});


	describe("Restriction: member (1/1)", async () => {
		describe("memberAdd()", async () => {
			it(
				"Should NOT allow member to add another member..",
				async () => {
					const [, addr1, , , addr4] = await ethers.getSigners();

					await expect(
						yieldSyncV1Vault.connect(addr1).memberAdd(addr4.address)
					).to.be.rejected;
				}
			);
		});

		describe("transferRequests", async () => {
			describe("Requesting Ether", async () => {
				describe("yieldSyncV1Vault_transferRequestId_transferRequestCreate()", async () => {
					it(
						"Should revert when unauthorized msg.sender calls..",
						async () => {
							const [, , , , addr4] = await ethers.getSigners();

							await expect(
								yieldSyncV1ATransferRequestProtocol.connect(addr4).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
									yieldSyncV1Vault.address,
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
								yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
									yieldSyncV1Vault.address,
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
								yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
									yieldSyncV1Vault.address,
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

							await yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								yieldSyncV1Vault.address,
								false,
								false,
								addr2.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							const createdTransferRequest: TransferRequest = await yieldSyncV1ATransferRequestProtocol
							.yieldSyncV1Vault_transferRequestId_transferRequest(
								yieldSyncV1Vault.address,
								0
							);

							const createdTransferRequestPoll: TransferRequestPoll = await yieldSyncV1ATransferRequestProtocol
							.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
								yieldSyncV1Vault.address,
								0
							);

							expect(createdTransferRequest.forERC20).to.be.false;
							expect(createdTransferRequest.forERC721).to.be.false;
							expect(createdTransferRequest.creator).to.be.equal(addr1.address);
							expect(createdTransferRequest.token).to.be.equal(ethers.constants.AddressZero);
							expect(createdTransferRequest.tokenId).to.be.equal(0);
							expect(createdTransferRequest.amount).to.be.equal(ethers.utils.parseEther(".5"));
							expect(createdTransferRequest.to).to.be.equal(addr2.address);
							expect(createdTransferRequestPoll.forVoteCount).to.be.equal(0);
							expect(createdTransferRequestPoll.againstVoteCount).to.be.equal(0);
							expect(createdTransferRequestPoll.votedMembers.length).to.be.equal(0);
						}
					);

					it(
						"Should have '0' in _openTransferRequestIds[0]..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							await yieldSyncV1ATransferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								yieldSyncV1Vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							const openTransferRequestIds: OpenTransferRequestIds = await yieldSyncV1ATransferRequestProtocol
							.yieldSyncV1Vault_openTransferRequestIds(
								yieldSyncV1Vault.address
							);

							expect(openTransferRequestIds.length).to.be.equal(1);
							expect(openTransferRequestIds[0]).to.be.equal(0);
						}
					);
				});


				/**
				 * @dev yieldSyncV1Vault_transferRequestId_transferRequestPollVote
				*/
				describe("yieldSyncV1Vault_transferRequestId_transferRequestPollVote()", async () => {
					it(
						"Should revert when unauthorized msg.sender calls..",
						async () => {
							const [, addr1, , , addr4] = await ethers.getSigners();

							await yieldSyncV1ATransferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								yieldSyncV1Vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							await expect(
								yieldSyncV1ATransferRequestProtocol.connect(
									addr4
								).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
									yieldSyncV1Vault.address,
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

							await yieldSyncV1ATransferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								yieldSyncV1Vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							// Vote
							await yieldSyncV1ATransferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								yieldSyncV1Vault.address,
								0,
								true
							)

							const createdTransferRequestPoll: TransferRequestPoll = await yieldSyncV1ATransferRequestProtocol
							.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
								yieldSyncV1Vault.address,
								0
							);

							// Vote count
							expect(createdTransferRequestPoll.forVoteCount).to.be.equal(1);
							// Voted members
							expect(createdTransferRequestPoll.votedMembers[0]).to.be.equal(addr1.address);
						}
					);

					it(
						"Should revert with 'Already voted' when attempting to vote again..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							await yieldSyncV1ATransferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								yieldSyncV1Vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							// 1st vote
							await yieldSyncV1ATransferRequestProtocol.connect(
							addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								yieldSyncV1Vault.address,
								0,
								true
							)

							// Attempt 2nd vote
							await expect(
								yieldSyncV1ATransferRequestProtocol.connect(
									addr1
								).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
									yieldSyncV1Vault.address,
									0,
									true
								)
							).to.be.rejectedWith("Already voted");
						}
					);
				});

				describe("yieldSyncV1Vault_transferRequestId_transferRequestProcess()", async () => {
					it(
						"Should revert when unauthorized msg.sender calls..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1ATransferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								yieldSyncV1Vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							await yieldSyncV1ATransferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								yieldSyncV1Vault.address,
								0,
								true
							);

							await expect(
								yieldSyncV1Vault.connect(
									addr2
								).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0)
							).to.be.rejected;
						}
					);

					it(
						"Should fail to process TransferRequest because not enough votes..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							await yieldSyncV1ATransferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								yieldSyncV1Vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							await yieldSyncV1ATransferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								yieldSyncV1Vault.address,
								0,
								true
							);

							await expect(
								yieldSyncV1Vault.connect(
									addr1
								).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0)
							).to.be.rejectedWith("Transfer request pending");
						}
					);

					it(
						"Should fail to process TransferRequest because not enough time has passed..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							// Preset
							await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate(
								yieldSyncV1Vault.address,
								[
									2,
									1,
									sevenDaysInSeconds
								]
							);

							await yieldSyncV1ATransferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								yieldSyncV1Vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							await yieldSyncV1ATransferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								yieldSyncV1Vault.address,
								0,
								true
							);

							// Fast-forward 6 days
							await ethers.provider.send('evm_increaseTime', [sixDaysInSeconds]);

							await expect(
								yieldSyncV1Vault.connect(
									addr1
								).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0)
							).to.be.rejectedWith("Transfer request approved and waiting delay");
						}
					);

					it(
						"Should process TransferRequest for Ether..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							// Preset
							await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate(
								yieldSyncV1Vault.address,
								[
									2,
									1,
									sixDaysInSeconds
								]
							);

							await yieldSyncV1ATransferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								yieldSyncV1Vault.address,
								false,
								false,
								addr2.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							await yieldSyncV1ATransferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								yieldSyncV1Vault.address,
								0,
								true
							);

							// Fast-forward 6 days
							await ethers.provider.send('evm_increaseTime', [sixDaysInSeconds]);

							const recieverBalanceBefore: number = ethers.utils.formatUnits(
								await ethers.provider.getBalance(addr2.address)
							);

							await yieldSyncV1Vault.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

							const recieverBalanceAfter: number = ethers.utils.formatUnits(
								await ethers.provider.getBalance(addr2.address)
							);

							await expect(recieverBalanceAfter - recieverBalanceBefore).to.be.equal(.5);

							const openTransferRequestIds: OpenTransferRequestIds = await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
								yieldSyncV1Vault.address
							);

							expect(openTransferRequestIds.length).to.be.equal(0);
						}
					);
				});

				describe("Invalid ERC20 transferRequest", async () => {
					it(
						"Should fail to process request AND delete transferRequest after..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							// Preset
							await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate(
								yieldSyncV1Vault.address,
								[
									2,
									1,
									sevenDaysInSeconds
								]
							);

							await yieldSyncV1ATransferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								yieldSyncV1Vault.address,
								false,
								false,
								addr2.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".6"),
								0
							);

							expect(
								(
									await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
										yieldSyncV1Vault.address
									)
								).length
							).to.be.equal(1);

							await yieldSyncV1ATransferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								yieldSyncV1Vault.address,
								0,
								true
							);

							const recieverBalanceBefore: number = await ethers.provider.getBalance(addr2.address);

							// Fast-forward 7 days
							await ethers.provider.send('evm_increaseTime', [sevenDaysInSeconds]);

							await yieldSyncV1Vault.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

							const recieverBalanceAfter: number = await ethers.provider.getBalance(addr2.address);

							await expect(
								ethers.utils.formatUnits(recieverBalanceAfter)
							).to.be.equal(ethers.utils.formatUnits(recieverBalanceBefore));

							expect(
								(
									await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
										yieldSyncV1Vault.address
									)
								).length
							).to.be.equal(0);
						}
					);
				});
			});


			/**
			 * @dev Process for Transferring ERC20
			*/
			describe("Requesting ERC20 tokens", async () => {
				describe("yieldSyncV1Vault_transferRequestId_transferRequestCreate()", async () => {
					it(
						"Should be able to create a TransferRequest for ERC20 token..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1ATransferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								yieldSyncV1Vault.address,
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0
							);

							const createdTransferRequest: TransferRequest = await yieldSyncV1ATransferRequestProtocol
							.yieldSyncV1Vault_transferRequestId_transferRequest(
								yieldSyncV1Vault.address,
								0
							);

							const createdTransferRequestPoll: TransferRequestPoll = await yieldSyncV1ATransferRequestProtocol
							.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
								yieldSyncV1Vault.address,
								0
							);

							expect(createdTransferRequest.forERC20).to.be.true;
							expect(createdTransferRequest.forERC721).to.be.false;
							expect(createdTransferRequest.creator).to.be.equal(addr1.address);
							expect(createdTransferRequest.token).to.be.equal(mockERC20.address);
							expect(createdTransferRequest.tokenId).to.be.equal(0);
							expect(createdTransferRequest.amount).to.be.equal(50);
							expect(createdTransferRequest.to).to.be.equal(addr2.address);
							expect(createdTransferRequestPoll.againstVoteCount).to.be.equal(0);
							expect(createdTransferRequestPoll.forVoteCount).to.be.equal(0);
							expect(createdTransferRequestPoll.votedMembers.length).to.be.equal(0);
						}
					);

					it(
						"Should have '0' in _openTransferRequestIds[0]..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1ATransferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								yieldSyncV1Vault.address,
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0
							);

							expect(
								(
									await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
										yieldSyncV1Vault.address
									)
								)[0]
							).to.be.equal(0);
						}
					);

					it(
						"Should have length _openTransferRequestIds of 1..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1ATransferRequestProtocol.connect(
								addr1
							).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								yieldSyncV1Vault.address,
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0
							);

							expect(
								(
									await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
										yieldSyncV1Vault.address
									)
								).length
							).to.be.equal(1);
						}
					);
				});

				describe("yieldSyncV1Vault_transferRequestId_transferRequestPollVote()", async () => {
					it(
						"Should be able vote on TransferRequest and add member to _transferRequest[].votedMembers..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							// Preset
							await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate(
								yieldSyncV1Vault.address,
								[
									2,
									1,
									sevenDaysInSeconds
								]
							);

							await yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								yieldSyncV1Vault.address,
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0
							);

							await yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								yieldSyncV1Vault.address,
								0,
								true
							);

							const createdTransferRequestPoll: TransferRequestPoll = await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
								yieldSyncV1Vault.address,
								0
							);

							expect(createdTransferRequestPoll.forVoteCount).to.be.equal(1);
							expect(createdTransferRequestPoll.votedMembers[0]).to.be.equal(addr1.address);
						}
					);
				});

				describe("processTransferRequest()", async () => {
					it(
						"Should process TransferRequest for ERC20 token..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							// Preset
							await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate(
								yieldSyncV1Vault.address,
								[
									2,
									1,
									sixDaysInSeconds
								]
							);

							await yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								yieldSyncV1Vault.address,
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0
							);

							await yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								yieldSyncV1Vault.address,
								0,
								true
							);

							const recieverBalanceBefore: number = await mockERC20.balanceOf(addr2.address);

							// Fast-forward 6 days
							await ethers.provider.send('evm_increaseTime', [sixDaysInSeconds]);

							await yieldSyncV1Vault.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

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
							await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate(
								yieldSyncV1Vault.address,
								[
									2,
									1,
									sixDaysInSeconds
								]
							);

							await yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								yieldSyncV1Vault.address,
								true,
								false,
								addr2.address,
								mockERC20.address,
								51,
								0
							);

							await yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								yieldSyncV1Vault.address,
								0,
								true
							);

							const recieverBalanceBefore: number = ethers.utils.formatUnits(
								await mockERC20.balanceOf(addr2.address)
							);

							// Fast-forward 7 days
							await ethers.provider.send('evm_increaseTime', [sevenDaysInSeconds]);

							await yieldSyncV1Vault.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

							const recieverBalanceAfter: number = ethers.utils.formatUnits(
								await mockERC20.balanceOf(addr2.address)
							);

							await expect(recieverBalanceAfter).to.be.equal(recieverBalanceBefore);
						}
					);
				});
			});


			describe("Requesting ERC721 tokens", async () => {
				describe("yieldSyncV1Vault_transferRequestId_transferRequestCreate", async () => {
					it(
						"Should be able to create a TransferRequest for ERC721 token..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								yieldSyncV1Vault.address,
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								1
							);

							const createdTransferRequest: TransferRequest = await yieldSyncV1ATransferRequestProtocol
							.yieldSyncV1Vault_transferRequestId_transferRequest(
								yieldSyncV1Vault.address,
								0
							);

							const createdTransferRequestPoll: TransferRequestPoll = await yieldSyncV1ATransferRequestProtocol
							.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
								yieldSyncV1Vault.address,
								0
							);

							expect(createdTransferRequest.forERC20).to.be.false;
							expect(createdTransferRequest.forERC721).to.be.true;
							expect(createdTransferRequest.creator).to.be.equal(addr1.address);
							expect(createdTransferRequest.token).to.be.equal(mockERC721.address);
							expect(createdTransferRequest.tokenId).to.be.equal(1);
							expect(createdTransferRequest.amount).to.be.equal(1);
							expect(createdTransferRequest.to).to.be.equal(addr2.address);
							expect(createdTransferRequestPoll.againstVoteCount).to.be.equal(0);
							expect(createdTransferRequestPoll.forVoteCount).to.be.equal(0);
							expect(createdTransferRequestPoll.votedMembers.length).to.be.equal(0);
						}
					);

					it(
						"Should have '0' in _openTransferRequestIds[0]..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								yieldSyncV1Vault.address,
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								1
							);

							const openTransferRequestIds: OpenTransferRequestIds = await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
								yieldSyncV1Vault.address
							);

							expect(openTransferRequestIds.length).to.be.equal(1);
							expect(openTransferRequestIds[0]).to.be.equal(0);
						}
					);
				});


				describe("yieldSyncV1Vault_transferRequestId_transferRequestPollVote", async () => {
					it(
						"Should be able vote on TransferRequest and add member to _transferRequest[].votedMembers..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								yieldSyncV1Vault.address,
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								1
							);

							await yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								yieldSyncV1Vault.address,
								0,
								true
							);

							const createdTransferRequestPoll: TransferRequestPoll = await yieldSyncV1ATransferRequestProtocol
							.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
								yieldSyncV1Vault.address,
								0
							);

							expect(createdTransferRequestPoll.forVoteCount).to.be.equal(1);
							expect(createdTransferRequestPoll.votedMembers[0]).to.be.equal(addr1.address);
						}
					);
				});


				describe("processTransferRequest", async () => {
					it(
						"Should process TransferRequest for ERC721 token..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							// Preset
							await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate(
								yieldSyncV1Vault.address,
								[
									2,
									1,
									sixDaysInSeconds
								]
							);

							await yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								yieldSyncV1Vault.address,
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								1
							);

							await yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								yieldSyncV1Vault.address,
								0,
								true
							);

							// Fast-forward 6 days
							await ethers.provider.send('evm_increaseTime', [sixDaysInSeconds]);

							const recieverBalanceBefore: number = await mockERC721.balanceOf(addr2.address);

							await yieldSyncV1Vault.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

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
							await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate(
								yieldSyncV1Vault.address,
								[
									2,
									1,
									sixDaysInSeconds
								]
							);

							await yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
								yieldSyncV1Vault.address,
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								2
							);

							await yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
								yieldSyncV1Vault.address,
								0,
								true
							);

							// Fast-forward 7 days
							await ethers.provider.send('evm_increaseTime', [sevenDaysInSeconds]);

							const recieverBalanceBefore: number = await mockERC721.balanceOf(addr2.address);

							await yieldSyncV1Vault.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

							const recieverBalanceAfter: number = await mockERC721.balanceOf(addr2.address);

							await expect(
								ethers.utils.formatUnits(recieverBalanceAfter)
							).to.be.equal(ethers.utils.formatUnits(recieverBalanceBefore))
						}
					);
				});
			});
		});

		describe("transferRequest Against", async () => {
			describe("yieldSyncV1Vault_transferRequestId_transferRequestPollVote()", async () => {
				it(
					"Should be able vote on TransferRequest and add member to _transferRequest[].votedMembers..",
					async () => {
						const [, addr1, addr2] = await ethers.getSigners();

						await yieldSyncV1ATransferRequestProtocol.connect(
							addr1
						).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
							yieldSyncV1Vault.address,
							false,
							false,
							addr2.address,
							ethers.constants.AddressZero,
							ethers.utils.parseEther(".5"),
							0
						)

						await yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
							yieldSyncV1Vault.address,
							0,
							false
						);

						const createdTransferRequestPoll: TransferRequestPoll = await yieldSyncV1ATransferRequestProtocol
						.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
							yieldSyncV1Vault.address,
							0
						);

						expect(createdTransferRequestPoll.againstVoteCount).to.be.equal(1);
						expect(createdTransferRequestPoll.votedMembers[0]).to.be.equal(addr1.address);
					}
				);
			});

			describe("processTransferRequest()", async () => {
				it(
					"Should delete transferRequest due to againstVoteCount met..",
					async () => {
						const [, addr1, addr2] = await ethers.getSigners();

						// Preset
						await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultPropertyUpdate(
							yieldSyncV1Vault.address,
							[
								1,
								2,
								sixDaysInSeconds
							]
						);

						await yieldSyncV1ATransferRequestProtocol.connect(addr1)
						.yieldSyncV1Vault_transferRequestId_transferRequestCreate(
							yieldSyncV1Vault.address,
							false,
							false,
							addr2.address,
							ethers.constants.AddressZero,
							ethers.utils.parseEther(".5"),
							0
						)

						await yieldSyncV1ATransferRequestProtocol.connect(addr1)
						.yieldSyncV1Vault_transferRequestId_transferRequestPollVote(
							yieldSyncV1Vault.address,
							0,
							false
						);

						await yieldSyncV1Vault.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestProcess(0);

						const openTransferRequestIds: OpenTransferRequestIds = await yieldSyncV1ATransferRequestProtocol
						.yieldSyncV1Vault_openTransferRequestIds(
							yieldSyncV1Vault.address
						);

						expect(openTransferRequestIds.length).to.be.equal(0);

						await expect(
							yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
								yieldSyncV1Vault.address,
								0
							)
						).to.be.rejectedWith("No TransferRequest found");
					}
				);
			});
		});

		describe("openTransferRequestIds()", async () => {
			it(
				"Should be able to keep record of multiple open TransferRequest Ids..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await yieldSyncV1ATransferRequestProtocol.connect(addr1)
					.yieldSyncV1Vault_transferRequestId_transferRequestCreate(
						yieldSyncV1Vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						50,
						0
					);

					await yieldSyncV1ATransferRequestProtocol.connect(addr1).
					yieldSyncV1Vault_transferRequestId_transferRequestCreate(
						yieldSyncV1Vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						50,
						0
					);

					const openTransferRequestIds: OpenTransferRequestIds = await yieldSyncV1ATransferRequestProtocol
					.yieldSyncV1Vault_openTransferRequestIds(
						yieldSyncV1Vault.address
					);

					expect(openTransferRequestIds[0]).to.be.equal(0);
					expect(openTransferRequestIds[1]).to.be.equal(1);
				}
			);
		});

		describe("renounceMembership()", async () => {
			it(
				"Should allow members to leave a vault..",
				async () => {
					const [, , , , , , addr6] = await ethers.getSigners();

					await yieldSyncV1Vault.memberAdd(addr6.address);

					const vaultsBefore = await yieldSyncV1VaultAccessControl.member_yieldSyncV1Vaults(addr6.address)

					let found: boolean = false;

					for (let i = 0; i < vaultsBefore.length; i++)
					{
						if (vaultsBefore[i] === yieldSyncV1Vault.address) found = true;
					}

					expect(found).to.be.true;

					await yieldSyncV1Vault.connect(addr6).renounceMembership();

					const vaultsAfter = await yieldSyncV1VaultAccessControl.member_yieldSyncV1Vaults(addr6.address)

					for (let i = 0; i < vaultsAfter.length; i++)
					{
						expect(vaultsAfter[i]).to.not.equal(yieldSyncV1Vault.address);
					}
				}
			);
		});
	});


	describe("Restriction: admin (2/2)", async () => {
		describe("yieldSyncV1Vault_transferRequestId_transferRequestUpdate()", async () => {
			it(
				"Should revert when amount is set to 0 or less..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
						yieldSyncV1Vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const openTransferRequestIds: OpenTransferRequestIds = await yieldSyncV1ATransferRequestProtocol
					.yieldSyncV1Vault_openTransferRequestIds(
						yieldSyncV1Vault.address
					);

					const transferRequest: TransferRequest = await yieldSyncV1ATransferRequestProtocol
					.yieldSyncV1Vault_transferRequestId_transferRequest(
						yieldSyncV1Vault.address,
						openTransferRequestIds[openTransferRequestIds.length - 1]
					);

					const updatedTR: UpdatedTransferRequest = [
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
						yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestUpdate(
							yieldSyncV1Vault.address,
							openTransferRequestIds[openTransferRequestIds.length - 1],
							updatedTR
						)
					).to.be.rejectedWith("!transferRequest.amount");
				}
			);

			it(
				"Should revert when forERC20 and forERC721 are BOTH true..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await yieldSyncV1ATransferRequestProtocol.connect(addr1)
					.yieldSyncV1Vault_transferRequestId_transferRequestCreate(
						yieldSyncV1Vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const openTransferRequestIds: OpenTransferRequestIds = await yieldSyncV1ATransferRequestProtocol
					.yieldSyncV1Vault_openTransferRequestIds(
						yieldSyncV1Vault.address
					);

					const transferRequest: TransferRequest = await yieldSyncV1ATransferRequestProtocol
					.yieldSyncV1Vault_transferRequestId_transferRequest(
						yieldSyncV1Vault.address,
						openTransferRequestIds[openTransferRequestIds.length - 1]
					);

					const updatedTR: UpdatedTransferRequest = [
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
						yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestUpdate(
							yieldSyncV1Vault.address,
							openTransferRequestIds[openTransferRequestIds.length - 1],
							updatedTR
						)
					).to.be.rejectedWith("transferRequest.forERC20 && transferRequest.forERC721");
				}
			);

			it(
				"Should be able to update TransferRequest.amount..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
						yieldSyncV1Vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const openTransferRequestIds: OpenTransferRequestIds = await yieldSyncV1ATransferRequestProtocol
					.yieldSyncV1Vault_openTransferRequestIds(
						yieldSyncV1Vault.address
					);

					const transferRequest: TransferRequest = await yieldSyncV1ATransferRequestProtocol
					.yieldSyncV1Vault_transferRequestId_transferRequest(
						yieldSyncV1Vault.address,
						openTransferRequestIds[openTransferRequestIds.length - 1]
					);

					const updatedTR: UpdatedTransferRequest = [
						transferRequest.forERC20,
						transferRequest.forERC721,
						transferRequest.creator,
						transferRequest.to,
						transferRequest.token,
						transferRequest.amount - 10,
						transferRequest.created,
						transferRequest.tokenId,
					];

					await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestUpdate(
						yieldSyncV1Vault.address,
						openTransferRequestIds[openTransferRequestIds.length - 1],
						updatedTR
					);

					const updatedTransferRequest: TransferRequest = await yieldSyncV1ATransferRequestProtocol
					.yieldSyncV1Vault_transferRequestId_transferRequest(
						yieldSyncV1Vault.address,
						openTransferRequestIds[openTransferRequestIds.length - 1]
					);

					expect(updatedTransferRequest.amount).to.be.equal(transferRequest.amount - 10);
				}
			);
		});

		describe("yieldSyncV1Vault_transferRequestId_transferRequestPollUpdate()", async () => {
			it(
				"Should be able to update TransferRequestPoll.forVoteCount..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
						yieldSyncV1Vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const openTransferRequestIds: OpenTransferRequestIds = await yieldSyncV1ATransferRequestProtocol
					.yieldSyncV1Vault_openTransferRequestIds(
						yieldSyncV1Vault.address
					);

					const transferRequestPoll: TransferRequestPoll = await yieldSyncV1ATransferRequestProtocol
					.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
						yieldSyncV1Vault.address,
						openTransferRequestIds[openTransferRequestIds.length - 1]
					);


					await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestPollUpdate(
						yieldSyncV1Vault.address,
						openTransferRequestIds[openTransferRequestIds.length - 1],
						[
							transferRequestPoll.againstVoteCount + 1,
							transferRequestPoll.forVoteCount,
							transferRequestPoll.latestForVoteTime,
							transferRequestPoll.votedMembers,
						] as UpdatedTransferRequestPoll
					);

					const updatedTransferRequestPoll: TransferRequestPoll = await yieldSyncV1ATransferRequestProtocol
					.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
						yieldSyncV1Vault.address,
						openTransferRequestIds[openTransferRequestIds.length - 1]
					);

					expect(updatedTransferRequestPoll.againstVoteCount).to.be.equal(1);
				}
			);

			it(
				"Should be able to update TransferRequestPoll.latestForVoteTime..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await yieldSyncV1ATransferRequestProtocol.connect(addr1)
					.yieldSyncV1Vault_transferRequestId_transferRequestCreate(
						yieldSyncV1Vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const openTransferRequestIds: OpenTransferRequestIds = await yieldSyncV1ATransferRequestProtocol
					.yieldSyncV1Vault_openTransferRequestIds(
						yieldSyncV1Vault.address
					);

					const transferRequestPoll: TransferRequestPoll = await yieldSyncV1ATransferRequestProtocol
					.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
						yieldSyncV1Vault.address,
						openTransferRequestIds[openTransferRequestIds.length - 1]
					);

					await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestPollUpdate(
						yieldSyncV1Vault.address,
						openTransferRequestIds[openTransferRequestIds.length - 1],
						[
							transferRequestPoll.againstVoteCount + 1,
							transferRequestPoll.forVoteCount,
							BigInt(transferRequestPoll.latestForVoteTime) + BigInt(10),
							transferRequestPoll.votedMembers,
						]
					);

					expect(
						BigInt(transferRequestPoll.latestForVoteTime) + BigInt(10)
					).to.be.greaterThanOrEqual(
						BigInt(
							(
								await yieldSyncV1ATransferRequestProtocol
								.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
									yieldSyncV1Vault.address,
									openTransferRequestIds[openTransferRequestIds.length - 1]
								)
							).latestForVoteTime
						)
					);
				}
			);
		});


		describe("yieldSyncV1Vault_transferRequestId_transferRequestDelete()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(
						yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestDelete(2)
					).to.be.rejected;
				}
			);

			it(
				"Should be able to delete TransferRequest..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await yieldSyncV1ATransferRequestProtocol.connect(addr1).yieldSyncV1Vault_transferRequestId_transferRequestCreate(
						yieldSyncV1Vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const beforeTransferRequests: OpenTransferRequestIds = await yieldSyncV1ATransferRequestProtocol
					.yieldSyncV1Vault_openTransferRequestIds(
						yieldSyncV1Vault.address
					);


					await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestDelete(
						yieldSyncV1Vault.address,
						beforeTransferRequests[beforeTransferRequests.length - 1]
					);

					expect(beforeTransferRequests.length - 1).to.be.equal(
						(
							await yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
								yieldSyncV1Vault.address
							)
						).length
					);

					await expect(
						yieldSyncV1ATransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestPoll(
							yieldSyncV1Vault.address,
							beforeTransferRequests[beforeTransferRequests.length - 1]
						)
					).to.be.rejectedWith("No TransferRequest found");
				}
			);
		});
	});
});
