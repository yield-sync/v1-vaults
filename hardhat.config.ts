require("dotenv").config();
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-solhint";


/**
 * @type import("hardhat/config").HardhatUserConfig
*/
const config: any = {
	etherscan: {
		apiKey: {
			mainnet: process.env.ETHERSCAN_API_KEY,
			goerli: process.env.ETHERSCAN_API_KEY,
			optimisticEthereum: process.env.OPTIMISTIC_ETHERSCAN_API_KEY,
			sepolia: process.env.ETHERSCAN_API_KEY,
		}
	},
	networks: {
		goerli: {
			url: `https://goerli.infura.io/v3/${process.env.INFURA_API_KEY}`,
			accounts: [`0x${process.env.PRIVATE_KEY}`]
		},
		ropsten: {
			url: `https://ropsten.infura.io/v3/${process.env.INFURA_API_KEY}`,
			accounts: [`0x${process.env.PRIVATE_KEY}`]
		},
		mainnet: {
			url: `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
			accounts: [`0x${process.env.PRIVATE_KEY}`]
		},
		optimism: {
			url: `https://mainnet.optimism.io`,
			accounts: [`0x${process.env.PRIVATE_KEY}`]
		},
		sepolia: {
			url: `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
			accounts: [`0x${process.env.PRIVATE_KEY}`]
		},
	},
	paths: {
		sources: "./contracts",
	},
	solidity: "0.8.18"
};


export default config;
