# Installation

Complete installation guide for setting up MetaTx-Contracts development environment.

## Prerequisites

### Required Software

- **Node.js** (v16.0.0 or higher)
- **npm** (v8.0.0 or higher) or **yarn** (v1.22.0 or higher)
- **Git** (v2.30.0 or higher)

### Recommended Tools

- **Visual Studio Code** with Solidity extensions
- **MetaMask** browser extension for testing
- **Hardhat** for development and testing

## System Requirements

### Hardware
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 5GB free space for node_modules and artifacts
- **CPU**: Modern multi-core processor

### Operating Systems
- **Windows**: 10 or later
- **macOS**: 10.15 or later  
- **Linux**: Ubuntu 18.04+ or equivalent

## Installation Steps

### 1. Clone Repository

```bash
# Clone the repository
git clone https://github.com/DINetworks/MetaTx-Contracts.git

# Navigate to project directory
cd MetaTx-Contracts

# Check current branch
git branch
```

### 2. Install Dependencies

```bash
# Install all dependencies
npm install

# Or using yarn
yarn install
```

### 3. Environment Configuration

Create a `.env` file in the root directory:

```bash
# Copy example environment file
cp .env.example .env
```

Edit `.env` with your configuration:

```env
# Private key for deployment (without 0x prefix)
PRIVATE_KEY=
RELAYER_PRIVATE_KEY=

MAINNET_RPC_URL=https://mainnet.gateway.tenderly.co
SEPOLIA_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com/
BSC_RPC_URL=https://bsc-dataseed.binance.org/
POLYGON_RPC_URL=https://polygon-rpc.com/
BASE_RPC_URL=https://mainnet.base.org/
OPTIMISM_RPC_URL=https://optimism-rpc.publicnode.com/
ARBITRUM_RPC_URL=https://arbitrum-one-rpc.publicnode.com/
AVALANCHE_RPC_URL=https://avalanche-c-chain-rpc.publicnode.com/

ETHERSCAN_API_KEY=
```

{% hint style="warning" %}
**Security Warning**: Never commit your private keys to version control. Use environment variables or secure key management systems.
{% endhint %}

### 4. Verify Installation

```bash
# Compile contracts
npx hardhat compile

# Run tests
npx hardhat test

# Check Hardhat tasks
npx hardhat help
```

Expected output:
```
✨ Compiled 15 files successfully
✅ All tests passed (25 passing)
📋 Hardhat tasks available
```

## Development Setup

### IDE Configuration

#### Visual Studio Code Extensions

Install these recommended extensions:

```json
{
  "recommendations": [
    "juanblanco.solidity",
    "tintinweb.solidity-visual-auditor",
    "esbenp.prettier-vscode",
    "ms-vscode.vscode-typescript-next"
  ]
}
```

#### Settings Configuration

Create `.vscode/settings.json`:

```json
{
  "solidity.compileUsingRemoteVersion": "v0.8.20+commit.a1b79de6",
  "solidity.defaultCompiler": "remote",
  "solidity.formatter": "prettier",
  "editor.formatOnSave": true,
  "typescript.preferences.importModuleSpecifier": "relative"
}
```

### Git Hooks Setup

Install pre-commit hooks:

```bash
# Install husky for git hooks
npm install --save-dev husky

# Set up pre-commit hook
npx husky add .husky/pre-commit "npm run lint && npm run test"
```

## Network Configuration

### Testnet Setup

#### BSC Testnet
- **Network Name**: BSC Testnet
- **RPC URL**: https://data-seed-prebsc-1-s1.binance.org:8545/
- **Chain ID**: 97
- **Currency Symbol**: tBNB
- **Block Explorer**: https://testnet.bscscan.com

#### Ethereum Sepolia
- **Network Name**: Sepolia
- **RPC URL**: https://sepolia.infura.io/v3/YOUR_INFURA_KEY
- **Chain ID**: 11155111
- **Currency Symbol**: ETH
- **Block Explorer**: https://sepolia.etherscan.io

### Mainnet Configuration

Update `hardhat.config.js` networks section:

```javascript
networks: {
  bsctestnet: {
    url: process.env.BSC_TESTNET_RPC || "https://data-seed-prebsc-1-s1.binance.org:8545/",
    chainId: 97,
    accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
  },
  bsc: {
    url: process.env.BSC_RPC_URL || "https://bsc-dataseed1.binance.org/",
    chainId: 56,
    accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
  }
}
```

## Troubleshooting

### Common Issues

#### Node Version Conflicts
```bash
# Check Node version
node --version

# Install correct version using nvm
nvm install 18
nvm use 18
```

#### Permission Errors
```bash
# Fix npm permissions (macOS/Linux)
sudo chown -R $(whoami) ~/.npm

# Use yarn instead of npm
npm install -g yarn
yarn install
```

#### Compilation Errors
```bash
# Clear Hardhat cache
npx hardhat clean

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

#### Network Connection Issues
```bash
# Test network connectivity
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  https://bsc-dataseed1.binance.org/
```

### Getting Help

- **Documentation**: Browse this GitBook
- **GitHub Issues**: Report bugs and request features
- **Community**: Join our Discord/Telegram
- **Stack Overflow**: Tag questions with `metatx-contracts`

## Next Steps

After successful installation:

1. **[Quick Start Guide](quick-start.md)** - Deploy your first contract
2. **[Contract Overview](../contracts/overview.md)** - Understand the architecture
3. **[Deployment Guide](../deployment/deployment-guide.md)** - Production deployment
4. **[Integration Guide](../integration/frontend-integration.md)** - Add to your dApp

{% hint style="success" %}
**Installation Complete!** You're ready to start building with MetaTx-Contracts. 🎉
{% endhint %}
