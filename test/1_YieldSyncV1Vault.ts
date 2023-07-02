import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";

const { ethers } = require("hardhat");


const sevenDaysInSeconds = 7 * 24 * 60 * 60;
const sixDaysInSeconds = 6 * 24 * 60 * 60;


describe("[1] YieldSyncV1Vault.sol - YieldSync V1 Vault Contract", async () => {
	let yieldSyncV1Vault: Contract;
	let yieldSyncV1VaultAccessControl: Contract;
	let yieldSyncV1VaultFactory: Contract;
	let yieldSyncV1VaultTransferRequest: Contract;
	let signatureManager: Contract;
	let mockAdmin: Contract;
	let mockERC20: Contract;
	let mockERC721: Contract;
	let mockYieldSyncGovernance: Contract;

	beforeEach("[before] Set up contracts..", async () => {
		const [owner, addr1] = await ethers.getSigners();


		// Contract Factory
		const MockAdmin: ContractFactory = await ethers.getContractFactory("MockAdmin");
		const MockERC20: ContractFactory = await ethers.getContractFactory("MockERC20");
		const MockERC721: ContractFactory = await ethers.getContractFactory("MockERC721");

		const MockYieldSyncGovernance: ContractFactory = await ethers.getContractFactory("MockYieldSyncGovernance");
		const YieldSyncV1Vault: ContractFactory = await ethers.getContractFactory("YieldSyncV1Vault");
		const YieldSyncV1VaultFactory: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultFactory");
		const YieldSyncV1VaultAccessControl: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultAccessControl");
		const SignatureManager: ContractFactory = await ethers.getContractFactory("SignatureManager");
		const YieldSyncV1VaultTransferRequest: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultTransferRequest");


		// Contract
		mockAdmin = await (await MockAdmin.deploy()).deployed();
		mockERC20 = await (await MockERC20.deploy()).deployed();
		mockERC721 = await (await MockERC721.deploy()).deployed();

		mockYieldSyncGovernance = await (await MockYieldSyncGovernance.deploy()).deployed();
		yieldSyncV1VaultAccessControl = await (await YieldSyncV1VaultAccessControl.deploy()).deployed();
		yieldSyncV1VaultFactory = await (
			await YieldSyncV1VaultFactory.deploy(mockYieldSyncGovernance.address, yieldSyncV1VaultAccessControl.address)
		).deployed();

		yieldSyncV1VaultTransferRequest = await (
			await YieldSyncV1VaultTransferRequest.deploy(
				yieldSyncV1VaultAccessControl.address,
				yieldSyncV1VaultTransferRequest.address
			)
		).deployed();

		// Deploy a vault
		await yieldSyncV1VaultFactory.deployYieldSyncV1Vault(
			[addr1.address],
			[addr1.address],
			ethers.constants.AddressZero,
			ethers.constants.AddressZero,
			true,
			true,
			2,
			2,
			sixDaysInSeconds,
			{ value: 1 }
		);

		// Attach the deployed vault's address
		yieldSyncV1Vault = await YieldSyncV1Vault.attach(
			await yieldSyncV1VaultFactory.yieldSyncV1VaultId_yieldSyncV1VaultAddress(0)
		);

		signatureManager = await (
			await SignatureManager.deploy(mockYieldSyncGovernance.address, yieldSyncV1VaultAccessControl.address)
		).deployed();

		// Send ether to YieldSyncV1Vault contract
		await addr1.sendTransaction({ to: yieldSyncV1Vault.address, value: ethers.utils.parseEther(".5") });

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
			"Should intialize againstVoteCountRequired as 2..",
			async () => {
				expect(await yieldSyncV1Vault.againstVoteCountRequired()).to.equal(2);
			}
		);

		it(
			"Should intialize forVoteCountRequired as 2..",
			async () => {
				expect(await yieldSyncV1Vault.forVoteCountRequired()).to.equal(2);
			}
		);

		it(
			"Should initialize transferDelaySeconds as sixDaysInSeconds..",
			async () => {
				expect(await yieldSyncV1Vault.transferDelaySeconds()).to.equal(sixDaysInSeconds);
			}
		);

		it(
			"Should have admin set properly..",
			async () => {
				const [owner] = await ethers.getSigners();

				expect(
					(await yieldSyncV1VaultAccessControl.participant_yieldSyncV1Vault_access(
						owner.address,
						yieldSyncV1Vault.address
					))[0]
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
					(await yieldSyncV1VaultAccessControl.participant_yieldSyncV1Vault_access(
						addr1.address,
						yieldSyncV1Vault.address
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


	describe("Restriction: DEFAULT_ADMIN_ROLE", async () => {
		describe("addAdmin()", async () => {
			it(
				"Should allow admin to add another admin..",
				async () => {
					const [, , , , addr4] = await ethers.getSigners();

					await yieldSyncV1Vault.addAdmin(addr4.address);

					expect(
						(await yieldSyncV1VaultAccessControl.participant_yieldSyncV1Vault_access(
							addr4.address,
							yieldSyncV1Vault.address
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
					await yieldSyncV1Vault.addAdmin(mockAdmin.address);

					expect(
						(await yieldSyncV1VaultAccessControl.participant_yieldSyncV1Vault_access(
							mockAdmin.address,
							yieldSyncV1Vault.address
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

		describe("addMember()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await expect(yieldSyncV1Vault.connect(addr1).addMember(addr2.address)).to.be.rejected;
				}
			);

			it(
				"Should NOT be able to set up MEMBER role for an address that already is member..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(yieldSyncV1Vault.addMember(addr1.address)).to.be.rejectedWith("Already member");
				}
			);

			it(
				"Should be able to set up MEMBER role for an address..",
				async () => {
					const [, , addr2] = await ethers.getSigners();

					await yieldSyncV1Vault.addMember(addr2.address);

					expect(
						(await yieldSyncV1VaultAccessControl.participant_yieldSyncV1Vault_access(
							addr2.address,
							yieldSyncV1Vault.address
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

		describe("removeMember()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(yieldSyncV1Vault.connect(addr1).removeMember(addr1.address)).to.be.rejected;
				}
			);

			it(
				"Should be able to remove address from MEMBER role..",
				async () => {
					const [, , , , addr5] = await ethers.getSigners();

					await yieldSyncV1Vault.addMember(addr5.address)

					expect(
						(await yieldSyncV1VaultAccessControl.participant_yieldSyncV1Vault_access(
							addr5.address,
							yieldSyncV1Vault.address
						))[1]
					).to.be.true;

					await yieldSyncV1Vault.removeMember(addr5.address)

					expect(
						(await yieldSyncV1VaultAccessControl.participant_yieldSyncV1Vault_access(
							addr5.address,
							yieldSyncV1Vault.address
						))[1]
					).to.be.false;
				}
			);
		});

		describe("updateSignatureManager()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(
						yieldSyncV1Vault.connect(addr1).updateSignatureManager(addr1.address)
					).to.be.rejected;
				}
			);

			it(
				"Should be able to set a signature manager contract..",
				async () => {

					await yieldSyncV1Vault.updateSignatureManager(signatureManager.address);

					expect(await yieldSyncV1Vault.signatureManager()).to.be.equal(signatureManager.address);
				}
			);
		});

		describe("updateAgainstVoteCountRequired()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(yieldSyncV1Vault.connect(addr1).updateAgainstVoteCountRequired(1)).to.be.rejected;
				}
			);

			it(
				"Should be able to update againstVoteCountRequired..",
				async () => {
					await yieldSyncV1Vault.updateAgainstVoteCountRequired(1)

					await expect(await yieldSyncV1Vault.againstVoteCountRequired()).to.be.equal(1);
				}
			);
		});


		describe("updateForVoteCountRequired()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(yieldSyncV1Vault.connect(addr1).updateForVoteCountRequired(1)).to.be.rejected;
				}
			);

			it(
				"Should be able to update forVoteCountRequired..",
				async () => {
					await yieldSyncV1Vault.updateForVoteCountRequired(1)

					await expect(await yieldSyncV1Vault.forVoteCountRequired()).to.be.equal(1);
				}
			);
		});


		describe("updateTransferDelaySeconds()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(
						yieldSyncV1Vault.connect(addr1).updateTransferDelaySeconds(sevenDaysInSeconds)
					).to.be.rejected;
				}
			);

			it(
				"Should be able to update transferDelaySeconds..",
				async () => {
					await yieldSyncV1Vault.updateTransferDelaySeconds(sevenDaysInSeconds)

					await expect(await yieldSyncV1Vault.transferDelaySeconds()).to.be.equal(sevenDaysInSeconds);
				}
			);
		});
	});

	describe("Restriction: MEMBER", async () => {
		describe("addMember()", async () => {
			it(
				"Should NOT allow member to add another member..",
				async () => {
					const [, addr1, , , addr4] = await ethers.getSigners();

					await expect(
						yieldSyncV1Vault.connect(addr1).addMember(addr4.address)
					).to.be.rejected;
				}
			);
		});

		describe("transferRequests", async () => {
			describe("Requesting Ether", async () => {
				describe("createTransferRequest()", async () => {
					it(
						"Should revert when unauthorized msg.sender calls..",
						async () => {
							const [, , , , addr4] = await ethers.getSigners();

							await expect(
								yieldSyncV1Vault.connect(addr4).createTransferRequest(
									true,
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
								yieldSyncV1Vault.connect(addr1).createTransferRequest(
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
						"Should be able to create a TransferRequest for Ether..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1Vault.connect(addr1).createTransferRequest(
								false,
								false,
								addr2.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							const createdTransferRequest = await yieldSyncV1Vault
								.transferRequestId_transferRequest(0)
							;

							expect(createdTransferRequest[0]).to.be.false;
							expect(createdTransferRequest[1]).to.be.false;
							expect(createdTransferRequest[2]).to.be.equal(addr1.address);
							expect(createdTransferRequest[3]).to.be.equal(ethers.constants.AddressZero);
							expect(createdTransferRequest[4]).to.be.equal(0);
							expect(createdTransferRequest[5]).to.be.equal(ethers.utils.parseEther(".5"));
							expect(createdTransferRequest[6]).to.be.equal(addr2.address);
							expect(createdTransferRequest[7]).to.be.equal(0);
							expect(createdTransferRequest[8]).to.be.equal(0);
							expect(createdTransferRequest[10].length).to.be.equal(0);
						}
					);

					it(
						"Should have '0' in _idsOfOpenTransferRequests[0]..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							await yieldSyncV1Vault.connect(addr1).createTransferRequest(
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							const idsOfOpenTransferRequests = await yieldSyncV1Vault.idsOfOpenTransferRequests();

							expect(idsOfOpenTransferRequests.length).to.be.equal(1);
							expect(idsOfOpenTransferRequests[0]).to.be.equal(0);
						}
					);
				});


				/**
				 * @dev voteOnTransferRequest
				*/
				describe("voteOnTransferRequest()", async () => {
					it(
						"Should revert when unauthorized msg.sender calls..",
						async () => {
							const [, addr1, , , addr4] = await ethers.getSigners();

							await yieldSyncV1Vault.connect(addr1).createTransferRequest(
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							await expect(
								yieldSyncV1Vault.connect(addr4).voteOnTransferRequest(0, true)
							).to.be.rejected;
						}
					);

					it(
						"Should be able vote on TransferRequest & add member to _transferRequest[].votedMembers..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							await yieldSyncV1Vault.connect(addr1).createTransferRequest(
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							// Vote
							await yieldSyncV1Vault.connect(addr1).voteOnTransferRequest(0, true);

							const createdTransferRequest = await yieldSyncV1Vault
								.transferRequestId_transferRequest(0)
							;

							// Vote count
							expect(createdTransferRequest[7]).to.be.equal(1);
							// Voted members
							expect(createdTransferRequest[10][0]).to.be.equal(addr1.address);
						}
					);

					it(
						"Should revert with 'Already voted' when attempting to vote again..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							await yieldSyncV1Vault.connect(addr1).createTransferRequest(
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							// 1st vote
							await yieldSyncV1Vault.connect(addr1).voteOnTransferRequest(0, true);

							// Attempt 2nd vote
							await expect(
								yieldSyncV1Vault.connect(addr1).voteOnTransferRequest(0, true)
							).to.be.rejectedWith("Already voted");
						}
					);
				});

				describe("processTransferRequest()", async () => {
					it(
						"Should revert when unauthorized msg.sender calls..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1Vault.connect(addr1).createTransferRequest(
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							await yieldSyncV1Vault.connect(addr1).voteOnTransferRequest(0, true);

							await expect(yieldSyncV1Vault.connect(addr2).processTransferRequest(0)).to.be.rejected;
						}
					);

					it(
						"Should fail to process TransferRequest because not enough votes..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							await yieldSyncV1Vault.updateForVoteCountRequired(2);

							await yieldSyncV1Vault.connect(addr1).createTransferRequest(
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							await yieldSyncV1Vault.connect(addr1).voteOnTransferRequest(0, true);

							await expect(
								yieldSyncV1Vault.connect(addr1).processTransferRequest(0)
							).to.be.rejectedWith("!forVoteCountRequired && !againstVoteCount");

							await yieldSyncV1Vault.updateForVoteCountRequired(1);
						}
					);

					it(
						"Should fail to process TransferRequest because not enough time has passed..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							await yieldSyncV1Vault.updateForVoteCountRequired(1);
							await yieldSyncV1Vault.updateTransferDelaySeconds(sevenDaysInSeconds);

							await yieldSyncV1Vault.connect(addr1).createTransferRequest(
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							await yieldSyncV1Vault.connect(addr1).voteOnTransferRequest(0, true);

							// Fast-forward 6 days
							await ethers.provider.send('evm_increaseTime', [sixDaysInSeconds]);

							await expect(
								yieldSyncV1Vault.connect(addr1).processTransferRequest(0)
							).to.be.rejectedWith("Not enough time has passed");
						}
					);

					it(
						"Should process TransferRequest for Ether..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1Vault.updateForVoteCountRequired(1);

							await yieldSyncV1Vault.connect(addr1).createTransferRequest(
								false,
								false,
								addr2.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							await yieldSyncV1Vault.connect(addr1).voteOnTransferRequest(0, true);

							// Fast-forward 6 days
							await ethers.provider.send('evm_increaseTime', [sixDaysInSeconds]);

							const recieverBalanceBefore = ethers.utils.formatUnits(
								await ethers.provider.getBalance(addr2.address)
							);

							await yieldSyncV1Vault.connect(addr1).processTransferRequest(0);

							const recieverBalanceAfter = ethers.utils.formatUnits(
								await ethers.provider.getBalance(addr2.address)
							);

							await expect(recieverBalanceAfter - recieverBalanceBefore).to.be.equal(.5);

							expect((await yieldSyncV1Vault.idsOfOpenTransferRequests()).length).to.be.equal(0);
						}
					);
				});

				describe("invalid ERC20 transferRequest", async () => {
					it(
						"Should fail to process request AND delete transferRequest after..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1Vault.updateForVoteCountRequired(1);

							await yieldSyncV1Vault.updateTransferDelaySeconds(sevenDaysInSeconds);

							await yieldSyncV1Vault.connect(addr1).createTransferRequest(
								false,
								false,
								addr2.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".6"),
								0
							);

							expect((await yieldSyncV1Vault.idsOfOpenTransferRequests()).length).to.be.equal(1);

							await yieldSyncV1Vault.connect(addr1).voteOnTransferRequest(0, true);

							const recieverBalanceBefore = await ethers.provider.getBalance(addr2.address);

							// Fast-forward 7 days
							await ethers.provider.send('evm_increaseTime', [sevenDaysInSeconds]);

							await yieldSyncV1Vault.connect(addr1).processTransferRequest(0);

							const recieverBalanceAfter = await ethers.provider.getBalance(addr2.address);

							await expect(
								ethers.utils.formatUnits(recieverBalanceAfter)
							).to.be.equal(ethers.utils.formatUnits(recieverBalanceBefore));

							expect((await yieldSyncV1Vault.idsOfOpenTransferRequests()).length).to.be.equal(0);
						}
					);
				});
			});


			/**
			 * @dev Process for Transferring ERC20
			*/
			describe("Requesting ERC20 tokens", async () => {
				describe("createTransferRequest()", async () => {
					it(
						"Should be able to create a TransferRequest for ERC20 token..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1Vault.connect(addr1).createTransferRequest(
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0
							);

							const createdTransferRequest = await yieldSyncV1Vault.transferRequestId_transferRequest(0);

							expect(createdTransferRequest[0]).to.be.true;
							expect(createdTransferRequest[1]).to.be.false;
							expect(createdTransferRequest[2]).to.be.equal(addr1.address);
							expect(createdTransferRequest[3]).to.be.equal(mockERC20.address);
							expect(createdTransferRequest[4]).to.be.equal(0);
							expect(createdTransferRequest[5]).to.be.equal(50);
							expect(createdTransferRequest[6]).to.be.equal(addr2.address);
							expect(createdTransferRequest[7]).to.be.equal(0);
							expect(createdTransferRequest[8]).to.be.equal(0);
							expect(createdTransferRequest[10].length).to.be.equal(0);
						}
					);

					it(
						"Should have '0' in _idsOfOpenTransferRequests[0]..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1Vault.connect(addr1).createTransferRequest(
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0
							);

							const idsOfOpenTransferRequests = await yieldSyncV1Vault.idsOfOpenTransferRequests();

							expect(idsOfOpenTransferRequests[0]).to.be.equal(0);
						}
					);

					it(
						"Should have length _idsOfOpenTransferRequests of 1..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1Vault.connect(addr1).createTransferRequest(
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0
							);

							const idsOfOpenTransferRequests = await yieldSyncV1Vault.idsOfOpenTransferRequests();

							expect(idsOfOpenTransferRequests.length).to.be.equal(1);
						}
					);
				});

				describe("voteOnTransferRequest()", async () => {
					it(
						"Should be able vote on TransferRequest and add member to _transferRequest[].votedMembers..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1Vault.updateForVoteCountRequired(1);

							await yieldSyncV1Vault.connect(addr1).createTransferRequest(
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0
							);

							await yieldSyncV1Vault.connect(addr1).voteOnTransferRequest(0, true);

							const createdTransferRequest = await yieldSyncV1Vault.transferRequestId_transferRequest(0);

							expect(createdTransferRequest[7]).to.be.equal(1);
							expect(createdTransferRequest[10][0]).to.be.equal(addr1.address);
						}
					);
				});

				describe("processTransferRequest()", async () => {
					it(
						"Should process TransferRequest for ERC20 token..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1Vault.updateForVoteCountRequired(1);

							await yieldSyncV1Vault.connect(addr1).createTransferRequest(
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0
							);

							await yieldSyncV1Vault.connect(addr1).voteOnTransferRequest(0, true);

							const recieverBalanceBefore = await mockERC20.balanceOf(addr2.address);

							// Fast-forward 6 days
							await ethers.provider.send('evm_increaseTime', [sixDaysInSeconds]);

							await yieldSyncV1Vault.connect(addr1).processTransferRequest(0);

							const recieverBalanceAfter = await mockERC20.balanceOf(addr2.address);

							await expect(recieverBalanceAfter - recieverBalanceBefore).to.be.equal(50);
						}
					);
				});

				describe("invalid ERC20 transferRequest", async () => {
					it(
						"Should fail to process request but delete transferRequest..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1Vault.updateForVoteCountRequired(1);

							await yieldSyncV1Vault.connect(addr1).createTransferRequest(
								true,
								false,
								addr2.address,
								mockERC20.address,
								51,
								0
							);

							await yieldSyncV1Vault.connect(addr1).voteOnTransferRequest(0, true);

							const recieverBalanceBefore = ethers.utils.formatUnits(
								await mockERC20.balanceOf(addr2.address)
							);

							// Fast-forward 7 days
							await ethers.provider.send('evm_increaseTime', [sevenDaysInSeconds]);

							await yieldSyncV1Vault.connect(addr1).processTransferRequest(0);

							const recieverBalanceAfter = ethers.utils.formatUnits(
								await mockERC20.balanceOf(addr2.address)
							);

							await expect(recieverBalanceAfter).to.be.equal(recieverBalanceBefore);
						}
					);
				});
			});


			describe("Requesting ERC721 tokens", async () => {
				describe("createTransferRequest", async () => {
					it(
						"Should be able to create a TransferRequest for ERC721 token..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1Vault.connect(addr1).createTransferRequest(
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								1
							);

							const createdTransferRequest = await yieldSyncV1Vault.transferRequestId_transferRequest(0);

							expect(createdTransferRequest[0]).to.be.false;
							expect(createdTransferRequest[1]).to.be.true;
							expect(createdTransferRequest[2]).to.be.equal(addr1.address);
							expect(createdTransferRequest[3]).to.be.equal(mockERC721.address);
							expect(createdTransferRequest[4]).to.be.equal(1);
							expect(createdTransferRequest[5]).to.be.equal(1);
							expect(createdTransferRequest[6]).to.be.equal(addr2.address);
							expect(createdTransferRequest[7]).to.be.equal(0);
							expect(createdTransferRequest[8]).to.be.equal(0);
							expect(createdTransferRequest[10].length).to.be.equal(0);
						}
					);

					it(
						"Should have '0' in _idsOfOpenTransferRequests[0]..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1Vault.connect(addr1).createTransferRequest(
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								1
							);

							const idsOfOpenTransferRequests = await yieldSyncV1Vault.idsOfOpenTransferRequests();

							expect(idsOfOpenTransferRequests.length).to.be.equal(1);
							expect(idsOfOpenTransferRequests[0]).to.be.equal(0);
						}
					);
				});


				describe("voteOnTransferRequest", async () => {
					it(
						"Should be able vote on TransferRequest and add member to _transferRequest[].votedMembers..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1Vault.connect(addr1).createTransferRequest(
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								1
							);

							await yieldSyncV1Vault.connect(addr1).voteOnTransferRequest(0, true);

							const createdTransferRequest = await yieldSyncV1Vault.transferRequestId_transferRequest(0);

							expect(createdTransferRequest[7]).to.be.equal(1);
							expect(createdTransferRequest[10][0]).to.be.equal(addr1.address);
						}
					);
				});


				describe("processTransferRequest", async () => {
					it(
						"Should process TransferRequest for ERC721 token..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1Vault.updateForVoteCountRequired(1);

							await yieldSyncV1Vault.connect(addr1).createTransferRequest(
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								1
							);

							await yieldSyncV1Vault.connect(addr1).voteOnTransferRequest(0, true);

							// Fast-forward 6 days
							await ethers.provider.send('evm_increaseTime', [sixDaysInSeconds]);

							const recieverBalanceBefore = await mockERC721.balanceOf(addr2.address);

							await yieldSyncV1Vault.connect(addr1).processTransferRequest(0);

							const recieverBalanceAfter = await mockERC721.balanceOf(addr2.address);

							await expect(recieverBalanceAfter - recieverBalanceBefore).to.be.equal(1);
						}
					);
				});

				describe("invalid ERC721 transferRequest", async () => {
					it(
						"Should fail to process request but delete transferRequest..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1Vault.updateForVoteCountRequired(1);

							await yieldSyncV1Vault.connect(addr1).createTransferRequest(
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								2
							);

							await yieldSyncV1Vault.connect(addr1).voteOnTransferRequest(0, true);

							// Fast-forward 7 days
							await ethers.provider.send('evm_increaseTime', [sevenDaysInSeconds]);

							const recieverBalanceBefore = await mockERC721.balanceOf(addr2.address);

							await yieldSyncV1Vault.connect(addr1).processTransferRequest(0);

							const recieverBalanceAfter = await mockERC721.balanceOf(addr2.address);

							await expect(
								ethers.utils.formatUnits(recieverBalanceAfter)
							).to.be.equal(ethers.utils.formatUnits(recieverBalanceBefore))
						}
					);
				});
			});
		});

		describe("transferRequest Against", async () => {
			describe("voteOnTransferRequest()", async () => {
				it(
					"Should be able vote on TransferRequest and add member to _transferRequest[].votedMembers..",
					async () => {
						const [, addr1, addr2] = await ethers.getSigners();

						await yieldSyncV1Vault.connect(addr1).createTransferRequest(
							false,
							false,
							addr2.address,
							ethers.constants.AddressZero,
							ethers.utils.parseEther(".5"),
							0
						)

						yieldSyncV1Vault.connect(addr1).voteOnTransferRequest(0, false);

						const createdTransferRequest = await yieldSyncV1Vault.transferRequestId_transferRequest(0);

						expect(createdTransferRequest[8]).to.be.equal(1);
						expect(createdTransferRequest[10][0]).to.be.equal(addr1.address);
					}
				);
			});

			describe("processTransferRequest()", async () => {
				it(
					"Should delete transferRequest due to againstVoteCount met..",
					async () => {
						const [, addr1, addr2] = await ethers.getSigners();

						await yieldSyncV1Vault.updateAgainstVoteCountRequired(1);

						await yieldSyncV1Vault.connect(addr1).createTransferRequest(
							false,
							false,
							addr2.address,
							ethers.constants.AddressZero,
							ethers.utils.parseEther(".5"),
							0
						)

						yieldSyncV1Vault.connect(addr1).voteOnTransferRequest(0, false);

						yieldSyncV1Vault.connect(addr1).processTransferRequest(0);

						await expect((await yieldSyncV1Vault.idsOfOpenTransferRequests()).length).to.be.equal(0);

						await expect(
							yieldSyncV1Vault.transferRequestId_transferRequest(0)
						).to.be.rejectedWith("No TransferRequest found");
					}
				);
			});
		});

		describe("idsOfOpenTransferRequests()", async () => {
			it(
				"Should be able to keep record of multiple open TransferRequest Ids..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await yieldSyncV1Vault.connect(addr1).createTransferRequest(
						true,
						false,
						addr2.address,
						mockERC20.address,
						50,
						0
					);

					await yieldSyncV1Vault.connect(addr1).createTransferRequest(
						true,
						false,
						addr2.address,
						mockERC20.address,
						50,
						0
					);

					expect((await yieldSyncV1Vault.idsOfOpenTransferRequests())[0]).to.be.equal(0);
					expect((await yieldSyncV1Vault.idsOfOpenTransferRequests())[1]).to.be.equal(1);
				}
			);
		});

		describe("renounceMembership()", async () => {
			it(
				"Should allow members to leave a vault..",
				async () => {
					const [, , , , , , addr6] = await ethers.getSigners();

					await yieldSyncV1Vault.addMember(addr6.address);

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


	describe("Restriction: DEFAULT_ADMIN_ROLE", async () => {
		describe("updateTransferRequest()", async () => {
			it(
				"Should be able to update TransferRequest.forVoteCount..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await yieldSyncV1Vault.connect(addr1).createTransferRequest(
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const idsOfOpenTransferRequests = await yieldSyncV1Vault.idsOfOpenTransferRequests()

					const transferRequest: any = await yieldSyncV1Vault.transferRequestId_transferRequest(
						idsOfOpenTransferRequests[idsOfOpenTransferRequests.length - 1]
					);

					await yieldSyncV1Vault.updateTransferRequest(
						idsOfOpenTransferRequests[idsOfOpenTransferRequests.length - 1],
						[
							transferRequest[0],
							transferRequest[1],
							transferRequest[2],
							transferRequest[3],
							transferRequest[4],
							transferRequest[5],
							transferRequest[6],
							transferRequest[7] + 1,
							transferRequest[8],
							transferRequest[9],
							transferRequest[10],
						]
					);

					const updatedTransferRequest: any = await yieldSyncV1Vault.transferRequestId_transferRequest(
						idsOfOpenTransferRequests[idsOfOpenTransferRequests.length - 1]
					);

					expect(updatedTransferRequest[7]).to.be.equal(1);
				}
			);

			it(
				"Should be able to update transferRequest.latestRelevantForVoteTime..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await yieldSyncV1Vault.connect(addr1).createTransferRequest(
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const idsOfOpenTransferRequests = await yieldSyncV1Vault.idsOfOpenTransferRequests();
					const wRiD: number = idsOfOpenTransferRequests[idsOfOpenTransferRequests.length - 1];

					const transferRequest: any = await yieldSyncV1Vault.transferRequestId_transferRequest(wRiD);

					await yieldSyncV1Vault.updateTransferRequest(
						wRiD,
						[
							transferRequest[0],
							transferRequest[1],
							transferRequest[2],
							transferRequest[3],
							transferRequest[4],
							transferRequest[5],
							transferRequest[6],
							transferRequest[7],
							transferRequest[8],
							BigInt(transferRequest[9]) + BigInt(10),
							transferRequest[10],
						]
					);

					expect(
						BigInt(transferRequest[9]) + BigInt(10)
					).to.be.greaterThanOrEqual(
						BigInt((await yieldSyncV1Vault.transferRequestId_transferRequest(wRiD))[9])
					);
				}
			);
		});


		describe("deleteTransferRequest()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(yieldSyncV1Vault.connect(addr1).deleteTransferRequest(2)).to.be.rejected;
				}
			);

			it(
				"Should be able to delete TransferRequest..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await yieldSyncV1Vault.connect(addr1).createTransferRequest(
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const beforeTransferRequests = await yieldSyncV1Vault.idsOfOpenTransferRequests();

					await yieldSyncV1Vault.deleteTransferRequest(
						beforeTransferRequests[beforeTransferRequests.length - 1]
					);

					expect(
						beforeTransferRequests.length - 1
					).to.be.equal(
						(await yieldSyncV1Vault.idsOfOpenTransferRequests()).length
					);

					await expect(
						yieldSyncV1Vault.transferRequestId_transferRequest(
							beforeTransferRequests[beforeTransferRequests.length - 1]
						)
					).to.be.rejectedWith("No TransferRequest found");
				}
			);
		});
	});
});
