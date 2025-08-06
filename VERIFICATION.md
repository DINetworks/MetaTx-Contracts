# Contract Verification Guide

## Quick Commands

### Get verification examples:
```bash
npm run verify:help
npm run verify:metatx  
npm run verify:gascredit
```

## Manual Verification

### MetaTxGateway
```bash
npx hardhat verify --contract contracts/MetaTxGateway.sol:MetaTxGateway --network mainnet YOUR_DEPLOYED_ADDRESS
```

### GasCreditVault  
```bash
npx hardhat verify --contract contracts/GasCreditVault.sol:GasCreditVault --network mainnet YOUR_DEPLOYED_ADDRESS
```

## Network Examples

### Mainnet
```bash
npx hardhat verify --contract contracts/MetaTxGateway.sol:MetaTxGateway --network mainnet 0x1234567890123456789012345678901234567890
```

### Sepolia Testnet
```bash
npx hardhat verify --contract contracts/MetaTxGateway.sol:MetaTxGateway --network sepolia 0x1234567890123456789012345678901234567890
```

### Polygon
```bash
npx hardhat verify --contract contracts/MetaTxGateway.sol:MetaTxGateway --network polygon 0x1234567890123456789012345678901234567890
```

## Important Notes

1. **Replace YOUR_DEPLOYED_ADDRESS** with the actual deployed contract address
2. **For upgradeable contracts**: Verify the implementation contract address, not the proxy
3. **Constructor arguments**: Add them after the address if your contract has constructor parameters
4. **API Keys**: Make sure you have the correct API keys in your `.env` file

## Environment Setup

Create a `.env` file with:
```
ETHERSCAN_API_KEY=your_etherscan_api_key
POLYGONSCAN_API_KEY=your_polygonscan_api_key  
BSCSCAN_API_KEY=your_bscscan_api_key
```
