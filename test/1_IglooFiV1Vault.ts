import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";

const { ethers } = require("hardhat");


const sevenDaysInSeconds = 7 * 24 * 60 * 60;
const sixDaysInSeconds = 6 * 24 * 60 * 60;


const stageContracts = async () => {
	const [owner] = await ethers.getSigners();

	const MockIglooFiGovernance: ContractFactory = await ethers.getContractFactory("MockIglooFiGovernance");
	const SignatureManager: ContractFactory = await ethers.getContractFactory("SignatureManager");
	const IglooFiV1VaultFactory: ContractFactory = await ethers.getContractFactory("IglooFiV1VaultFactory");
	const MockERC20: ContractFactory = await ethers.getContractFactory("MockERC20");
	const MockERC721: ContractFactory = await ethers.getContractFactory("MockERC721");
	const IglooFiV1Vault: ContractFactory = await ethers.getContractFactory("IglooFiV1Vault");
	
	const mockIglooFiGovernance: Contract = await (await MockIglooFiGovernance.deploy()).deployed();
	
	const iglooFiV1VaultFactory: Contract = await (await IglooFiV1VaultFactory.deploy(mockIglooFiGovernance.address)).deployed();
	await iglooFiV1VaultFactory.setPause(false);
	
	// Deploy a vault
	await iglooFiV1VaultFactory.deployVault(owner.address, 2, 5, { value: 1 });

	// Attach the deployed vault's address
	const iglooFiV1Vault: Contract = await IglooFiV1Vault.attach(iglooFiV1VaultFactory.vaultAddress(0));
	
	const signatureManager: Contract = await (await SignatureManager.deploy(mockIglooFiGovernance.address)).deployed();
	
	const mockERC20: Contract = await (await MockERC20.deploy()).deployed();
	
	const mockERC721: Contract = await (await MockERC721.deploy()).deployed();

	return {
		mockIglooFiGovernance,
		iglooFiV1VaultFactory,
		iglooFiV1Vault,
		mockERC20,
		mockERC721,
		signatureManager
	};
};


describe("IglooFiV1Vault.sol - IglooFi V1 Vault Contract", async () => {
	let mockIglooFiGovernance: Contract;
	let iglooFiV1VaultFactory: Contract;
	let iglooFiV1Vault: Contract;
	let mockERC20: Contract;
	let mockERC721: Contract;
	let signatureManager: Contract;


	before("[before] Set up contracts..", async () => {
		const stagedContracts = await stageContracts();

		mockIglooFiGovernance = stagedContracts.mockIglooFiGovernance;
		iglooFiV1VaultFactory = stagedContracts.iglooFiV1VaultFactory
		iglooFiV1Vault = stagedContracts.iglooFiV1Vault
		mockERC20 = stagedContracts.mockERC20
		mockERC721 = stagedContracts.mockERC721
		signatureManager = stagedContracts.signatureManager
	});


	describe("Recieving tokens & ethers", async () => {
		it("Should be able to recieve ether..", async () => {
			const [, addr1] = await ethers.getSigners();

			// Send ether to IglooFiV1VaultFactory contract
			await addr1.sendTransaction({
				to: iglooFiV1Vault.address,
				value: ethers.utils.parseEther("1")
			});

			await expect(
				await ethers.provider.getBalance(iglooFiV1Vault.address)
			).to.be.greaterThanOrEqual(ethers.utils.parseEther("1"));
		});

		it("Should be able to recieve ERC20 tokens..", async () => {
			await mockERC20.transfer(iglooFiV1Vault.address, 50);

			expect(await mockERC20.balanceOf(iglooFiV1Vault.address)).to.equal(50);
		});

		it("Should be able to recieve ERC721 tokens..", async () => {
			const [owner] = await ethers.getSigners();
			await mockERC721.transferFrom(owner.address, iglooFiV1Vault.address, 1);

			expect(await mockERC721.balanceOf(iglooFiV1Vault.address)).to.equal(1);
		});
	});

	
	/**
	* @dev AccessControlEnumerable
	*/
	describe("AccessControlEnumerable", async () => {
		it("Should allow admin to add another admin..", async () => {
			const [, , , , addr4] = await ethers.getSigners();

			await iglooFiV1Vault.grantRole(await iglooFiV1Vault.VOTER(), addr4.address)
		});
	});


	/**
	* @dev Constructor Initialized Values
	*/
	describe("Constructor Initialized Values", async () => {
		it(
			"Should have admin set properly..",
			async () => {
				const [owner] = await ethers.getSigners();

				await iglooFiV1Vault.hasRole(await iglooFiV1Vault.DEFAULT_ADMIN_ROLE(), owner.address);
			}
		);

		it(
			"Should intialize requiredVoteCount as 2..",
			async () => {
				expect(await iglooFiV1Vault.requiredVoteCount()).to.equal(2);
			}
		);

		it(
			"Should initialize withdrawalDelaySeconds 5..",
			async () => {
				expect(await iglooFiV1Vault.withdrawalDelaySeconds()).to.equal(5);
			}
		);
	});


	/**
	 * @dev Restriction: DEFAULT_ADMIN_ROLE
	*/
	describe("Restriction: DEFAULT_ADMIN_ROLE", async () => {
		describe("updateSignatureManager", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(
						iglooFiV1Vault.connect(addr1).updateSignatureManager(addr1.address)
					).to.be.rejected;
				}
			);

			it(
				"Should be able to set a signature manager contract..",
				async () => {

					await iglooFiV1Vault.updateSignatureManager(signatureManager.address);
					
					expect(await iglooFiV1Vault.signatureManager()).to.be.equal(signatureManager.address);
				}
			);
		});


		describe("addVoter", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await expect(iglooFiV1Vault.connect(addr1).addVoter(addr2.address)).to.be.rejected;
				}
			);

			it(
				"Should be able to set up VOTER role for an address..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await iglooFiV1Vault.addVoter(addr1.address);

					await expect(
						await iglooFiV1Vault.hasRole(await iglooFiV1Vault.VOTER(), addr1.address)
					).to.be.true;
				}
			);
		});


		describe("removeVoter", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(iglooFiV1Vault.connect(addr1).removeVoter(addr1.address)).to.be.rejected;
				}
			);

			it(
				"Should be able to remove address from VOTER role..",
				async () => {
					const [,, addr2] = await ethers.getSigners();

					await iglooFiV1Vault.addVoter(addr2.address)

					await iglooFiV1Vault.removeVoter(addr2.address)

					await expect(
						await iglooFiV1Vault.hasRole(await iglooFiV1Vault.VOTER(), addr2.address)
					).to.be.false;
				}
			);
		});


		describe("updateRequiredVoteCount", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();
					
					await expect(iglooFiV1Vault.connect(addr1).updateRequiredVoteCount(1)).to.be.rejected;
				}
			);

			it(
				"Should be able to update requiredVoteCount..",
				async () => {
					await iglooFiV1Vault.updateRequiredVoteCount(1)

					await expect(await iglooFiV1Vault.requiredVoteCount()).to.be.equal(1);
				}
			);
		});


		describe("updateWithdrawalDelaySeconds", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();

					await expect(
						iglooFiV1Vault.connect(addr1).updateWithdrawalDelaySeconds(sevenDaysInSeconds)
					).to.be.rejected;
				}
			);

			it(
				"Should be able to update withdrawalDelaySeconds..",
				async () => {
					await iglooFiV1Vault.updateWithdrawalDelaySeconds(sevenDaysInSeconds)

					await expect(await iglooFiV1Vault.withdrawalDelaySeconds()).to.be.equal(sevenDaysInSeconds);
				}
			);
		});
	});


	/**
	 * @dev Restriction: VOTER
	*/
	describe("Restriction: VOTER", async () => {
		/**
		 * @notice Process for withdrawking Ether
		*/
		describe("Requesting Ether", async () => {
			/**
			 * @dev createWithdrawalRequest
			*/
			describe("createWithdrawalRequest", async () => {
				it(
					"Should revert when unauthorized msg.sender calls..",
					async () => {
						const [, , addr2] = await ethers.getSigners();
						
						await expect(
							iglooFiV1Vault.connect(addr2).createWithdrawalRequest(
								true,
								false,
								false,
								addr2.address,
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
							iglooFiV1Vault.connect(addr1).createWithdrawalRequest(
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
						
						await iglooFiV1Vault.connect(addr1).createWithdrawalRequest(
							true,
							false,
							false,
							addr2.address,
							ethers.constants.AddressZero,
							ethers.utils.parseEther(".5"),
							0
						);
						
						const createdWithdrawalRequest: any = await iglooFiV1Vault.withdrawalRequest(0);
						
						expect(createdWithdrawalRequest[0]).to.be.true;
						expect(createdWithdrawalRequest[1]).to.be.false;
						expect(createdWithdrawalRequest[2]).to.be.false;
						expect(createdWithdrawalRequest[3]).to.be.equal(addr1.address);
						expect(createdWithdrawalRequest[4]).to.be.equal(addr2.address);
						expect(createdWithdrawalRequest[5]).to.be.equal(ethers.constants.AddressZero);
						expect(createdWithdrawalRequest[6]).to.be.equal(ethers.utils.parseEther(".5"));
						expect(createdWithdrawalRequest[7]).to.be.equal(0);
						expect(createdWithdrawalRequest[8]).to.be.equal(0);
						expect(createdWithdrawalRequest[10].length).to.be.equal(0);
					}
				);

				it(
					"Should have '0' in _openWithdrawalRequestIds[0]..",
					async () => {
						const openWithdrawalRequestIds = await iglooFiV1Vault.openWithdrawalRequestIds();

						expect(openWithdrawalRequestIds.length).to.be.equal(1);
						expect(openWithdrawalRequestIds[0]).to.be.equal(0);
					}
				);
			});


			/**
			 * @dev voteOnWithdrawalRequest
			*/
			describe("voteOnWithdrawalRequest", async () => {
				it(
					"Should revert when unauthorized msg.sender calls..",
					async () => {
						const [,, addr2] = await ethers.getSigners();
						
						await expect(iglooFiV1Vault.connect(addr2).voteOnWithdrawalRequest(0, true)).to.be.rejected;
					}
				);

				it(
					"Should be able vote on WithdrawalRequest and add voter to _withdrawalRequest[].votedVoters..",
					async () => {
						const [, addr1] = await ethers.getSigners();
						
						await iglooFiV1Vault.connect(addr1).voteOnWithdrawalRequest(0, true);

						const createdWithdrawalRequest: any = await iglooFiV1Vault.withdrawalRequest(0);

						expect(createdWithdrawalRequest[8]).to.be.equal(1);
						expect(createdWithdrawalRequest[10][0]).to.be.equal(addr1.address);
					}
				);

				it(
					"Should revert with 'Already voted' when attempting to vote again..",
					async () => {
						const [, addr1] = await ethers.getSigners();
						
						await expect(
							iglooFiV1Vault.connect(addr1).voteOnWithdrawalRequest(0, true)
						).to.be.rejectedWith("Already voted");
					}
				);
			});


			/**
			 * @dev processWithdrawalRequest
			*/
			describe("processWithdrawalRequest", async () => {
				it(
					"Should revert when unauthorized msg.sender calls..",
					async () => {
						const [,, addr2] = await ethers.getSigners();
						
						await expect(iglooFiV1Vault.connect(addr2).processWithdrawalRequest(0)).to.be.rejected;
					}
				);

				it(
					"Should fail to process WithdrawalRequest because not votes..",
					async () => {
						const [,addr1] = await ethers.getSigners();

						await iglooFiV1Vault.updateRequiredVoteCount(2);
						
						await expect(
							iglooFiV1Vault.connect(addr1).processWithdrawalRequest(0)
						).to.be.rejectedWith("Not enough votes");

						await iglooFiV1Vault.updateRequiredVoteCount(1);
					}
				);

				it(
					"Should fail to process WithdrawalRequest because not enough time has passed..",
					async () => {
						const [, addr1] = await ethers.getSigners();

						// Fast-forward 6 days
						await ethers.provider.send('evm_increaseTime', [sixDaysInSeconds]);
						
						await expect(
							iglooFiV1Vault.connect(addr1).processWithdrawalRequest(0)
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
						
						await iglooFiV1Vault.connect(addr1).processWithdrawalRequest(0);

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
						
						await iglooFiV1Vault.connect(addr1).createWithdrawalRequest(
							false,
							true,
							false,
							addr2.address,
							mockERC20.address,
							50,
							0
						);
						
						const createdWithdrawalRequest: any = await iglooFiV1Vault.withdrawalRequest(1);

						expect(createdWithdrawalRequest[0]).to.be.false;
						expect(createdWithdrawalRequest[1]).to.be.true;
						expect(createdWithdrawalRequest[2]).to.be.false;
						expect(createdWithdrawalRequest[3]).to.be.equal(addr1.address);
						expect(createdWithdrawalRequest[4]).to.be.equal(addr2.address);
						expect(createdWithdrawalRequest[5]).to.be.equal(mockERC20.address);
						expect(createdWithdrawalRequest[6]).to.be.equal(50);
						expect(createdWithdrawalRequest[7]).to.be.equal(0);
						expect(createdWithdrawalRequest[8]).to.be.equal(0);
						expect(createdWithdrawalRequest[10].length).to.be.equal(0);
					}
				);

				it(
					"Should have '1' in _openWithdrawalRequestIds[0]..",
					async () => {
						const openWithdrawalRequestIds = await iglooFiV1Vault.openWithdrawalRequestIds();

						expect(openWithdrawalRequestIds.length).to.be.equal(1);
						expect(openWithdrawalRequestIds[0]).to.be.equal(1);
					}
				);
			});


			/**
			 * @dev voteOnWithdrawalRequest
			*/
			describe("voteOnWithdrawalRequest", async () => {
				it(
					"Should be able vote on WithdrawalRequest and add voter to _withdrawalRequest[].votedVoters..",
					async () => {
						const [, addr1] = await ethers.getSigners();
						
						await iglooFiV1Vault.connect(addr1).voteOnWithdrawalRequest(1, true);

						const createdWithdrawalRequest: any = await iglooFiV1Vault.withdrawalRequest(1);

						expect(createdWithdrawalRequest[8]).to.be.equal(1);
						expect(createdWithdrawalRequest[10][0]).to.be.equal(addr1.address);
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
						
						await iglooFiV1Vault.connect(addr1).processWithdrawalRequest(1);

						const recieverBalanceAfter = await mockERC20.balanceOf(addr2.address);

						await expect(recieverBalanceAfter - recieverBalanceBefore).to.be.equal(50);
					}
				);

				it(
					"_openWithdrawalRequestIds should be empty..",
					async () => {
						expect((await iglooFiV1Vault.openWithdrawalRequestIds()).length).to.be.equal(0);
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
						
						await iglooFiV1Vault.connect(addr1).createWithdrawalRequest(
							false,
							false,
							true,
							addr2.address,
							mockERC721.address,
							1,
							1
						);
						
						const createdWithdrawalRequest: any = await iglooFiV1Vault.withdrawalRequest(2);

						expect(createdWithdrawalRequest[0]).to.be.false;
						expect(createdWithdrawalRequest[1]).to.be.false;
						expect(createdWithdrawalRequest[2]).to.be.true;
						expect(createdWithdrawalRequest[3]).to.be.equal(addr1.address);
						expect(createdWithdrawalRequest[4]).to.be.equal(addr2.address);
						expect(createdWithdrawalRequest[5]).to.be.equal(mockERC721.address);
						expect(createdWithdrawalRequest[6]).to.be.equal(1);
						expect(createdWithdrawalRequest[7]).to.be.equal(1);
						expect(createdWithdrawalRequest[8]).to.be.equal(0);
						expect(createdWithdrawalRequest[10].length).to.be.equal(0);
					}
				);

				it(
					"Should have '2' in _openWithdrawalRequestIds[0]..",
					async () => {
						const openWithdrawalRequestIds = await iglooFiV1Vault.openWithdrawalRequestIds();

						expect(openWithdrawalRequestIds.length).to.be.equal(1);
						expect(openWithdrawalRequestIds[0]).to.be.equal(2);
					}
				);
			});


			/**
			 * @dev voteOnWithdrawalRequest
			*/
			describe("voteOnWithdrawalRequest", async () => {
				it(
					"Should be able vote on WithdrawalRequest and add voter to _withdrawalRequest[].votedVoters..",
					async () => {
						const [, addr1] = await ethers.getSigners();
						
						await iglooFiV1Vault.connect(addr1).voteOnWithdrawalRequest(2, true);

						const createdWithdrawalRequest: any = await iglooFiV1Vault.withdrawalRequest(2);

						expect(createdWithdrawalRequest[8]).to.be.equal(1);
						expect(createdWithdrawalRequest[10][0]).to.be.equal(addr1.address);
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
						
						await iglooFiV1Vault.connect(addr1).processWithdrawalRequest(2);

						const recieverBalanceAfter = await mockERC721.balanceOf(addr2.address);

						await expect(recieverBalanceAfter - recieverBalanceBefore).to.be.equal(1);
					}
				);

				it(
					"_openWithdrawalRequestIds should be empty..",
					async () => {
						expect((await iglooFiV1Vault.openWithdrawalRequestIds()).length).to.be.equal(0);
					}
				);
			});
		});


		describe("_openWithdrawalRequestIds", async () => {
			it(
				"Should be able to keep record of multiple open WithdrawalRequest Ids..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();
					
					await iglooFiV1Vault.connect(addr1).createWithdrawalRequest(
						false,
						true,
						false,
						addr2.address,
						mockERC20.address,
						50,
						0
					);

					await iglooFiV1Vault.connect(addr1).createWithdrawalRequest(
						false,
						true,
						false,
						addr2.address,
						mockERC20.address,
						50,
						0
					);
					

					expect((await iglooFiV1Vault.openWithdrawalRequestIds())[0]).to.be.equal(3);
					expect((await iglooFiV1Vault.openWithdrawalRequestIds())[1]).to.be.equal(4);
				}
			);
		});
	});


	/**
	* @dev Restriction: DEFAULT_ADMIN_ROLE
	*/
	describe("Restriction: DEFAULT_ADMIN_ROLE", async () => {
		describe("Update WitdrawalRequest", async () => {
			it(
				"Should be able update WithdrawalRequest.voteCount..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();
					
					await iglooFiV1Vault.connect(addr1).createWithdrawalRequest(
						false,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const openWithdrawalRequestIds = await iglooFiV1Vault.openWithdrawalRequestIds()

					const withdrawalRequest: any = await iglooFiV1Vault.withdrawalRequest(
						openWithdrawalRequestIds[openWithdrawalRequestIds.length - 1]
					);

					await iglooFiV1Vault.updateWithdrawalRequest(
						openWithdrawalRequestIds[openWithdrawalRequestIds.length - 1],
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
						]
					);

					const updatedWithdrawalRequest: any = await iglooFiV1Vault.withdrawalRequest(
						openWithdrawalRequestIds[openWithdrawalRequestIds.length - 1]
					);
					
					expect(updatedWithdrawalRequest[8]).to.be.equal(1);
				}
			);
		
			it(
				"Should update the latestRelevantApproveVoteTime to ADD seconds..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await iglooFiV1Vault.connect(addr1).createWithdrawalRequest(
						false,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const openWithdrawalRequestIds = await iglooFiV1Vault.openWithdrawalRequestIds();
					const wRiD: number = openWithdrawalRequestIds[openWithdrawalRequestIds.length - 1];

					const withdrawalRequest: any = await iglooFiV1Vault.withdrawalRequest(wRiD);

					await iglooFiV1Vault.updateWithdrawalRequest(
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
						]
					);

					expect(
						BigInt(withdrawalRequest[9]) + BigInt(10)
					).to.be.greaterThanOrEqual(
						BigInt((await iglooFiV1Vault.withdrawalRequest(wRiD))[9])
					);
				}
			);

			it(
				"Should update the latestRelevantApproveVoteTime to SUBTRACT seconds..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();

					await iglooFiV1Vault.connect(addr1).createWithdrawalRequest(
						false,
						true,
						false,
						addr2.address,
						mockERC20.address,
						999,
						0
					);

					const openWithdrawalRequestIds = await iglooFiV1Vault.openWithdrawalRequestIds();
					const wRiD: number = openWithdrawalRequestIds[openWithdrawalRequestIds.length - 1];

					const withdrawalRequest: any = await iglooFiV1Vault.withdrawalRequest(wRiD);

					await iglooFiV1Vault.updateWithdrawalRequest(
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
							BigInt(withdrawalRequest[9]) - BigInt(10),
							withdrawalRequest[10],
						]
					);

					expect(
						BigInt(withdrawalRequest[9]) - BigInt(10)
					).to.be.lessThanOrEqual(
						BigInt((await iglooFiV1Vault.withdrawalRequest(wRiD))[9])
					);
				}
			);
		});

		describe("Delete WithdrawalRequest", async () => {
			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();
					
					await expect(iglooFiV1Vault.connect(addr1).deleteWithdrawalRequest(2)).to.be.rejected;
				}
			);

			it(
				"Should be able to delete WithdrawalRequest..",
				async () => {
					await iglooFiV1Vault.deleteWithdrawalRequest(3);
					await iglooFiV1Vault.deleteWithdrawalRequest(4);
					await iglooFiV1Vault.deleteWithdrawalRequest(5);
					await iglooFiV1Vault.deleteWithdrawalRequest(6);
					await iglooFiV1Vault.deleteWithdrawalRequest(7);
					
					expect((await iglooFiV1Vault.openWithdrawalRequestIds()).length).to.be.equal(0);
				}
			);
		});
	});
});