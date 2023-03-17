import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";

const { ethers } = require("hardhat");


const sevenDaysInSeconds = 7 * 24 * 60 * 60;
const sixDaysInSeconds = 6 * 24 * 60 * 60;


const stageContracts = async () => {
	const [owner, addr1] = await ethers.getSigners();

	const YieldSyncV1Vault: ContractFactory = await ethers.getContractFactory("YieldSyncV1Vault");
	const YieldSyncV1VaultFactory: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultFactory");
	const YieldSyncV1VaultRecord: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultRecord");
	const MockAdmin: ContractFactory = await ethers.getContractFactory("MockAdmin");
	const MockERC20: ContractFactory = await ethers.getContractFactory("MockERC20");
	const MockERC721: ContractFactory = await ethers.getContractFactory("MockERC721");
	const MockYieldSyncGovernance: ContractFactory = await ethers.getContractFactory("MockYieldSyncGovernance");
	const SignatureManager: ContractFactory = await ethers.getContractFactory("SignatureManager");

	const mockYieldSyncGovernance: Contract = await (await MockYieldSyncGovernance.deploy()).deployed();
	const yieldSyncV1VaultRecord: Contract = await (await YieldSyncV1VaultRecord.deploy()).deployed();
	const yieldSyncV1VaultFactory: Contract = await (
		await YieldSyncV1VaultFactory.deploy(mockYieldSyncGovernance.address, yieldSyncV1VaultRecord.address)
	).deployed();

	// Deploy a vault
	await yieldSyncV1VaultFactory.deployYieldSyncV1Vault(
		[owner.address],
		[addr1.address],
		ethers.constants.AddressZero,
		true,
		2,
		2,
		5,
		{ value: 1 }
	);

	// Attach the deployed vault's address
	const yieldSyncV1Vault: Contract = await YieldSyncV1Vault.attach(
		await yieldSyncV1VaultFactory.yieldSyncV1VaultId_yieldSyncV1VaultAddress(0)
	);

	const signatureManager: Contract = await (
		await SignatureManager.deploy(mockYieldSyncGovernance.address, yieldSyncV1VaultRecord.address)
	).deployed();
	const mockAdmin: Contract = await (await MockAdmin.deploy()).deployed();
	const mockERC20: Contract = await (await MockERC20.deploy()).deployed();
	const mockERC721: Contract = await (await MockERC721.deploy()).deployed();

	return {
		yieldSyncV1Vault,
		yieldSyncV1VaultFactory,
		yieldSyncV1VaultRecord,
		signatureManager,
		mockAdmin,
		mockERC20,
		mockERC721,
		mockYieldSyncGovernance
	};
};


describe("[1] YieldSyncV1Vault.sol - YieldSync V1 Vault Contract", async () => {
	let yieldSyncV1Vault: Contract;
	let yieldSyncV1VaultFactory: Contract;
	let yieldSyncV1VaultRecord: Contract;
	let signatureManager: Contract;
	let mockAdmin: Contract;
	let mockERC20: Contract;
	let mockERC721: Contract;
	let mockYieldSyncGovernance: Contract;

	before("[before] Set up contracts..", async () => {
		const stagedContracts = await stageContracts();

		yieldSyncV1Vault = stagedContracts.yieldSyncV1Vault
		yieldSyncV1VaultFactory = stagedContracts.yieldSyncV1VaultFactory
		yieldSyncV1VaultRecord = stagedContracts.yieldSyncV1VaultRecord
		signatureManager = stagedContracts.signatureManager
		mockAdmin = stagedContracts.mockAdmin
		mockERC20 = stagedContracts.mockERC20
		mockERC721 = stagedContracts.mockERC721
		mockYieldSyncGovernance = stagedContracts.mockYieldSyncGovernance;
	});

	describe("Receiving tokens & ethers", async () => {
		it("Should be able to recieve ether..", async () => {
			const [, addr1] = await ethers.getSigners();

			// Send ether to YieldSyncV1Vault contract
			await addr1.sendTransaction({
				to: yieldSyncV1Vault.address,
				value: ethers.utils.parseEther("1")
			});

			await expect(
				await ethers.provider.getBalance(yieldSyncV1Vault.address)
			).to.be.greaterThanOrEqual(ethers.utils.parseEther("1"));
		});

		it("Should be able to recieve ERC20 tokens..", async () => {
			await mockERC20.transfer(yieldSyncV1Vault.address, 50);

			expect(await mockERC20.balanceOf(yieldSyncV1Vault.address)).to.equal(50);
		});

		it("Should be able to recieve ERC721 tokens..", async () => {
			const [owner] = await ethers.getSigners();
			await mockERC721.transferFrom(owner.address, yieldSyncV1Vault.address, 1);

			expect(await mockERC721.balanceOf(yieldSyncV1Vault.address)).to.equal(1);
		});
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
			"Should initialize withdrawalDelaySeconds 5..",
			async () => {
				expect(await yieldSyncV1Vault.withdrawalDelaySeconds()).to.equal(5);
			}
		);

		it(
			"Should have admin set properly..",
			async () => {
				const [owner] = await ethers.getSigners();

				expect(
					(await yieldSyncV1VaultRecord.participant_yieldSyncV1Vault_access(
						owner.address,
						yieldSyncV1Vault.address
					))[0]
				).to.be.true;

				expect(
					(await yieldSyncV1VaultRecord.yieldSyncV1Vault_admins(yieldSyncV1Vault.address))[0]
				).to.be.equal(owner.address);

				expect(
					(await yieldSyncV1VaultRecord.admin_yieldSyncV1Vaults(owner.address))[0]
				).to.be.equal(yieldSyncV1Vault.address);
			}
		);

		it(
			"Should have added members correctly..",
				async () => {
				const [, addr1] = await ethers.getSigners();

				expect(
					(await yieldSyncV1VaultRecord.participant_yieldSyncV1Vault_access(
						addr1.address,
						yieldSyncV1Vault.address
					))[1]
				).to.be.true;

				expect(
					(await yieldSyncV1VaultRecord.yieldSyncV1Vault_members(yieldSyncV1Vault.address))[0]
				).to.be.equal(addr1.address);

				expect(
					(await yieldSyncV1VaultRecord.member_yieldSyncV1Vaults(addr1.address))[0]
				).to.be.equal(yieldSyncV1Vault.address);
			}
		);
	});


	/**
	 * @dev Restriction: DEFAULT_ADMIN_ROLE
	*/
	describe("Restriction: DEFAULT_ADMIN_ROLE", async () => {
		describe("addAdmin()", async () => {
			it("Should allow admin to add another admin..", async () => {
				const [, , , , addr4] = await ethers.getSigners();

				await yieldSyncV1Vault.addAdmin(addr4.address);

				expect(
					(await yieldSyncV1VaultRecord.participant_yieldSyncV1Vault_access(
						addr4.address,
						yieldSyncV1Vault.address
					))[0]
				).to.be.true;

				expect(
					(await yieldSyncV1VaultRecord.admin_yieldSyncV1Vaults(addr4.address))[0]
				).to.be.equal(yieldSyncV1Vault.address);


				expect(
					(await yieldSyncV1VaultRecord.yieldSyncV1Vault_admins(yieldSyncV1Vault.address))[1]
				).to.be.equal(addr4.address);
			});

			it("Should allow admin to add a contract-based admin..", async () => {
				await yieldSyncV1Vault.addAdmin(mockAdmin.address);

				expect(
					(await yieldSyncV1VaultRecord.participant_yieldSyncV1Vault_access(
						mockAdmin.address,
						yieldSyncV1Vault.address
					))[0]
				).to.be.true;

				expect(
					(await yieldSyncV1VaultRecord.admin_yieldSyncV1Vaults(mockAdmin.address))[0]
				).to.be.equal(yieldSyncV1Vault.address);


				expect(
					(await yieldSyncV1VaultRecord.yieldSyncV1Vault_admins(yieldSyncV1Vault.address))[2]
				).to.be.equal(mockAdmin.address);
			});
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
						(await yieldSyncV1VaultRecord.participant_yieldSyncV1Vault_access(
							addr2.address,
							yieldSyncV1Vault.address
						))[1]
					).to.be.true;

					expect(
						(await yieldSyncV1VaultRecord.member_yieldSyncV1Vaults(addr2.address))[0]
					).to.be.equal(yieldSyncV1Vault.address);


					expect(
						(await yieldSyncV1VaultRecord.yieldSyncV1Vault_members(yieldSyncV1Vault.address))[1]
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
					const [, ,  , , addr5] = await ethers.getSigners();

					await yieldSyncV1Vault.addMember(addr5.address)

					await yieldSyncV1Vault.removeMember(addr5.address)

					expect(
						(await yieldSyncV1VaultRecord.participant_yieldSyncV1Vault_access(
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


		describe("updateWithdrawalDelaySeconds()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(
						yieldSyncV1Vault.connect(addr1).updateWithdrawalDelaySeconds(sevenDaysInSeconds)
					).to.be.rejected;
				}
			);

			it(
				"Should be able to update withdrawalDelaySeconds..",
				async () => {
					await yieldSyncV1Vault.updateWithdrawalDelaySeconds(sevenDaysInSeconds)

					await expect(await yieldSyncV1Vault.withdrawalDelaySeconds()).to.be.equal(sevenDaysInSeconds);
				}
			);
		});
	});


	/**
	 * @dev Restriction: MEMBER
	*/
	describe("Restriction: MEMBER", async () => {
		describe("addMember()", async () => {
			it("Should NOT allow member to add another member..", async () => {
				const [, addr1, , , addr4] = await ethers.getSigners();

				await expect(
					yieldSyncV1Vault.connect(addr1).addMember(addr4.address)
				).to.be.rejected;
			});
		});

		describe("withdrawalRequest For", async () => {
			/**
			 * @notice Process for withdrawling Ether
			*/
			describe("Requesting Ether", async () => {
				/**
				 * @dev createWithdrawalRequest
				*/
				describe("createWithdrawalRequest()", async () => {
					it(
						"Should revert when unauthorized msg.sender calls..",
						async () => {
						const [, , , , addr4] = await ethers.getSigners();

							await expect(
								yieldSyncV1Vault.connect(addr4).createWithdrawalRequest(
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
								yieldSyncV1Vault.connect(addr1).createWithdrawalRequest(
									true,
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
						"Should be able to create a WithdrawalRequest for Ether..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1Vault.connect(addr1).createWithdrawalRequest(
								true,
								false,
								false,
								addr2.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							const createdWithdrawalRequest: any = await yieldSyncV1Vault.withdrawalRequestId_withdralRequest(0);

							expect(createdWithdrawalRequest[0]).to.be.true;
							expect(createdWithdrawalRequest[1]).to.be.false;
							expect(createdWithdrawalRequest[2]).to.be.false;
							expect(createdWithdrawalRequest[3]).to.be.equal(addr1.address);
							expect(createdWithdrawalRequest[4]).to.be.equal(addr2.address);
							expect(createdWithdrawalRequest[5]).to.be.equal(ethers.constants.AddressZero);
							expect(createdWithdrawalRequest[6]).to.be.equal(ethers.utils.parseEther(".5"));
							expect(createdWithdrawalRequest[7]).to.be.equal(0);
							expect(createdWithdrawalRequest[8]).to.be.equal(0);
							expect(createdWithdrawalRequest[9]).to.be.equal(0);
							expect(createdWithdrawalRequest[11].length).to.be.equal(0);
						}
					);

					it(
						"Should have '0' in _idsOfOpenWithdrawalRequests[0]..",
						async () => {
							const idsOfOpenWithdrawalRequests = await yieldSyncV1Vault.idsOfOpenWithdrawalRequests();

							expect(idsOfOpenWithdrawalRequests.length).to.be.equal(1);
							expect(idsOfOpenWithdrawalRequests[0]).to.be.equal(0);
						}
					);
				});


				/**
				 * @dev voteOnWithdrawalRequest
				*/
				describe("voteOnWithdrawalRequest()", async () => {
					it(
						"Should revert when unauthorized msg.sender calls..",
						async () => {
							const [, , , , addr4] = await ethers.getSigners();

							await expect(yieldSyncV1Vault.connect(addr4).voteOnWithdrawalRequest(0, true)).to.be.rejected;
						}
					);

					it(
						"Should be able vote on WithdrawalRequest and add member to _withdrawalRequest[].votedMembers..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							await yieldSyncV1Vault.connect(addr1).voteOnWithdrawalRequest(0, true);

							const createdWithdrawalRequest: any = await yieldSyncV1Vault.withdrawalRequestId_withdralRequest(0);

							expect(createdWithdrawalRequest[8]).to.be.equal(1);
							expect(createdWithdrawalRequest[11][0]).to.be.equal(addr1.address);
						}
					);

					it(
						"Should revert with 'Already voted' when attempting to vote again..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							await expect(
								yieldSyncV1Vault.connect(addr1).voteOnWithdrawalRequest(0, true)
							).to.be.rejectedWith("Already voted");
						}
					);
				});


				/**
				 * @dev processWithdrawalRequest
				*/
				describe("processWithdrawalRequest()", async () => {
					it(
						"Should revert when unauthorized msg.sender calls..",
						async () => {
							const [,, addr2] = await ethers.getSigners();

							await expect(yieldSyncV1Vault.connect(addr2).processWithdrawalRequest(0)).to.be.rejected;
						}
					);

					it(
						"Should fail to process WithdrawalRequest because not votes..",
						async () => {
							const [,addr1] = await ethers.getSigners();

							await yieldSyncV1Vault.updateForVoteCountRequired(2);

							await expect(
								yieldSyncV1Vault.connect(addr1).processWithdrawalRequest(0)
							).to.be.rejectedWith("!forVoteCountRequired && !againstVoteCount");

							await yieldSyncV1Vault.updateForVoteCountRequired(1);
						}
					);

					it(
						"Should fail to process WithdrawalRequest because not enough time has passed..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							// Fast-forward 6 days
							await ethers.provider.send('evm_increaseTime', [sixDaysInSeconds]);

							await expect(
								yieldSyncV1Vault.connect(addr1).processWithdrawalRequest(0)
							).to.be.rejectedWith("Not enough time has passed");
						}
					);

					it(
						"Should process WithdrawalRequest for Ether..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							const recieverBalanceBefore = await ethers.provider.getBalance(addr2.address);

							// Fast-forward 7 days
							await ethers.provider.send('evm_increaseTime', [sevenDaysInSeconds]);

							await yieldSyncV1Vault.connect(addr1).processWithdrawalRequest(0);

							const recieverBalanceAfter = await ethers.provider.getBalance(addr2.address);

							await expect(
								ethers.utils.formatUnits(recieverBalanceAfter) -
								ethers.utils.formatUnits(recieverBalanceBefore)
							).to.be.equal(.5);
						}
					);
				});
			});


			/**
			 * @dev Process for withdrawing ERC20
			*/
			describe("Requesting ERC20 tokens", async () => {
				/**
				 * @dev createWithdrawalRequest
				*/
				describe("createWithdrawalRequest", async () => {
					it(
						"Should be able to create a WithdrawalRequest for ERC20 token..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1Vault.connect(addr1).createWithdrawalRequest(
								false,
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0
							);

							const createdWithdrawalRequest: any = await yieldSyncV1Vault.withdrawalRequestId_withdralRequest(1);

							expect(createdWithdrawalRequest[0]).to.be.false;
							expect(createdWithdrawalRequest[1]).to.be.true;
							expect(createdWithdrawalRequest[2]).to.be.false;
							expect(createdWithdrawalRequest[3]).to.be.equal(addr1.address);
							expect(createdWithdrawalRequest[4]).to.be.equal(addr2.address);
							expect(createdWithdrawalRequest[5]).to.be.equal(mockERC20.address);
							expect(createdWithdrawalRequest[6]).to.be.equal(50);
							expect(createdWithdrawalRequest[7]).to.be.equal(0);
							expect(createdWithdrawalRequest[8]).to.be.equal(0);
							expect(createdWithdrawalRequest[9]).to.be.equal(0);
							expect(createdWithdrawalRequest[11].length).to.be.equal(0);
						}
					);

					it(
						"Should have '1' in _idsOfOpenWithdrawalRequests[0]..",
						async () => {
							const idsOfOpenWithdrawalRequests = await yieldSyncV1Vault.idsOfOpenWithdrawalRequests();

							expect(idsOfOpenWithdrawalRequests.length).to.be.equal(1);
							expect(idsOfOpenWithdrawalRequests[0]).to.be.equal(1);
						}
					);
				});


				/**
				 * @dev voteOnWithdrawalRequest
				*/
				describe("voteOnWithdrawalRequest", async () => {
					it(
						"Should be able vote on WithdrawalRequest and add member to _withdrawalRequest[].votedMembers..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							await yieldSyncV1Vault.connect(addr1).voteOnWithdrawalRequest(1, true);

							const createdWithdrawalRequest: any = await yieldSyncV1Vault.withdrawalRequestId_withdralRequest(1);

							expect(createdWithdrawalRequest[8]).to.be.equal(1);
							expect(createdWithdrawalRequest[11][0]).to.be.equal(addr1.address);
						}
					);
				});


				/**
				 * @dev processWithdrawalRequest
				*/
				describe("processWithdrawalRequest", async () => {
					it(
						"Should process WithdrawalRequest for ERC20 token..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							const recieverBalanceBefore = await mockERC20.balanceOf(addr2.address);

							// Fast-forward 7 days
							await ethers.provider.send('evm_increaseTime', [sevenDaysInSeconds]);

							await yieldSyncV1Vault.connect(addr1).processWithdrawalRequest(1);

							const recieverBalanceAfter = await mockERC20.balanceOf(addr2.address);

							await expect(recieverBalanceAfter - recieverBalanceBefore).to.be.equal(50);
						}
					);

					it(
						"_idsOfOpenWithdrawalRequests should be empty..",
						async () => {
							expect((await yieldSyncV1Vault.idsOfOpenWithdrawalRequests()).length).to.be.equal(0);
						}
					);
				});
			});


			/**
			 * @dev Process for withdrawing ERC721
			*/
			describe("Requesting ERC721 tokens", async () => {
				/**
				 * @dev createWithdrawalRequest
				*/
				describe("createWithdrawalRequest", async () => {
					it(
						"Should be able to create a WithdrawalRequest for ERC721 token..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1Vault.connect(addr1).createWithdrawalRequest(
								false,
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								1
							);

							const createdWithdrawalRequest: any = await yieldSyncV1Vault.withdrawalRequestId_withdralRequest(2);

							expect(createdWithdrawalRequest[0]).to.be.false;
							expect(createdWithdrawalRequest[1]).to.be.false;
							expect(createdWithdrawalRequest[2]).to.be.true;
							expect(createdWithdrawalRequest[3]).to.be.equal(addr1.address);
							expect(createdWithdrawalRequest[4]).to.be.equal(addr2.address);
							expect(createdWithdrawalRequest[5]).to.be.equal(mockERC721.address);
							expect(createdWithdrawalRequest[6]).to.be.equal(1);
							expect(createdWithdrawalRequest[7]).to.be.equal(1);
							expect(createdWithdrawalRequest[8]).to.be.equal(0);
							expect(createdWithdrawalRequest[9]).to.be.equal(0);
							expect(createdWithdrawalRequest[11].length).to.be.equal(0);
						}
					);

					it(
						"Should have '2' in _idsOfOpenWithdrawalRequests[0]..",
						async () => {
							const idsOfOpenWithdrawalRequests = await yieldSyncV1Vault.idsOfOpenWithdrawalRequests();

							expect(idsOfOpenWithdrawalRequests.length).to.be.equal(1);
							expect(idsOfOpenWithdrawalRequests[0]).to.be.equal(2);
						}
					);
				});


				/**
				 * @dev voteOnWithdrawalRequest
				*/
				describe("voteOnWithdrawalRequest", async () => {
					it(
						"Should be able vote on WithdrawalRequest and add member to _withdrawalRequest[].votedMembers..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							await yieldSyncV1Vault.connect(addr1).voteOnWithdrawalRequest(2, true);

							const createdWithdrawalRequest: any = await yieldSyncV1Vault.withdrawalRequestId_withdralRequest(2);

							expect(createdWithdrawalRequest[8]).to.be.equal(1);
							expect(createdWithdrawalRequest[11][0]).to.be.equal(addr1.address);
						}
					);
				});


				/**
				 * @dev processWithdrawalRequest
				*/
				describe("processWithdrawalRequest", async () => {
					it(
						"Should process WithdrawalRequest for ERC721 token..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							const recieverBalanceBefore = await mockERC721.balanceOf(addr2.address);

							// Fast-forward 7 days
							await ethers.provider.send('evm_increaseTime', [sevenDaysInSeconds]);

							await yieldSyncV1Vault.connect(addr1).processWithdrawalRequest(2);

							const recieverBalanceAfter = await mockERC721.balanceOf(addr2.address);

							await expect(recieverBalanceAfter - recieverBalanceBefore).to.be.equal(1);
						}
					);

					it(
						"_idsOfOpenWithdrawalRequests should be empty..",
						async () => {
							expect((await yieldSyncV1Vault.idsOfOpenWithdrawalRequests()).length).to.be.equal(0);
						}
					);
				});
			});
		});

		describe("withdrawalRequest Against", async () => {
			/**
			 * @dev voteOnWithdrawalRequest
			*/
			describe("voteOnWithdrawalRequest()", async () => {
				it(
					"Should be able vote on WithdrawalRequest and add member to _withdrawalRequest[].votedMembers..",
					async () => {
						const [, addr1, addr2] = await ethers.getSigners();

						await yieldSyncV1Vault.connect(addr1).createWithdrawalRequest(
							true,
							false,
							false,
							addr2.address,
							ethers.constants.AddressZero,
							ethers.utils.parseEther(".5"),
							0
						)

						const idsOfOpenWithdrawalRequests = await yieldSyncV1Vault.idsOfOpenWithdrawalRequests()

						yieldSyncV1Vault.connect(addr1).voteOnWithdrawalRequest(
							idsOfOpenWithdrawalRequests[idsOfOpenWithdrawalRequests.length - 1],
							false
						)

						const createdWithdrawalRequest = await yieldSyncV1Vault.withdrawalRequestId_withdralRequest(
							idsOfOpenWithdrawalRequests[idsOfOpenWithdrawalRequests.length - 1]
						)

						expect(createdWithdrawalRequest[9]).to.be.equal(1);
						expect(createdWithdrawalRequest[11][0]).to.be.equal(addr1.address);
					}
				);
			});

			/**
			 * @dev processWithdrawalRequest
			*/
			describe("processWithdrawalRequest()", async () => {
				it("Should delete withdrawalRequest due to againstVoteCount met..", async () => {
					const [, addr1] = await ethers.getSigners();

					const idsOfOpenWithdrawalRequests = await yieldSyncV1Vault.idsOfOpenWithdrawalRequests();

					yieldSyncV1Vault.connect(addr1).processWithdrawalRequest(
						idsOfOpenWithdrawalRequests[idsOfOpenWithdrawalRequests.length - 1]
					);

					await expect((await yieldSyncV1Vault.idsOfOpenWithdrawalRequests()).length).to.be.equal(0);

					await expect(
						yieldSyncV1Vault.withdrawalRequestId_withdralRequest(
							idsOfOpenWithdrawalRequests[idsOfOpenWithdrawalRequests.length - 1]
						)
					).to.be.rejectedWith("No WithdrawalRequest found");
				});
			});
		});

		describe("idsOfOpenWithdrawalRequests()", async () => {
			it(
				"Should be able to keep record of multiple open WithdrawalRequest Ids..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await yieldSyncV1Vault.connect(addr1).createWithdrawalRequest(
						false,
						true,
						false,
						addr2.address,
						mockERC20.address,
						50,
						0
					);

					await yieldSyncV1Vault.connect(addr1).createWithdrawalRequest(
						false,
						true,
						false,
						addr2.address,
						mockERC20.address,
						50,
						0
					);

					expect((await yieldSyncV1Vault.idsOfOpenWithdrawalRequests())[0]).to.be.equal(4);
					expect((await yieldSyncV1Vault.idsOfOpenWithdrawalRequests())[1]).to.be.equal(5);
				}
			);
		});
	});


	/**
	* @dev Restriction: DEFAULT_ADMIN_ROLE
	*/
	describe("Restriction: DEFAULT_ADMIN_ROLE", async () => {
		describe("updateWithdrawalRequest()", async () => {
			it(
				"Should be able to update WithdrawalRequest.forVoteCount..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await yieldSyncV1Vault.connect(addr1).createWithdrawalRequest(
						false,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const idsOfOpenWithdrawalRequests = await yieldSyncV1Vault.idsOfOpenWithdrawalRequests()

					const withdrawalRequest: any = await yieldSyncV1Vault.withdrawalRequestId_withdralRequest(
						idsOfOpenWithdrawalRequests[idsOfOpenWithdrawalRequests.length - 1]
					);

					await yieldSyncV1Vault.updateWithdrawalRequest(
						idsOfOpenWithdrawalRequests[idsOfOpenWithdrawalRequests.length - 1],
						[
							withdrawalRequest[0],
							withdrawalRequest[1],
							withdrawalRequest[2],
							withdrawalRequest[3],
							withdrawalRequest[4],
							withdrawalRequest[5],
							withdrawalRequest[6],
							withdrawalRequest[7],
							withdrawalRequest[8] + 1,
							withdrawalRequest[9],
							withdrawalRequest[10],
							withdrawalRequest[11],
						]
					);

					const updatedWithdrawalRequest: any = await yieldSyncV1Vault.withdrawalRequestId_withdralRequest(
						idsOfOpenWithdrawalRequests[idsOfOpenWithdrawalRequests.length - 1]
					);

					expect(updatedWithdrawalRequest[8]).to.be.equal(1);
				}
			);

			it(
				"Should be able to update withdrawalRequest.latestRelevantApproveVoteTime..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await yieldSyncV1Vault.connect(addr1).createWithdrawalRequest(
						false,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const idsOfOpenWithdrawalRequests = await yieldSyncV1Vault.idsOfOpenWithdrawalRequests();
					const wRiD: number = idsOfOpenWithdrawalRequests[idsOfOpenWithdrawalRequests.length - 1];

					const withdrawalRequest: any = await yieldSyncV1Vault.withdrawalRequestId_withdralRequest(wRiD);

					await yieldSyncV1Vault.updateWithdrawalRequest(
						wRiD,
						[
							withdrawalRequest[0],
							withdrawalRequest[1],
							withdrawalRequest[2],
							withdrawalRequest[3],
							withdrawalRequest[4],
							withdrawalRequest[5],
							withdrawalRequest[6],
							withdrawalRequest[7],
							withdrawalRequest[8],
							BigInt(withdrawalRequest[9]) + BigInt(10),
							withdrawalRequest[10],
							withdrawalRequest[11],
						]
					);

					expect(
						BigInt(withdrawalRequest[9]) + BigInt(10)
					).to.be.greaterThanOrEqual(
						BigInt((await yieldSyncV1Vault.withdrawalRequestId_withdralRequest(wRiD))[9])
					);
				}
			);
		});


		describe("deleteWithdrawalRequest()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(yieldSyncV1Vault.connect(addr1).deleteWithdrawalRequest(2)).to.be.rejected;
				}
			);

			it(
				"Should be able to delete WithdrawalRequest..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await yieldSyncV1Vault.connect(addr1).createWithdrawalRequest(
						false,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const beforeWithdrawalRequests = await yieldSyncV1Vault.idsOfOpenWithdrawalRequests();

					await yieldSyncV1Vault.deleteWithdrawalRequest(
						beforeWithdrawalRequests[beforeWithdrawalRequests.length - 1]
					);

					expect(
						beforeWithdrawalRequests.length - 1
					).to.be.equal(
						(await yieldSyncV1Vault.idsOfOpenWithdrawalRequests()).length
					);

					await expect(
						yieldSyncV1Vault.withdrawalRequestId_withdralRequest(
							beforeWithdrawalRequests[beforeWithdrawalRequests.length - 1]
						)
					).to.be.rejectedWith("No WithdrawalRequest found");
				}
			);
		});
	});
});
