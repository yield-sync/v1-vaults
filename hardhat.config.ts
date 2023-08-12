import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-solhint";

require("dotenv").config();
require("@nomiclabs/hardhat-ethers");
require("@eth-optimism/plugins/hardhat/compiler");


export default {
	etherscan: {
		apiKey: {
			mainnet: process.env.ETHERSCAN_API_KEY,
			goerli: process.env.ETHERSCAN_API_KEY,
			optimisticEthereum: process.env.OPTIMISTIC_ETHERSCAN_API_KEY,
			optimisticGoerli: process.env.OPTIMISTIC_ETHERSCAN_API_KEY,
			sepolia: process.env.ETHERSCAN_API_KEY,
		}
	},
	networks: {
		goerli: {
			url: `https://goerli.infura.io/v3/${process.env.INFURA_API_KEY}`,
			accounts: [`0x${process.env.PRIVATE_KEY}` as string]
		},
		ropsten: {
			url: `https://ropsten.infura.io/v3/${process.env.INFURA_API_KEY}`,
			accounts: [`0x${process.env.PRIVATE_KEY}` as string]
		},
		mainnet: {
			url: `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
			accounts: [`0x${process.env.PRIVATE_KEY}` as string]
		},
		optimism: {
			url: `https://mainnet.optimism.io`,
			accounts: [`0x${process.env.PRIVATE_KEY}` as string],
			gasPrice: 15000000,
			ovm: true
		},
		optimismgoerli: {
			url: `https://goerli.optimism.io`,
			accounts: [`0x${process.env.PRIVATE_KEY}` as string],
			gasPrice: 15000000
		},
		sepolia: {
			url: `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
			accounts: [`0x${process.env.PRIVATE_KEY}` as string]
		},
		"base-mainnet": {
			url: "https://mainnet.base.org",
			accounts: [`0x${process.env.PRIVATE_KEY}` as string],
			gasPrice: 1000000000,
		},
		"base-goerli": {
			url: "https://goerli.base.org",
			accounts: [`0x${process.env.PRIVATE_KEY}` as string],
			gasPrice: 1000000000,
		},
		"base-local": {
			url: "http://localhost:8545",
			accounts: [`0x${process.env.PRIVATE_KEY}` as string],
			gasPrice: 1000000000,
		},
	},
	paths: {
		sources: "./contracts",
	},
	solidity: "0.8.18"
} as import("hardhat/config").HardhatUserConfig;
