import { expect } from "chai";
const { ethers } = require("hardhat");


describe("IglooFi V1 Vault", async () => {
	let iglooFiV1Vault: any;
	let mockERC20: any;


	/**
	 * @notice Deploy the contracts
	 * @dev Deploy IglooFiV1Vault.sol
	*/
	before("[before] Deploy IglooFiV1Vault.sol..", async () => {
		const [owner] = await ethers.getSigners();

		const IglooFiV1Vault = await ethers.getContractFactory(
			"IglooFiV1Vault"
		);

		iglooFiV1Vault = await IglooFiV1Vault.deploy(
			owner.address,
			2,
			10
		);
		iglooFiV1Vault = await iglooFiV1Vault.deployed();
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
	* @dev recieve
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
	});


	/**
	* @dev Initial values set by constructor
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
			"Should initialize withdrawalDelaySeconds 10..",
			async () => {
				expect(await iglooFiV1Vault.withdrawalDelaySeconds()).to.equal(
					10
				);
			}
		);
	});


	/**
	 * @dev sign
	 * TODO: Incomploete, need to create tests for this function
	*/
	describe("Auth: DEFAULT_ADMIN_ROLE", async () => {
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
						iglooFiV1Vault.connect(addr1).updateWithdrawalDelaySeconds(5)
					).to.be.rejected;
				}
			);

			it(
				"Should be able to update withdrawalDelaySeconds..",
				async () => {
					await iglooFiV1Vault.updateWithdrawalDelaySeconds(5)
	
					await expect(
						await iglooFiV1Vault.withdrawalDelaySeconds()
					).to.be.equal(5);
				}
			);
		});
	});


	/**
	 * @dev VOTER
	*/
	describe("Auth: VOTER", async () => {
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
							addr2.address,
							"0x0000000000000000000000000000000000000000",
							ethers.utils.parseEther(".5"),
							0
						)
					).to.be.rejected;
				}
			);

			it(
				"Should be able to create a WithdrawalRequest for Ether..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();
					
					await iglooFiV1Vault.connect(addr1).createWithdrawalRequest(
						true,
						addr2.address,
						"0x0000000000000000000000000000000000000000",
						ethers.utils.parseEther(".5"),
						0
					);
					
					const createdWithdrawalRequest: any = await iglooFiV1Vault.withdrawalRequest(0);

					expect(createdWithdrawalRequest[0]).to.be.true;
					expect(createdWithdrawalRequest[1]).to.be.equal(addr1.address);
					expect(createdWithdrawalRequest[2]).to.be.equal(addr2.address);
					expect(createdWithdrawalRequest[3]).to.be.equal(
						"0x0000000000000000000000000000000000000000"
					);
					expect(createdWithdrawalRequest[4]).to.be.equal(
						ethers.utils.parseEther(".5")
					);
					expect(createdWithdrawalRequest[5]).to.be.equal(0);
					expect(createdWithdrawalRequest[6]).to.be.equal(0);
					expect(createdWithdrawalRequest[8].length).to.be.equal(0);
				}
			);

			it(
				"Should be able to create a WithdrawalRequest for ERC20 token..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();
					
					await iglooFiV1Vault.connect(addr1).createWithdrawalRequest(
						false,
						addr2.address,
						mockERC20.address,
						50,
						0
					);
					
					const createdWithdrawalRequest: any = await iglooFiV1Vault.withdrawalRequest(1);

					expect(createdWithdrawalRequest[0]).to.be.false;
					expect(createdWithdrawalRequest[1]).to.be.equal(addr1.address);
					expect(createdWithdrawalRequest[2]).to.be.equal(addr2.address);
					expect(createdWithdrawalRequest[3]).to.be.equal(mockERC20.address);
					expect(createdWithdrawalRequest[4]).to.be.equal(50);
					expect(createdWithdrawalRequest[5]).to.be.equal(0);
					expect(createdWithdrawalRequest[6]).to.be.equal(0);
					expect(createdWithdrawalRequest[8].length).to.be.equal(0);
				}
			);
		});

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
				"Should be able vote on WithdrawalRequest..",
				async () => {
					const [, addr1] = await ethers.getSigners();
					
					await iglooFiV1Vault.connect(addr1).voteOnWithdrawalRequest(
						0,
						true
					)

					const createdWithdrawalRequest: any = await iglooFiV1Vault.withdrawalRequest(0);

					expect(createdWithdrawalRequest[6]).to.be.equal(1);
				}
			);
		});
	});


	/**
	 * @dev sign
	 * TODO: Incomploete, need to create tests for this function
	*/
	describe("sign", async () => {})
});