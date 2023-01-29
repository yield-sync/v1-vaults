import { expect } from "chai";
const { ethers } = require("hardhat");


describe("IglooFiV1Vault", async () => {
	let iglooFiV1Vault: any;


	/**
	 * @notice Deploy the contracts
	 * @dev Deploy TestIglooFiGovernance.sol
	 * @dev Deploy IglooFiV1VaultFactory.sol
	*/
	before("[before] Deploy..", async () => {
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
	* @dev recieve
	*/
	describe("Contract", async () => {
		it(
			"Should be able to recieve ether..",
			async () => {
				const [, addr1] = await ethers.getSigners();
				
				// Send ether to IglooFiV1VaultFactory contract
				await addr1.sendTransaction({
					to: iglooFiV1Vault.address,
					value: ethers.utils.parseEther("1"),
				});

				await expect(
					await ethers.provider.getBalance(iglooFiV1Vault.address)
				).to.be.greaterThanOrEqual(ethers.utils.parseEther("1"));
			}
		);
	})


	/**
	* @dev Initial values set by constructor
	*/
	describe("Constructor Initialized values", async () => {
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
			)

			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1, addr2] = await ethers.getSigners();
		
					await expect(
						iglooFiV1Vault.connect(addr1).addVoter(addr2.address)
					).to.be.rejected;
				}
			)
		})

		describe("removeVoter", async () => {
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
			)

			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();
		
					await expect(
						iglooFiV1Vault.connect(addr1).removeVoter(addr1.address)
					).to.be.rejected;
				}
			)
		})

		describe("updateRequiredVoteCount", async () => {
			it(
				"Should be able to update requiredVoteCount..",
				async () => {
					await iglooFiV1Vault.updateRequiredVoteCount(3)
	
					await expect(
						await iglooFiV1Vault.requiredVoteCount()
					).to.be.equal(3);
				}
			)

			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();
		
					await expect(
						iglooFiV1Vault.connect(addr1).updateRequiredVoteCount(1)
					).to.be.rejected;
				}
			)
		})

		describe("updateWithdrawalDelaySeconds", async () => {
			it(
				"Should be able to update withdrawalDelaySeconds..",
				async () => {
					await iglooFiV1Vault.updateWithdrawalDelaySeconds(5)
	
					await expect(
						await iglooFiV1Vault.withdrawalDelaySeconds()
					).to.be.equal(5);
				}
			)

			it(
				"Should revert when unauthorized msg.sender calls..",
				async () => {
					const [, addr1] = await ethers.getSigners();
		
					await expect(
						iglooFiV1Vault.connect(addr1).updateWithdrawalDelaySeconds(0)
					).to.be.rejected;
				}
			)
		})
	})


	/**
	 * @dev sign
	 * TODO: Incomploete, need to create tests for this function
	*/
	describe("sign", async () => {})


	/**
	 * @dev VOTER
	*/
	describe("Auth: VOTER", async () => {
		/**
		 * @dev createWithdrawalRequest
		*/
		describe("createWithdrawalRequest", async () => {
			it(
				"Should be able to create a WithdrawalRequest..",
				async () => {
					
					
				}
			)
		})
	})

});