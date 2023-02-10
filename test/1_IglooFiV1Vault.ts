import { expect } from "chai";
const { ethers } = require("hardhat");


const sevenDaysInSeconds = 7 * 24 * 60 * 60;
const sixDaysInSeconds = 6 * 24 * 60 * 60;


describe("IglooFi V1 Vault", async () => {
	let iglooFiV1VaultFactory: any;
	let testIglooFiGovernance: any;
	let iglooFiV1VaultsMultiSignedMessages: any;
	let iglooFiV1Vault: any;
	let mockERC20: any;
	
	
	/**
	 * @notice Deploy contract
	 * @dev Deploy TestIglooFiGovernance.sol
	*/
	before("[before] Deploy IglooFiGovernance.sol contract..", async () => {
		const TestIglooFiGovernance = await ethers.getContractFactory("TestIglooFiGovernance");

		testIglooFiGovernance = await TestIglooFiGovernance.deploy();
		testIglooFiGovernance = await testIglooFiGovernance.deployed();
	});


	/**
	 * @notice Deploy contract
	 * @dev Deploy IglooFiV1VaultsMultiSignedMessages.sol
	*/
	before("[before] Deploy IglooFiV1VaultsMultiSignedMessages.sol..", async () => {
		const IglooFiV1VaultsMultiSignedMessages = await ethers.getContractFactory(
			"IglooFiV1VaultsMultiSignedMessages"
		);

		iglooFiV1VaultsMultiSignedMessages = await IglooFiV1VaultsMultiSignedMessages.deploy();
		iglooFiV1VaultsMultiSignedMessages = await iglooFiV1VaultsMultiSignedMessages.deployed();
	});


	/**
	 * @notice Deploy contract
	 * @dev Deploy IglooFiV1VaultFactory.sol
	*/
	before("[before] Deploy IglooFiV1VaultFactory.sol contracts..", async () => {
		const IglooFiV1VaultFactory = await ethers.getContractFactory("IglooFiV1VaultFactory");

		iglooFiV1VaultFactory = await IglooFiV1VaultFactory.deploy(
			testIglooFiGovernance.address,
			iglooFiV1VaultsMultiSignedMessages.address
		);

		iglooFiV1VaultFactory = await iglooFiV1VaultFactory.deployed();

		await iglooFiV1VaultFactory.setPause(false);
	});


	/**
	 * @notice Deploy contract
	 * @dev Factory Deploy IglooFiV1Vault.sol (IglooFiV1VaultFactory.sol)
	*/
	before("[before] Factory deploy IglooFiV1Vault.sol..", async () => {
		const [owner] = await ethers.getSigners();

		const IglooFiV1Vault = await ethers.getContractFactory("IglooFiV1Vault");
		
		// Deploy a vault
		await iglooFiV1VaultFactory.deployVault(
			owner.address,
			2,
			5,
			{ value: 1 }
		);

		// Attach the deployed vault's address
		iglooFiV1Vault = await IglooFiV1Vault.attach(iglooFiV1VaultFactory.vaultAddress(0));
	});


	/**
	 * @notice Deploy the contracts
	 * @dev Deploy MockERC20.sol
	*/
	before("[before] Deploy MockERC20.sol..", async () => {
		const MockERC20 = await ethers.getContractFactory("MockERC20");

		mockERC20 = await MockERC20.deploy();
		mockERC20 = await mockERC20.deployed();
	});


	/**
	* @dev IglooFiV1Vault.sol
	*/
	describe("IglooFiV1Vault.sol Contract", async () => {
		it("Should be able to recieve ether..", async () => {
			const [, addr1] = await ethers.getSigners();
			
			// Send ether to IglooFiV1VaultFactory contract
			await addr1.sendTransaction({
				to: iglooFiV1Vault.address,
				value: ethers.utils.parseEther("1"),
			});

			await expect(
				await ethers.provider.getBalance(iglooFiV1Vault.address)
			).to.be.greaterThanOrEqual(ethers.utils.parseEther("1"));
		});

		it("Should be able to recieve ERC20 tokens..", async () => {
			await mockERC20.transfer(iglooFiV1Vault.address, 50);

			expect(await mockERC20.balanceOf(iglooFiV1Vault.address)).to.equal(50);
		});
		
		
		/**
		* @dev Constructor Initialized Values
		*/
		describe("Constructor Initialized Values", async () => {
			it(
				"Should have admin set properly..",
				async () => {
					const [owner] = await ethers.getSigners();

					await iglooFiV1Vault.hasRole(
						await iglooFiV1Vault.DEFAULT_ADMIN_ROLE(),
						owner.address
					)
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
			describe("addVoter", async () => {
				it(
					"Should revert when unauthorized msg.sender calls..",
					async () => {
						const [, addr1, addr2] = await ethers.getSigners();

						await expect(
							iglooFiV1Vault.connect(addr1).addVoter(addr2.address)
						).to.be.rejected;
					}
				);

				it(
					"Should be able to set up VOTER role for an address..",
					async () => {
						const [, addr1] = await ethers.getSigners();

						await iglooFiV1Vault.addVoter(addr1.address)

						await expect(
							await iglooFiV1Vault.hasRole(
								await iglooFiV1Vault.VOTER(),
								addr1.address
							)
						).to.be.true;
					}
				);
			});


			describe("removeVoter", async () => {
				it(
					"Should revert when unauthorized msg.sender calls..",
					async () => {
						const [, addr1] = await ethers.getSigners();

						await expect(
							iglooFiV1Vault.connect(addr1).removeVoter(addr1.address)
						).to.be.rejected;
					}
				);

				it(
					"Should be able to remove address from VOTER role..",
					async () => {
						const [,, addr2] = await ethers.getSigners();

						await iglooFiV1Vault.addVoter(addr2.address)

						await iglooFiV1Vault.removeVoter(addr2.address)

						await expect(
							await iglooFiV1Vault.hasRole(
								await iglooFiV1Vault.VOTER(),
								addr2.address
							)
						).to.be.false;
					}
				);
			});


			describe("updateRequiredVoteCount", async () => {
				it(
					"Should revert when unauthorized msg.sender calls..",
					async () => {
						const [, addr1] = await ethers.getSigners();
						
						await expect(
							iglooFiV1Vault.connect(addr1).updateRequiredVoteCount(1)
						).to.be.rejected;
					}
				);

				it(
					"Should be able to update requiredVoteCount..",
					async () => {
						await iglooFiV1Vault.updateRequiredVoteCount(1)

						await expect(
							await iglooFiV1Vault.requiredVoteCount()
						).to.be.equal(1);
					}
				);
			});


			describe("updateWithdrawalDelaySeconds", async () => {
				it(
					"Should revert when unauthorized msg.sender calls..",
					async () => {
						const [, addr1] = await ethers.getSigners();

						await expect(
							iglooFiV1Vault.connect(addr1).updateWithdrawalDelaySeconds(
								sevenDaysInSeconds
							)
						).to.be.rejected;
					}
				);

				it(
					"Should be able to update withdrawalDelaySeconds..",
					async () => {
						await iglooFiV1Vault.updateWithdrawalDelaySeconds(
							sevenDaysInSeconds
						)

						await expect(
							await iglooFiV1Vault.withdrawalDelaySeconds()
						).to.be.equal(sevenDaysInSeconds);
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
							const [,, addr2] = await ethers.getSigners();
							
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
							expect(createdWithdrawalRequest[5]).to.be.equal(
								ethers.constants.AddressZero
							);
							expect(createdWithdrawalRequest[6]).to.be.equal(
								ethers.utils.parseEther(".5")
							);
							expect(createdWithdrawalRequest[7]).to.be.equal(0);
							expect(createdWithdrawalRequest[8]).to.be.equal(0);
							expect(createdWithdrawalRequest[10].length).to.be.equal(0);
						}
					);

					it(
						"Should have 0 in _openWithdrawalRequestIds[0]..",
						async () => {
							expect(
								(await iglooFiV1Vault.openWithdrawalRequestIds())[0]
							).to.be.equal(0);
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
							
							await expect(
								iglooFiV1Vault.connect(addr2).voteOnWithdrawalRequest(
									0,
									true
								)
							).to.be.rejected;
						}
					);

					it(
						"Should be able vote on WithdrawalRequest and add voter to _withdrawalRequest[].votedVoters..",
						async () => {
							const [, addr1] = await ethers.getSigners();
							
							await iglooFiV1Vault.connect(addr1).voteOnWithdrawalRequest(
								0,
								true
							)

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
								iglooFiV1Vault.connect(addr1).voteOnWithdrawalRequest(
									0,
									true
								)
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
							
							await expect(
								iglooFiV1Vault.connect(addr2).processWithdrawalRequest(0)
							).to.be.rejected;
						}
					);
	
					it(
						"Should fail to process WithdrawalRequest because not votes..",
						async () => {
							const [,addr1, addr2] = await ethers.getSigners();
	
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
							const [,addr1, addr2] = await ethers.getSigners();

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
	
							const recieverBalanceBefore = await ethers.provider.getBalance(
								addr2.address
							);
							
							// Fast-forward 7 days
							await ethers.provider.send('evm_increaseTime', [sevenDaysInSeconds]);
							
							await iglooFiV1Vault.connect(addr1).processWithdrawalRequest(0);


							const recieverBalanceAfter = await ethers.provider.getBalance(
								addr2.address
							);
	
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
						"Should have 1 in _openWithdrawalRequestIds[0]..",
						async () => {
							expect(
								(await iglooFiV1Vault.openWithdrawalRequestIds())[0]
							).to.be.equal(1);
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
							
							await iglooFiV1Vault.connect(addr1).voteOnWithdrawalRequest(
								1,
								true
							)

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

							await expect(
								recieverBalanceAfter - recieverBalanceBefore
							).to.be.equal(50);
						}
					)
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

						expect(
							(await iglooFiV1Vault.openWithdrawalRequestIds())[0]
						).to.be.equal(2);

						expect(
							(await iglooFiV1Vault.openWithdrawalRequestIds())[1]
						).to.be.equal(3);
					}
				);
			});


			describe("VerifySignature", function () {
				it("Check signature", async function () {
					const [owner] = await ethers.getSigners();
				
					// Get contract
					const VerifySignature = await ethers.getContractFactory("VerifySignature");

					// Deploy contract
					const contract = await VerifySignature.deploy();
					await contract.deployed();

					const hash = await contract.getMessageHash("Hello, world!");
					const signature = await owner.signMessage(ethers.utils.arrayify(hash));
					const ethHash = await contract.ECDSA_toEthSignedMessageHash(hash);

					// Correct signer recovered
					expect(
						await contract.ECDSA_recover(ethHash, signature)
					).to.equal(owner.address);

					// Correct signature and message
					expect(
						await contract.verify(owner.address, "Hello, world!", signature)
					).to.equal(true);
				});
			});

			/*
			describe("createSignedMessage", async () => {
				it(
					"Should revert when unauthorized msg.sender calls..",
					async () => {
						const [,, addr2] = await ethers.getSigners();
						
						await expect(
							iglooFiV1Vault.connect(addr2).signMessage(
								ethers.utils.toUtf8Bytes("Hello, world!")
							)
						).to.be.rejected;
					}
				);

				it("should allow address 1 to sign a message..", async () => {
					const [, addr1] = await ethers.getSigners();
					
					await iglooFiV1Vault.connect(addr1).signMessage(
						ethers.utils.toUtf8Bytes("Hello, world!")
					);

					const signedMessage = await iglooFiV1VaultsMultiSignedMessages.messageToSignedMessage(
						iglooFiV1Vault.address,
						ethers.utils.toUtf8Bytes("Hello, world!")
					);

					await expect(
						await iglooFiV1VaultsMultiSignedMessages.signedMessageVotes(
							iglooFiV1Vault.address,
							signedMessage
						)
					).to.be.equal(1);
				});

				it("should NOT allow double vote on a signed message..", async () => {
					const [, addr1] = await ethers.getSigners();

					await iglooFiV1Vault.connect(addr1).signMessage(
						ethers.utils.toUtf8Bytes("Hello, world!")
					);

					const signedMessage = await iglooFiV1VaultsMultiSignedMessages.messageToSignedMessage(
						iglooFiV1Vault.address,
						ethers.utils.toUtf8Bytes("Hello, world!")
					);

					await expect(
						await iglooFiV1VaultsMultiSignedMessages.signedMessageVotes(
							iglooFiV1Vault.address,
							signedMessage
						)
					).to.be.equal(1);
				});

				it("should allow address 2 to sign a message..", async () => {
					const [,, addr2] = await ethers.getSigners();

					await iglooFiV1Vault.addVoter(addr2.address);

					await iglooFiV1Vault.connect(addr2).signMessage(
						ethers.utils.toUtf8Bytes("Hello, world!")
					);

					const signedMessage = await iglooFiV1VaultsMultiSignedMessages.messageToSignedMessage(
						iglooFiV1Vault.address,
						ethers.utils.toUtf8Bytes("Hello, world!")
					);

					await expect(
						await iglooFiV1VaultsMultiSignedMessages.signedMessageVotes(
							iglooFiV1Vault.address,
							signedMessage
						)
					).to.be.equal(2);
				});
			});
			*/
		});


		/**
		* @dev Restriction: DEFAULT_ADMIN_ROLE
		*/
		describe("Restriction: DEFAULT_ADMIN_ROLE", async () => {
			/**
			 * @dev deleteWithdrawalRequest
			*/
			describe("updateWithdrawalRequestLatestRelevantApproveVoteTime", async () => {
				it(
					"Should update the latestRelevantApproveVoteTime to ADD seconds..",
					async () => {
						const beforeBlockTimestamp: number = parseInt(
							(await iglooFiV1Vault.withdrawalRequest(3))[9]
						);
						
						await iglooFiV1Vault.updateWithdrawalRequestLatestRelevantApproveVoteTime(
							3,
							true,
							10
						)
						
						const afterBlockTimestamp: number = parseInt(
							(await iglooFiV1Vault.withdrawalRequest(3))[9]
						);

						expect(beforeBlockTimestamp + 10).to.be.equal(afterBlockTimestamp);
					}
				);

				it(
					"Should update the latestRelevantApproveVoteTime to SUBTRACT seconds..",
					async () => {
						const beforeBlockTimestamp: number = parseInt(
							(await iglooFiV1Vault.withdrawalRequest(3))[9]
						);

						await iglooFiV1Vault.updateWithdrawalRequestLatestRelevantApproveVoteTime(
							3,
							false,
							10
						)
						
						const afterBlockTimestamp: number = parseInt(
							(await iglooFiV1Vault.withdrawalRequest(3))[9]
						);

						expect(beforeBlockTimestamp - 10).to.be.equal(afterBlockTimestamp);
					}
				);
			});

			
			/**
			 * @dev deleteWithdrawalRequest
			*/
			describe("deleteWithdrawalRequest", async () => {
				it(
					"Should revert when unauthorized msg.sender calls..",
					async () => {
						const [, addr1] = await ethers.getSigners();
						
						await expect(
							iglooFiV1Vault.connect(addr1).deleteWithdrawalRequest(2)
						).to.be.rejected;
					}
				);

				it(
					"Should be able to delete WithdrawalRequest..",
					async () => {
						await iglooFiV1Vault.deleteWithdrawalRequest(2);

						expect(
							(await iglooFiV1Vault.openWithdrawalRequestIds())[0]
						).to.be.equal(3);

						expect(
							(await iglooFiV1Vault.openWithdrawalRequestIds()).length
						).to.be.equal(1);
					}
				);
			});
		});
	});
});