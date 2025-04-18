require('dotenv').config();
require("@nomicfoundation/hardhat-ethers")
require("@nomicfoundation/hardhat-chai-matchers");
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
    crossfi: {
      chainId: 4157,
      url: "https://rpc.testnet.ms", 
      accounts: [process.env.PRIVATE_KEY], 
    },
  },
  // Add paths if needed
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  }
};