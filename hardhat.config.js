require('dotenv').config();
require("@nomicfoundation/hardhat-ethers")
require("@nomicfoundation/hardhat-chai-matchers");
require("@nomicfoundation/hardhat-verify");
require("hardhat-contract-sizer");
require('@openzeppelin/hardhat-upgrades');

module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 200  // Optimization runs
      },
      // Optional: Additional output selection
      outputSelection: {
        "*": {
          "*": ["abi", "evm.bytecode", "evm.deployedBytecode", "evm.methodIdentifiers"]
        }
      }
    }
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
  },
  networks: {
    hardhat: {
      mining: {
        auto: false,
        interval: 1000 // Optional manual mining interval
      }
    },
    localhost: {
      url: "http://127.0.0.1:8545"
    },
    mainnet: {
      url: process.env.MAINNET_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      timeout: 300000, // 5 minutes for mainnet
      confirmations: 3
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
    base: {
      url: process.env.BASE_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      timeout: 120000, // 2 minutes
      confirmations: 2
    },
    optimism: {
      url: process.env.OPTIMISM_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      timeout: 120000, // 2 minutes
      confirmations: 2
    },
    avalanche: {
      url: process.env.AVALANCHE_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      timeout: 120000, // 2 minutes timeout
      confirmations: 2, // Wait for 2 confirmations
      gasPrice: "auto"
    },
    arbitrum: {
      url: process.env.ARBITRUM_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      timeout: 120000, // 2 minutes
      confirmations: 2
    },    
    polygon: {
      url: process.env.POLYGON_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      timeout: 180000, // 3 minutes for Polygon
      confirmations: 3
    },
    bsc: {
      url: process.env.BSC_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      timeout: 120000, // 2 minutes
      confirmations: 2
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  },
  // Global timeout settings
  mocha: {
    timeout: 300000 // 5 minutes for tests
  },
  // OpenZeppelin Upgrades plugin configuration
  upgrades: {
    timeout: parseInt(process.env.DEPLOYMENT_TIMEOUT) || 300000, // 5 minutes default
    pollingInterval: parseInt(process.env.POLLING_INTERVAL) || 5000 // 5 seconds default
  },
  // Add paths if needed
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  }
};