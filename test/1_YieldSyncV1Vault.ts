import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";

const { ethers } = require("hardhat");


const sevenDaysInSeconds = 7 * 24 * 60 * 60;
const sixDaysInSeconds = 6 * 24 * 60 * 60;


describe("[1] YieldSyncV1Vault.sol - YieldSync V1 Vault Contract", async () => {
	let yieldSyncV1Vault: Contract;
	let yieldSyncV1VaultAccessControl: Contract;
	let yieldSyncV1VaultFactory: Contract;
	let yieldSyncV1TransferRequestProtocol: Contract;
	let signatureProtocol: Contract;
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

		const YieldSyncV1Vault: ContractFactory = await ethers.getContractFactory("YieldSyncV1Vault");
		const YieldSyncV1VaultFactory: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultFactory");
		const YieldSyncV1VaultAccessControl: ContractFactory = await ethers.getContractFactory("YieldSyncV1VaultAccessControl");
		const MockYieldSyncGovernance: ContractFactory = await ethers.getContractFactory("MockYieldSyncGovernance");
		const YieldSyncV1SignatureProtocol: ContractFactory = await ethers.getContractFactory("YieldSyncV1SignatureProtocol");
		const YieldSyncV1TransferRequestProtocol: ContractFactory = await ethers.getContractFactory("YieldSyncV1TransferRequestProtocol");


		// Contract
		mockAdmin = await (await MockAdmin.deploy()).deployed();
		mockERC20 = await (await MockERC20.deploy()).deployed();
		mockERC721 = await (await MockERC721.deploy()).deployed();

		// Deploy
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

		// Set Factory -> Transfer Request Protocol
		await yieldSyncV1VaultFactory.updateTransferRequestProtocol(yieldSyncV1TransferRequestProtocol.address);

		// Deploy Signature Protocol
		signatureProtocol = await (
			await YieldSyncV1SignatureProtocol.deploy(
				mockYieldSyncGovernance.address,
				yieldSyncV1VaultAccessControl.address
			)
		).deployed();

		// Set YieldSyncV1Vault properties on TransferRequestProtocol.sol
		await yieldSyncV1TransferRequestProtocol.update_purposer_yieldSyncV1VaultProperty([
			2, 2, sixDaysInSeconds
		]);

		// Deploy a vault
		await yieldSyncV1VaultFactory.deployYieldSyncV1Vault(
			[owner.address],
			[addr1.address],
			ethers.constants.AddressZero,
			ethers.constants.AddressZero,
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
				const vProp = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
					yieldSyncV1Vault.address
				);

				expect(vProp.forVoteRequired).to.equal(BigInt(2));
			}
		);

		it(
			"Should intialize forVoteRequired as 2..",
			async () => {
				const vProp = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
					yieldSyncV1Vault.address
				);

				expect(vProp.againstVoteRequired).to.equal(BigInt(2));
			}
		);

		it(
			"Should initialize transferDelaySeconds as sixDaysInSeconds..",
			async () => {
				const vProp = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
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
		describe("addAdmin()", async () => {
			it(
				"Should allow admin to add another admin..",
				async () => {
					const [, , , , addr4] = await ethers.getSigners();

					await yieldSyncV1Vault.addAdmin(addr4.address);

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
					await yieldSyncV1Vault.addAdmin(mockAdmin.address);

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
						(await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_participant_access(
							yieldSyncV1Vault.address,
							addr5.address,
						))[1]
					).to.be.true;

					await yieldSyncV1Vault.removeMember(addr5.address)

					expect(
						(await yieldSyncV1VaultAccessControl.yieldSyncV1Vault_participant_access(
							yieldSyncV1Vault.address,
							addr5.address,
						))[1]
					).to.be.false;
				}
			);
		});

		describe("updateSignatureProtocol()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(
						yieldSyncV1Vault.connect(addr1).updateSignatureProtocol(addr1.address)
					).to.be.rejected;
				}
			);

			it(
				"Should be able to set a signature manager contract..",
				async () => {

					await yieldSyncV1Vault.updateSignatureProtocol(signatureProtocol.address);

					expect(await yieldSyncV1Vault.signatureProtocol()).to.be.equal(signatureProtocol.address);
				}
			);
		});

		describe("update_yieldSyncV1Vault_yieldSyncV1VaultProperty()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(
						yieldSyncV1TransferRequestProtocol.connect(
							addr1
						).update_yieldSyncV1Vault_yieldSyncV1VaultProperty(
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
					await yieldSyncV1TransferRequestProtocol.update_yieldSyncV1Vault_yieldSyncV1VaultProperty(
						yieldSyncV1Vault.address,
						[
							1,
							2,
							sixDaysInSeconds
						]
					)

					const vProp = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
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
					await yieldSyncV1TransferRequestProtocol.update_yieldSyncV1Vault_yieldSyncV1VaultProperty(
						yieldSyncV1Vault.address,
						[
							2,
							1,
							sixDaysInSeconds
						]
					)

					const vProp = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
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
					await yieldSyncV1TransferRequestProtocol.update_yieldSyncV1Vault_yieldSyncV1VaultProperty(
						yieldSyncV1Vault.address,
						[
							2,
							2,
							10
						]
					)

					const vProp = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_yieldSyncV1VaultProperty(
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
								yieldSyncV1TransferRequestProtocol.connect(addr4).createTransferRequest(
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
								yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
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
						"Should be able to create a TransferRequest for Ether..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
								yieldSyncV1Vault.address,
								false,
								false,
								addr2.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							const createdTransferRequest = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequest(
								yieldSyncV1Vault.address,
								0
							);

							const createdTransferRequestVote = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestVote(
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
							expect(createdTransferRequestVote.forVoteCount).to.be.equal(0);
							expect(createdTransferRequestVote.againstVoteCount).to.be.equal(0);
							expect(createdTransferRequestVote.votedMembers.length).to.be.equal(0);
						}
					);

					it(
						"Should have '0' in _idsOfOpenTransferRequests[0]..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
								yieldSyncV1Vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							const idsOfOpenTransferRequests = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
								yieldSyncV1Vault.address
							);

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

							await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
								yieldSyncV1Vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							await expect(
								yieldSyncV1TransferRequestProtocol.connect(addr4).voteOnTransferRequest(
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

							await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
								yieldSyncV1Vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							// Vote
							await yieldSyncV1TransferRequestProtocol.connect(addr1).voteOnTransferRequest(
								yieldSyncV1Vault.address,
								0,
								true
							)

							const createdTransferRequestVote = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestVote(
								yieldSyncV1Vault.address,
								0
							);

							// Vote count
							expect(createdTransferRequestVote.forVoteCount).to.be.equal(1);
							// Voted members
							expect(createdTransferRequestVote.votedMembers[0]).to.be.equal(addr1.address);
						}
					);

					it(
						"Should revert with 'Already voted' when attempting to vote again..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
								yieldSyncV1Vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							// 1st vote
							await yieldSyncV1TransferRequestProtocol.connect(addr1).voteOnTransferRequest(
								yieldSyncV1Vault.address,
								0,
								true
							)

							// Attempt 2nd vote
							await expect(
								yieldSyncV1TransferRequestProtocol.connect(addr1).voteOnTransferRequest(
									yieldSyncV1Vault.address,
									0,
									true
								)
							).to.be.rejectedWith("Already voted");
						}
					);
				});

				describe("processTransferRequest()", async () => {
					it(
						"Should revert when unauthorized msg.sender calls..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
								yieldSyncV1Vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							await yieldSyncV1TransferRequestProtocol.connect(addr1).voteOnTransferRequest(
								yieldSyncV1Vault.address,
								0,
								true
							);

							await expect(
								yieldSyncV1Vault.connect(addr2).processTransferRequest(0)
							).to.be.rejected;
						}
					);

					it(
						"Should fail to process TransferRequest because not enough votes..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
								yieldSyncV1Vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							await yieldSyncV1TransferRequestProtocol.connect(addr1).voteOnTransferRequest(
								yieldSyncV1Vault.address,
								0,
								true
							);

							await expect(
								yieldSyncV1Vault.connect(addr1).processTransferRequest(0)
							).to.be.rejectedWith("Transfer request pending");
						}
					);

					it(
						"Should fail to process TransferRequest because not enough time has passed..",
						async () => {
							const [, addr1] = await ethers.getSigners();

							await yieldSyncV1TransferRequestProtocol.update_yieldSyncV1Vault_yieldSyncV1VaultProperty(
								yieldSyncV1Vault.address,
								[
									2,
									1,
									sevenDaysInSeconds
								]
							);

							await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
								yieldSyncV1Vault.address,
								false,
								false,
								addr1.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							await yieldSyncV1TransferRequestProtocol.connect(addr1).voteOnTransferRequest(
								yieldSyncV1Vault.address,
								0,
								true
							);

							// Fast-forward 6 days
							await ethers.provider.send('evm_increaseTime', [sixDaysInSeconds]);

							await expect(
								yieldSyncV1Vault.connect(addr1).processTransferRequest(0)
							).to.be.rejectedWith("Transfer request approved and waiting delay");
						}
					);

					it(
						"Should process TransferRequest for Ether..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1TransferRequestProtocol.update_yieldSyncV1Vault_yieldSyncV1VaultProperty(
								yieldSyncV1Vault.address,
								[
									2,
									1,
									sixDaysInSeconds
								]
							);

							await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
								yieldSyncV1Vault.address,
								false,
								false,
								addr2.address,
								ethers.constants.AddressZero,
								ethers.utils.parseEther(".5"),
								0
							);

							await yieldSyncV1TransferRequestProtocol.connect(addr1).voteOnTransferRequest(
								yieldSyncV1Vault.address,
								0,
								true
							);

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

							const idsOfOpenTransferRequests = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
								yieldSyncV1Vault.address
							);

							expect(idsOfOpenTransferRequests.length).to.be.equal(0);
						}
					);
				});

				describe("invalid ERC20 transferRequest", async () => {
					it(
						"Should fail to process request AND delete transferRequest after..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1TransferRequestProtocol.update_yieldSyncV1Vault_yieldSyncV1VaultProperty(
								yieldSyncV1Vault.address,
								[
									2,
									1,
									sevenDaysInSeconds
								]
							);

							await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
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
									await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
										yieldSyncV1Vault.address
									)
								).length
							).to.be.equal(1);

							await yieldSyncV1TransferRequestProtocol.connect(addr1).voteOnTransferRequest(
								yieldSyncV1Vault.address,
								0,
								true
							);

							const recieverBalanceBefore = await ethers.provider.getBalance(addr2.address);

							// Fast-forward 7 days
							await ethers.provider.send('evm_increaseTime', [sevenDaysInSeconds]);

							await yieldSyncV1Vault.connect(addr1).processTransferRequest(0);

							const recieverBalanceAfter = await ethers.provider.getBalance(addr2.address);

							await expect(
								ethers.utils.formatUnits(recieverBalanceAfter)
							).to.be.equal(ethers.utils.formatUnits(recieverBalanceBefore));

							expect(
								(
									await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
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
				describe("createTransferRequest()", async () => {
					it(
						"Should be able to create a TransferRequest for ERC20 token..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
								yieldSyncV1Vault.address,
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0
							);

							const createdTransferRequest = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequest(
								yieldSyncV1Vault.address,
								0
							);

							const createdTransferRequestVote = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestVote(
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
							expect(createdTransferRequestVote.againstVoteCount).to.be.equal(0);
							expect(createdTransferRequestVote.forVoteCount).to.be.equal(0);
							expect(createdTransferRequestVote.votedMembers.length).to.be.equal(0);
						}
					);

					it(
						"Should have '0' in _idsOfOpenTransferRequests[0]..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
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
									await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
										yieldSyncV1Vault.address
									)
								)[0]
							).to.be.equal(0);
						}
					);

					it(
						"Should have length _idsOfOpenTransferRequests of 1..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
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
									await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
										yieldSyncV1Vault.address
									)
								).length
							).to.be.equal(1);
						}
					);
				});

				describe("voteOnTransferRequest()", async () => {
					it(
						"Should be able vote on TransferRequest and add member to _transferRequest[].votedMembers..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1TransferRequestProtocol.update_yieldSyncV1Vault_yieldSyncV1VaultProperty(
								yieldSyncV1Vault.address,
								[
									2,
									1,
									sevenDaysInSeconds
								]
							);

							await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
								yieldSyncV1Vault.address,
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0
							);

							await yieldSyncV1TransferRequestProtocol.connect(addr1).voteOnTransferRequest(
								yieldSyncV1Vault.address,
								0,
								true
							);

							const createdTransferRequestVote = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestVote(
								yieldSyncV1Vault.address,
								0
							);

							expect(createdTransferRequestVote.forVoteCount).to.be.equal(1);
							expect(createdTransferRequestVote.votedMembers[0]).to.be.equal(addr1.address);
						}
					);
				});

				describe("processTransferRequest()", async () => {
					it(
						"Should process TransferRequest for ERC20 token..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1TransferRequestProtocol.update_yieldSyncV1Vault_yieldSyncV1VaultProperty(
								yieldSyncV1Vault.address,
								[
									2,
									1,
									sixDaysInSeconds
								]
							);

							await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
								yieldSyncV1Vault.address,
								true,
								false,
								addr2.address,
								mockERC20.address,
								50,
								0
							);

							await yieldSyncV1TransferRequestProtocol.connect(addr1).voteOnTransferRequest(
								yieldSyncV1Vault.address,
								0,
								true
							);

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

							await yieldSyncV1TransferRequestProtocol.update_yieldSyncV1Vault_yieldSyncV1VaultProperty(
								yieldSyncV1Vault.address,
								[
									2,
									1,
									sixDaysInSeconds
								]
							);

							await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
								yieldSyncV1Vault.address,
								true,
								false,
								addr2.address,
								mockERC20.address,
								51,
								0
							);

							await yieldSyncV1TransferRequestProtocol.connect(addr1).voteOnTransferRequest(
								yieldSyncV1Vault.address,
								0,
								true
							);

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

							await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
								yieldSyncV1Vault.address,
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								1
							);

							const createdTransferRequest = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequest(
								yieldSyncV1Vault.address,
								0
							);

							const createdTransferRequestVote = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestVote(
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
							expect(createdTransferRequestVote.againstVoteCount).to.be.equal(0);
							expect(createdTransferRequestVote.forVoteCount).to.be.equal(0);
							expect(createdTransferRequestVote.votedMembers.length).to.be.equal(0);
						}
					);

					it(
						"Should have '0' in _idsOfOpenTransferRequests[0]..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
								yieldSyncV1Vault.address,
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								1
							);

							const idsOfOpenTransferRequests = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
								yieldSyncV1Vault.address
							);

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

							await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
								yieldSyncV1Vault.address,
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								1
							);

							await yieldSyncV1TransferRequestProtocol.connect(addr1).voteOnTransferRequest(
								yieldSyncV1Vault.address,
								0,
								true
							);

							const createdTransferRequestVote = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestVote(
								yieldSyncV1Vault.address,
								0
							);

							expect(createdTransferRequestVote.forVoteCount).to.be.equal(1);
							expect(createdTransferRequestVote.votedMembers[0]).to.be.equal(addr1.address);
						}
					);
				});


				describe("processTransferRequest", async () => {
					it(
						"Should process TransferRequest for ERC721 token..",
						async () => {
							const [, addr1, addr2] = await ethers.getSigners();

							await yieldSyncV1TransferRequestProtocol.update_yieldSyncV1Vault_yieldSyncV1VaultProperty(
								yieldSyncV1Vault.address,
								[
									2,
									1,
									sixDaysInSeconds
								]
							);

							await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
								yieldSyncV1Vault.address,
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								1
							);

							await yieldSyncV1TransferRequestProtocol.connect(addr1).voteOnTransferRequest(
								yieldSyncV1Vault.address,
								0,
								true
							);

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

							await yieldSyncV1TransferRequestProtocol.update_yieldSyncV1Vault_yieldSyncV1VaultProperty(
								yieldSyncV1Vault.address,
								[
									2,
									1,
									sixDaysInSeconds
								]
							);

							await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
								yieldSyncV1Vault.address,
								false,
								true,
								addr2.address,
								mockERC721.address,
								1,
								2
							);

							await yieldSyncV1TransferRequestProtocol.connect(addr1).voteOnTransferRequest(
								yieldSyncV1Vault.address,
								0,
								true
							);

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

						await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
							yieldSyncV1Vault.address,
							false,
							false,
							addr2.address,
							ethers.constants.AddressZero,
							ethers.utils.parseEther(".5"),
							0
						)

						await yieldSyncV1TransferRequestProtocol.connect(addr1).voteOnTransferRequest(
							yieldSyncV1Vault.address,
							0,
							false
						);

						const createdTransferRequestVote = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestVote(
							yieldSyncV1Vault.address,
							0
						);

						expect(createdTransferRequestVote.againstVoteCount).to.be.equal(1);
						expect(createdTransferRequestVote.votedMembers[0]).to.be.equal(addr1.address);
					}
				);
			});

			describe("processTransferRequest()", async () => {
				it(
					"Should delete transferRequest due to againstVoteCount met..",
					async () => {
						const [, addr1, addr2] = await ethers.getSigners();

						await yieldSyncV1TransferRequestProtocol.update_yieldSyncV1Vault_yieldSyncV1VaultProperty(
							yieldSyncV1Vault.address,
							[
								1,
								2,
								sixDaysInSeconds
							]
						);

						await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
							yieldSyncV1Vault.address,
							false,
							false,
							addr2.address,
							ethers.constants.AddressZero,
							ethers.utils.parseEther(".5"),
							0
						)

						await yieldSyncV1TransferRequestProtocol.connect(addr1).voteOnTransferRequest(
							yieldSyncV1Vault.address,
							0,
							false
						);

						await yieldSyncV1Vault.connect(addr1).processTransferRequest(0);

						const idsOfOpenTransferRequests = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
							yieldSyncV1Vault.address
						);

						expect(idsOfOpenTransferRequests.length).to.be.equal(0);

						await expect(
							yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestVote(
								yieldSyncV1Vault.address,
								0
							)
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

					await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
								yieldSyncV1Vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						50,
						0
					);

					await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
								yieldSyncV1Vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						50,
						0
					);

					const idsOfOpenTransferRequests = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
						yieldSyncV1Vault.address
					);

					expect(idsOfOpenTransferRequests[0]).to.be.equal(0);
					expect(idsOfOpenTransferRequests[1]).to.be.equal(1);
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


	describe("Restriction: admin (2/2)", async () => {
		describe("updateTransferRequest()", async () => {
			it(
				"Should be able to update TransferRequest.forVoteCount..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
						yieldSyncV1Vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const idsOfOpenTransferRequests = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
						yieldSyncV1Vault.address
					);

					const transferRequest: any = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequest(
						yieldSyncV1Vault.address,
						idsOfOpenTransferRequests[idsOfOpenTransferRequests.length - 1]
					);

					const transferRequestVote: any = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestVote(
						yieldSyncV1Vault.address,
						idsOfOpenTransferRequests[idsOfOpenTransferRequests.length - 1]
					);


					await yieldSyncV1TransferRequestProtocol.updateTransferRequestVote(
						yieldSyncV1Vault.address,
						idsOfOpenTransferRequests[idsOfOpenTransferRequests.length - 1],
						[
							transferRequestVote.againstVoteCount + 1,
							transferRequestVote.forVoteCount,
							transferRequestVote.latestRelevantForVoteTime,
							transferRequestVote.votedMembers,
						]
					);

					const updatedTransferRequest: any = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestVote(
						yieldSyncV1Vault.address,
						idsOfOpenTransferRequests[idsOfOpenTransferRequests.length - 1]
					);

					expect(updatedTransferRequest.againstVoteCount).to.be.equal(1);
				}
			);

			it(
				"Should be able to update transferRequest.latestRelevantForVoteTime..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
						yieldSyncV1Vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const idsOfOpenTransferRequests = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
						yieldSyncV1Vault.address
					);

					const transferRequestVote: any = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestVote(
						yieldSyncV1Vault.address,
						idsOfOpenTransferRequests[idsOfOpenTransferRequests.length - 1]
					);

					await yieldSyncV1TransferRequestProtocol.updateTransferRequestVote(
						yieldSyncV1Vault.address,
						idsOfOpenTransferRequests[idsOfOpenTransferRequests.length - 1],
						[
							transferRequestVote.againstVoteCount + 1,
							transferRequestVote.forVoteCount,
							BigInt(transferRequestVote.latestRelevantForVoteTime) + BigInt(10),
							transferRequestVote.votedMembers,
						]
					);

					expect(
						BigInt(transferRequestVote.latestRelevantForVoteTime) + BigInt(10)
					).to.be.greaterThanOrEqual(
						BigInt(
							(
								await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestVote(
									yieldSyncV1Vault.address,
									idsOfOpenTransferRequests[idsOfOpenTransferRequests.length - 1]
								)
							).latestRelevantForVoteTime
						)
					);
				}
			);
		});


		describe("deleteTransferRequest()", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(
						yieldSyncV1TransferRequestProtocol.connect(addr1).deleteTransferRequest(2)
					).to.be.rejected;
				}
			);

			it(
				"Should be able to delete TransferRequest..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await yieldSyncV1TransferRequestProtocol.connect(addr1).createTransferRequest(
						yieldSyncV1Vault.address,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const beforeTransferRequests = await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
						yieldSyncV1Vault.address
					);


					await yieldSyncV1TransferRequestProtocol.deleteTransferRequest(
						yieldSyncV1Vault.address,
						beforeTransferRequests[beforeTransferRequests.length - 1]
					);

					expect(beforeTransferRequests.length - 1).to.be.equal(
						(
							await yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_openTransferRequestIds(
								yieldSyncV1Vault.address
							)
						).length
					);

					await expect(
						yieldSyncV1TransferRequestProtocol.yieldSyncV1Vault_transferRequestId_transferRequestVote(
							yieldSyncV1Vault.address,
							beforeTransferRequests[beforeTransferRequests.length - 1]
						)
					).to.be.rejectedWith("No TransferRequest found");
				}
			);
		});
	});
});
