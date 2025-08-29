# Quick Start

Get up and running with MetaTx-Contracts in just a few minutes!

## Prerequisites

Before you begin, make sure you have:

- **Node.js** (v16 or higher)
- **npm** or **yarn** package manager
- **Git** for cloning the repository
- A **wallet** with testnet tokens for deployment

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/DINetworks/MetaTx-Contracts.git
cd MetaTx-Contracts
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Environment Setup

Create a `.env` file in the root directory:

```env
PRIVATE_KEY=your_private_key_here
BSCSCAN_API_KEY=your_bscscan_api_key
INFURA_API_KEY=your_infura_api_key
```

{% hint style="warning" %}
**Security Note**: Never commit your private keys to version control. Use environment variables or secure key management systems.
{% endhint %}

## Compilation

Compile the smart contracts:

```bash
npx hardhat compile
```

You should see output similar to:

```
Compiling 15 files with 0.8.20
Solidity compilation finished successfully
```

## Testing

Run the test suite to ensure everything works:

```bash
npx hardhat test
```

Expected output:
```
  MetaTxGateway
    ✓ Should initialize correctly
    ✓ Should authorize relayers
    ✓ Should execute meta-transactions with native token
    ✓ Should handle batch transactions
    ✓ Should refund unused native tokens

  GasCreditVault
    ✓ Should deposit credits
    ✓ Should withdraw credits
    ✓ Should consume credits for gas

  15 passing (2.3s)
```

## Deploy to Testnet

Deploy your first MetaTxGateway contract:

```bash
# Deploy to BSC Testnet
npx hardhat run scripts/deploy-metatx-v1.js --network bsctestnet
```

You'll see deployment information:

```
🚀 Deploying MetaTxGateway with fresh proxy...
📋 Deploying with account: 0x742d35Cc6634C0532925a3b8E3c03e1B65b0c4EA
💰 Account balance: 0.5 ETH

📦 Deploying MetaTxGateway implementation and proxy...
✅ Proxy deployed to: 0x1234567890123456789012345678901234567890
✅ Implementation deployed to: 0x0987654321098765432109876543210987654321

🔍 Verifying deployment...
👤 Owner: 0x742d35Cc6634C0532925a3b8E3c03e1B65b0c4EA
📝 Version: v1.0.0-native-token-support
✅ Owner correctly set to deployer
✅ Relayer authorization test passed

🎉 Deployment completed successfully!
```

## First Meta-Transaction

Let's execute your first gasless transaction:

### 1. Set Up Relayer Authorization

```javascript
const { ethers } = require("hardhat");

async function authorizeRelayer() {
    const MetaTxGateway = await ethers.getContractAt(
        "MetaTxGateway", 
        "0x1234567890123456789012345678901234567890" // Your deployed address
    );
    
    const relayerAddress = "0x742d35Cc6634C0532925a3b8E3c03e1B65b0c4EA";
    await MetaTxGateway.setRelayerAuthorization(relayerAddress, true);
    
    console.log("✅ Relayer authorized!");
}
```

### 2. Create a Meta-Transaction

```javascript
// Example: Transfer ERC20 tokens via meta-transaction
const metaTxs = [{
    to: "0xTokenContractAddress",
    value: 0, // No native token for ERC20 transfer
    data: tokenContract.interface.encodeFunctionData("transfer", [recipient, amount])
}];
```

### 3. Sign the Batch (EIP-712)

```javascript
const domain = {
    name: "MetaTxGateway",
    version: "1",
    chainId: await ethers.provider.getNetwork().then(n => n.chainId),
    verifyingContract: MetaTxGateway.address
};

const types = {
    MetaTransaction: [
        { name: "to", type: "address" },
        { name: "value", type: "uint256" },
        { name: "data", type: "bytes" }
    ],
    MetaTransactions: [
        { name: "from", type: "address" },
        { name: "metaTxs", type: "MetaTransaction[]" },
        { name: "nonce", type: "uint256" },
        { name: "deadline", type: "uint256" }
    ]
};

const value = {
    from: userAddress,
    metaTxs,
    nonce: await MetaTxGateway.getNonce(userAddress),
    deadline: Math.floor(Date.now() / 1000) + 3600 // 1 hour from now
};

const signature = await userSigner._signTypedData(domain, types, value);
```

### 4. Calculate Required Value

```javascript
const requiredValue = await MetaTxGateway.calculateRequiredValue(metaTxs);
```

### 5. Execute the Meta-Transaction

```javascript
const tx = await MetaTxGateway.executeMetaTransactions(
    userAddress,
    metaTxs,
    signature,
    value.nonce,
    value.deadline,
    { value: requiredValue }
);

console.log("✅ Meta-transaction executed:", tx.hash);
```

## What's Next?

Now that you have MetaTx-Contracts running:

1. **[Learn about the contracts](../contracts/overview.md)** - Understand the architecture
2. **[Deploy to mainnet](../deployment/deployment-guide.md)** - Production deployment guide
3. **[Integrate with your frontend](../integration/frontend-integration.md)** - Add gasless functionality
4. **[Set up gas credits](../integration/gas-credit-management.md)** - Enable multi-token payments

## Need Help?

- 📖 **Documentation**: Browse this guide for detailed information
- 🐛 **Issues**: Report bugs on [GitHub Issues](https://github.com/DINetworks/MetaTx-Contracts/issues)
- 💬 **Community**: Join our community discussions
- 🔍 **Examples**: Check out the `test/` directory for working examples

{% hint style="success" %}
**Congratulations!** You've successfully set up MetaTx-Contracts and executed your first gasless transaction. Welcome to the future of user-friendly DeFi! 🎉
{% endhint %}
