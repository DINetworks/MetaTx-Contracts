# MetaTx-Contracts

## 🚀 Gasless Meta-Transaction System with Native Token Support

A comprehensive smart contract system enabling gasless user experiences through meta-transactions with built-in native token handling and multi-token gas credit management.

## 📋 Overview

This project provides two main contracts:

### 🔄 MetaTxGateway v1.0.0
**Enhanced gasless transaction execution gateway**
- **Native token validation**: Requires exact native token amount for meta-transactions
- **Automatic refunds**: Returns unused tokens when transactions fail
- **Batch processing**: Execute multiple transactions in a single call
- **EIP-712 signatures**: Secure signature verification with version 2 domain separator
- **UUPS upgradeable**: Safe proxy pattern for future enhancements
- **Comprehensive logging**: Detailed events for monitoring and debugging

### 💰 GasCreditVault
**Multi-token gas credit management system**
- **Multi-token support**: Accept various ERC20 tokens and stablecoins
- **Chainlink integration**: Real-time price feeds for accurate credit calculations
- **Credit management**: Deposit, withdraw, transfer, and consume credits
- **Owner controls**: Automated withdrawal of consumed credits
- **Emergency features**: Pause and emergency withdrawal capabilities

## 🛠️ Technology Stack

- **Solidity**: 0.8.20 with Via IR optimization
- **OpenZeppelin**: v5.3.0 upgradeable contracts
- **Hardhat**: Development and testing framework
- **Chainlink**: Price feed oracles
- **EIP-712**: Typed structured data hashing and signing

## 🚀 Quick Start

### Installation

```shell
npm install
```

### Compilation

```shell
npx hardhat compile
```

### Testing

```shell
# Run all tests
npx hardhat test

# Run with gas reporting
REPORT_GAS=true npx hardhat test

# Run specific test file
npx hardhat test test/MetaTxGateway.test.js
```

### Deployment

```shell
# Deploy to BSC Testnet
npx hardhat run scripts/deploy-metatx.js --network bsctestnet

# Deploy to BSC Mainnet
npx hardhat run scripts/deploy-metatx.js --network bsc
```

### Verification

```shell
# Verify contracts on BSCScan
PROXY_ADDRESS=0x... npx hardhat run scripts/verify-metatx-v1.js --network bsc
```

## 📁 Project Structure

```
contracts/
├── MetaTxGateway.sol          # Enhanced meta-transaction gateway
└── GasCreditVault.sol         # Multi-token gas credit system

scripts/
└── deploy-metatx.js        # MetaTxGateway deployment

test/
├── MetaTxGateway.test.js      # Gateway contract tests
└── GasCreditVault.test.js     # Vault contract tests

```

## 🔧 Configuration

### Hardhat Networks

Update `hardhat.config.js` with your network configurations:

```javascript
networks: {
  bsctestnet: {
    url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
    accounts: [process.env.PRIVATE_KEY]
  },
  bsc: {
    url: "https://bsc-dataseed1.binance.org/",
    accounts: [process.env.PRIVATE_KEY]
  }
}
```

### Environment Variables

Create a `.env` file:

```env
PRIVATE_KEY=your_private_key_here
BSCSCAN_API_KEY=your_bscscan_api_key
PROXY_ADDRESS=deployed_proxy_address
```

## 💡 Usage Examples

### MetaTxGateway Integration

```javascript
const MetaTxGateway = await ethers.getContractAt("MetaTxGateway", PROXY_ADDRESS);

// Calculate required native token value
const metaTxData = ethers.utils.defaultAbiCoder.encode(
  ["tuple(address to, uint256 value, bytes data)[]"],
  [transactions]
);
const requiredValue = await MetaTxGateway.calculateRequiredValue(metaTxData);

// Execute meta-transactions with native token
const tx = await MetaTxGateway.executeMetaTransactions(
  userAddress,
  metaTxData,
  signature,
  nonce,
  deadline,
  { value: requiredValue }
);
```

### GasCreditVault Integration

```javascript
const GasCreditVault = await ethers.getContractAt("GasCreditVault", VAULT_ADDRESS);

// Deposit USDT for gas credits
await usdtToken.approve(GasCreditVault.address, amount);
await GasCreditVault.depositCredit(usdtToken.address, amount, userAddress);

// Check credit balance
const credits = await GasCreditVault.getCreditBalance(userAddress);
```

## 🛡️ Security Features

### MetaTxGateway
- **Native token validation**: Prevents under/over-funding
- **Automatic refunds**: Protects against fund loss
- **EIP-712 signatures**: Secure meta-transaction authorization
- **Replay protection**: Nonce-based security
- **Access controls**: Owner and relayer management

### GasCreditVault
- **Price feed validation**: Chainlink oracle integration
- **Stale price protection**: Prevents manipulation
- **Emergency controls**: Pause and withdrawal mechanisms
- **Multi-token support**: Flexible payment options
- **Owner withdrawal**: Automatic fee collection

## 📚 Documentation

- **[Storage Safety Guide](STORAGE_SAFETY_GUIDE.md)**: Upgrade safety and storage layout
- **[Deployment Guide](DEPLOYMENT_GUIDE_V1.md)**: Step-by-step deployment instructions
- **[Release Notes](TAG_RELEASE_v1.0.0.md)**: Version history and features

## 🧪 Testing

The project includes comprehensive test suites:

```shell
# Run MetaTxGateway tests
npx hardhat test test/MetaTxGateway.test.js

# Run GasCreditVault tests
npx hardhat test test/GasCreditVault.test.js

# Run all tests with coverage
npm run test:coverage
```

## 🌐 Supported Networks

- **BSC Mainnet**: Binance Smart Chain
- **BSC Testnet**: For development and testing
- **Ethereum**: Mainnet and testnets
- **Polygon**: MATIC network support

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For questions and support:
- **GitHub Issues**: Bug reports and feature requests
- **Documentation**: Comprehensive guides in the `docs/` folder
- **Code Examples**: Working examples in `scripts/` and `test/` folders

## 🚀 Deployment Status

- **MetaTxGateway v1.0.0**: ✅ Production ready with native token support
- **GasCreditVault**: ✅ Multi-token credit system
- **Token Contracts**: ✅ DI ecosystem ready
- **BSCScan Verification**: ✅ Standard JSON Input support

---

**Built with ❤️ for gasless DeFi experiences**
