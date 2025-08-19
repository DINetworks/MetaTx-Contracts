# Troubleshooting Guide

Common issues and solutions when working with MetaTx-Contracts.

## Common Issues

### Wallet Connection Problems

#### MetaMask Not Detected

**Problem:** Application can't detect MetaMask extension.

**Symptoms:**
- "MetaMask not installed" error
- `window.ethereum` is undefined
- Wallet connection fails

**Solutions:**

1. **Check MetaMask Installation:**
   ```javascript
   if (typeof window.ethereum === 'undefined') {
     alert('Please install MetaMask to use this application');
     window.open('https://metamask.io/', '_blank');
   }
   ```

2. **Wait for Extension Load:**
   ```javascript
   // Wait for MetaMask to load
   const checkMetaMask = () => {
     if (window.ethereum) {
       initializeWallet();
     } else {
       setTimeout(checkMetaMask, 100);
     }
   };
   checkMetaMask();
   ```

3. **Use Extension Detection:**
   ```javascript
   const isMetaMaskInstalled = () => {
     const { ethereum } = window;
     return Boolean(ethereum && ethereum.isMetaMask);
   };
   ```

#### Wrong Network

**Problem:** User connected to wrong blockchain network.

**Symptoms:**
- Contract calls fail with network errors
- Transaction submission rejected
- Chain ID mismatch

**Solutions:**

1. **Auto Network Switch:**
   ```javascript
   async function switchToBSC() {
     try {
       await window.ethereum.request({
         method: 'wallet_switchEthereumChain',
         params: [{ chainId: '0x38' }], // BSC Mainnet
       });
     } catch (switchError) {
       if (switchError.code === 4902) {
         // Network not added, add it
         await addBSCNetwork();
       }
     }
   }
   
   async function addBSCNetwork() {
     await window.ethereum.request({
       method: 'wallet_addEthereumChain',
       params: [{
         chainId: '0x38',
         chainName: 'BNB Smart Chain',
         rpcUrls: ['https://bsc-dataseed1.binance.org/'],
         nativeCurrency: {
           name: 'BNB',
           symbol: 'BNB',
           decimals: 18
         },
         blockExplorerUrls: ['https://bscscan.com']
       }]
     });
   }
   ```

2. **Network Validation:**
   ```javascript
   const validateNetwork = (chainId) => {
     const supportedNetworks = [56, 97]; // BSC mainnet and testnet
     if (!supportedNetworks.includes(chainId)) {
       throw new Error(`Unsupported network. Please switch to BSC.`);
     }
   };
   ```

### Signature Issues

#### Invalid Signature Error

**Problem:** Meta-transaction signature verification fails.

**Symptoms:**
- `InvalidSignature()` error from contract
- Transaction rejected by relayer
- Signature recovery fails

**Common Causes & Solutions:**

1. **Wrong Domain Separator:**
   ```javascript
   // Ensure correct domain configuration
   const domain = {
     name: "MetaTxGateway",      // Must match contract
     version: "2.0.0",          // Must match contract version
     chainId: 56,               // Must match current network
     verifyingContract: "0x..." // Must be correct contract address
   };
   ```

2. **Incorrect Types Definition:**
   ```javascript
   // Ensure exact type structure
   const types = {
     MetaTransaction: [
       { name: "to", type: "address" },
       { name: "value", type: "uint256" },
       { name: "data", type: "bytes" },
       { name: "nonce", type: "uint256" },
       { name: "deadline", type: "uint256" }
     ]
   };
   ```

3. **Data Type Mismatches:**
   ```javascript
   // Convert all numbers to strings for signing
   const message = {
     to: transaction.to,
     value: transaction.value.toString(),    // BigInt to string
     data: transaction.data,
     nonce: transaction.nonce.toString(),    // BigInt to string
     deadline: transaction.deadline.toString() // BigInt to string
   };
   ```

4. **Signer Address Mismatch:**
   ```javascript
   // Verify signer address
   const signerAddress = await signer.getAddress();
   const expectedAddress = "0x...";
   
   if (signerAddress.toLowerCase() !== expectedAddress.toLowerCase()) {
     throw new Error('Signer address mismatch');
   }
   ```

#### Nonce Synchronization

**Problem:** Nonce mismatch between frontend and contract.

**Symptoms:**
- `InvalidNonce()` error
- Transaction order issues
- Duplicate nonce errors

**Solutions:**

1. **Always Fetch Latest Nonce:**
   ```javascript
   const getCurrentNonce = async (userAddress) => {
     const gateway = getMetaTxGateway();
     return await gateway.getNonce(userAddress);
   };
   
   // Use for each transaction
   const nonce = await getCurrentNonce(userAddress);
   ```

2. **Handle Concurrent Transactions:**
   ```javascript
   class NonceManager {
     constructor(gateway, userAddress) {
       this.gateway = gateway;
       this.userAddress = userAddress;
       this.pendingNonces = new Set();
     }
   
     async getNextNonce() {
       const currentNonce = await this.gateway.getNonce(this.userAddress);
       let nextNonce = currentNonce;
       
       // Find next available nonce
       while (this.pendingNonces.has(nextNonce.toString())) {
         nextNonce = nextNonce + 1n;
       }
       
       this.pendingNonces.add(nextNonce.toString());
       return nextNonce;
     }
   
     releaseNonce(nonce) {
       this.pendingNonces.delete(nonce.toString());
     }
   }
   ```

### Transaction Execution

#### Gas Estimation Failures

**Problem:** Transaction gas estimation fails.

**Symptoms:**
- "Cannot estimate gas" error
- Transaction reverts during estimation
- High gas estimates

**Solutions:**

1. **Manual Gas Limits:**
   ```javascript
   const executeWithFixedGas = async (transaction) => {
     return await gateway.executeMetaTransactions([transaction], {
       gasLimit: 500000 // Fixed gas limit
     });
   };
   ```

2. **Estimate with Buffer:**
   ```javascript
   const estimateGasWithBuffer = async (transaction) => {
     try {
       const estimated = await gateway.estimateGas.executeMetaTransactions([transaction]);
       return estimated * 120n / 100n; // 20% buffer
     } catch (error) {
       return 500000n; // Fallback gas limit
     }
   };
   ```

3. **Validate Transaction Data:**
   ```javascript
   const validateTransaction = (tx) => {
     if (!ethers.isAddress(tx.to)) {
       throw new Error('Invalid recipient address');
     }
     
     if (tx.value < 0) {
       throw new Error('Invalid value amount');
     }
     
     if (!tx.data.startsWith('0x')) {
       throw new Error('Invalid data format');
     }
   };
   ```

#### Transaction Reverts

**Problem:** Meta-transaction execution reverts.

**Common Revert Reasons & Solutions:**

1. **Insufficient Gas Credits:**
   ```javascript
   // Check credit balance before execution
   const checkCredits = async (userAddress, estimatedGas) => {
     const vault = getGasCreditVault();
     const balance = await vault.getCreditBalance(userAddress);
     const gasPrice = await provider.getGasPrice();
     const required = estimatedGas * gasPrice;
     
     if (balance < required) {
       throw new Error(`Insufficient credits. Required: ${ethers.formatEther(required)}, Available: ${ethers.formatEther(balance)}`);
     }
   };
   ```

2. **Expired Deadline:**
   ```javascript
   // Set appropriate deadline
   const setDeadline = () => {
     const now = Math.floor(Date.now() / 1000);
     return BigInt(now + 300); // 5 minutes from now
   };
   
   // Validate deadline
   const validateDeadline = (deadline) => {
     const now = Math.floor(Date.now() / 1000);
     if (Number(deadline) <= now) {
       throw new Error('Transaction deadline has passed');
     }
   };
   ```

3. **Target Contract Errors:**
   ```javascript
   // Simulate transaction first
   const simulateTransaction = async (tx) => {
     try {
       await provider.call({
         to: tx.to,
         data: tx.data,
         value: tx.value
       });
     } catch (error) {
       throw new Error(`Target transaction would fail: ${error.message}`);
     }
   };
   ```

### Gas Credits Issues

#### Credit Deposit Failures

**Problem:** Unable to deposit tokens for gas credits.

**Symptoms:**
- Token transfer fails
- Insufficient allowance error
- Unsupported token error

**Solutions:**

1. **Check Token Approval:**
   ```javascript
   const ensureApproval = async (token, vault, amount) => {
     const allowance = await token.allowance(userAddress, vault.address);
     
     if (allowance < amount) {
       const approveTx = await token.approve(vault.address, amount);
       await approveTx.wait();
     }
   };
   ```

2. **Validate Token Support:**
   ```javascript
   const validateToken = async (vault, tokenAddress) => {
     const supported = await vault.isTokenSupported(tokenAddress);
     if (!supported) {
       throw new Error(`Token ${tokenAddress} is not supported`);
     }
   };
   ```

3. **Check Token Balance:**
   ```javascript
   const checkTokenBalance = async (token, userAddress, amount) => {
     const balance = await token.balanceOf(userAddress);
     if (balance < amount) {
       throw new Error(`Insufficient token balance. Required: ${amount}, Available: ${balance}`);
     }
   };
   ```

#### Price Feed Issues

**Problem:** Oracle price feeds return stale or invalid data.

**Symptoms:**
- "StalePrice" error
- Incorrect credit calculations
- Price feed reverts

**Solutions:**

1. **Check Price Staleness:**
   ```javascript
   const checkPriceFreshness = async (priceFeed) => {
     const [, price, , updatedAt] = await priceFeed.latestRoundData();
     const now = Math.floor(Date.now() / 1000);
     const staleness = now - Number(updatedAt);
     
     if (staleness > 3600) { // 1 hour
       throw new Error(`Price data is stale: ${staleness} seconds old`);
     }
     
     return price;
   };
   ```

2. **Fallback Price Sources:**
   ```javascript
   const getPriceWithFallback = async (primaryFeed, fallbackFeed) => {
     try {
       return await checkPriceFreshness(primaryFeed);
     } catch (error) {
       console.warn('Primary price feed failed, using fallback');
       return await checkPriceFreshness(fallbackFeed);
     }
   };
   ```

### Relayer Issues

#### Relayer Connection Failures

**Problem:** Cannot connect to relayer service.

**Symptoms:**
- Network timeout errors
- Connection refused
- HTTP 500/503 errors

**Solutions:**

1. **Implement Retry Logic:**
   ```javascript
   const submitWithRetry = async (data, maxRetries = 3) => {
     for (let i = 0; i < maxRetries; i++) {
       try {
         return await relayerService.submit(data);
       } catch (error) {
         if (i === maxRetries - 1) throw error;
         
         const delay = Math.pow(2, i) * 1000; // Exponential backoff
         await new Promise(resolve => setTimeout(resolve, delay));
       }
     }
   };
   ```

2. **Health Check:**
   ```javascript
   const checkRelayerHealth = async () => {
     try {
       const response = await fetch(`${relayerUrl}/health`);
       return response.ok;
     } catch (error) {
       return false;
     }
   };
   ```

3. **Multiple Relayers:**
   ```javascript
   const relayers = [
     'https://relayer1.example.com',
     'https://relayer2.example.com',
     'https://relayer3.example.com'
   ];
   
   const submitToAnyRelayer = async (data) => {
     for (const relayerUrl of relayers) {
       try {
         const relayer = new RelayerService(relayerUrl);
         return await relayer.submit(data);
       } catch (error) {
         console.warn(`Relayer ${relayerUrl} failed:`, error.message);
       }
     }
     throw new Error('All relayers failed');
   };
   ```

#### Rate Limiting

**Problem:** Requests rejected due to rate limits.

**Symptoms:**
- HTTP 429 errors
- "Too many requests" messages
- Temporary rejections

**Solutions:**

1. **Rate Limit Handling:**
   ```javascript
   const handleRateLimit = async (request) => {
     try {
       return await request();
     } catch (error) {
       if (error.status === 429) {
         const retryAfter = error.headers?.['retry-after'] || 60;
         console.log(`Rate limited, waiting ${retryAfter} seconds`);
         await new Promise(resolve => setTimeout(resolve, retryAfter * 1000));
         return await request();
       }
       throw error;
     }
   };
   ```

2. **Request Queue:**
   ```javascript
   class RequestQueue {
     constructor(maxConcurrent = 5, delayMs = 1000) {
       this.queue = [];
       this.running = 0;
       this.maxConcurrent = maxConcurrent;
       this.delayMs = delayMs;
     }
   
     async add(request) {
       return new Promise((resolve, reject) => {
         this.queue.push({ request, resolve, reject });
         this.process();
       });
     }
   
     async process() {
       if (this.running >= this.maxConcurrent || this.queue.length === 0) {
         return;
       }
   
       this.running++;
       const { request, resolve, reject } = this.queue.shift();
   
       try {
         const result = await request();
         resolve(result);
       } catch (error) {
         reject(error);
       } finally {
         this.running--;
         setTimeout(() => this.process(), this.delayMs);
       }
     }
   }
   ```

## Development Issues

### Contract Compilation

#### Solidity Version Conflicts

**Problem:** Contracts fail to compile due to version mismatches.

**Symptoms:**
- Compilation errors
- Missing features
- Incompatible syntax

**Solutions:**

1. **Lock Solidity Version:**
   ```javascript
   // hardhat.config.js
   module.exports = {
     solidity: {
       version: "0.8.20",
       settings: {
         optimizer: {
           enabled: true,
           runs: 200
         },
         viaIR: true
       }
     }
   };
   ```

2. **Check OpenZeppelin Compatibility:**
   ```bash
   npm install @openzeppelin/contracts@5.3.0
   npm install @openzeppelin/contracts-upgradeable@5.3.0
   ```

#### Missing Dependencies

**Problem:** Compilation fails due to missing imports.

**Solutions:**

1. **Install Required Packages:**
   ```bash
   npm install @openzeppelin/contracts
   npm install @chainlink/contracts
   npm install hardhat
   ```

2. **Check Import Paths:**
   ```solidity
   // Correct import paths
   import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
   import "@openzeppelin/contracts/access/Ownable.sol";
   ```

### Testing Issues

#### Test Environment Setup

**Problem:** Tests fail due to environment configuration.

**Solutions:**

1. **Proper Test Setup:**
   ```javascript
   const { ethers } = require("hardhat");
   const { expect } = require("chai");
   
   describe("MetaTxGateway", function () {
     let gateway, vault, owner, user;
   
     beforeEach(async function () {
       [owner, user] = await ethers.getSigners();
       
       // Deploy contracts
       const Gateway = await ethers.getContractFactory("MetaTxGateway");
       gateway = await upgrades.deployProxy(Gateway, [owner.address]);
       
       const Vault = await ethers.getContractFactory("GasCreditVault");
       vault = await upgrades.deployProxy(Vault, [owner.address]);
     });
   });
   ```

2. **Mock External Dependencies:**
   ```javascript
   // Mock Chainlink price feed
   const MockAggregator = await ethers.getContractFactory("MockAggregatorV3");
   const mockFeed = await MockAggregator.deploy(8, 100000000); // $1.00
   ```

## Performance Issues

### Slow Transaction Processing

**Problem:** Meta-transactions take too long to process.

**Common Causes & Solutions:**

1. **Network Congestion:**
   ```javascript
   // Increase gas price during congestion
   const getOptimalGasPrice = async () => {
     const gasPrice = await provider.getGasPrice();
     return gasPrice * 110n / 100n; // 10% above current
   };
   ```

2. **Large Transaction Data:**
   ```javascript
   // Optimize transaction data
   const optimizeCalldata = (functionCall) => {
     // Use function selectors instead of full signatures
     // Minimize parameter sizes
     // Use packed encoding where possible
   };
   ```

3. **Batch Size Optimization:**
   ```javascript
   // Optimal batch size for performance
   const OPTIMAL_BATCH_SIZE = 5;
   
   const processBatches = async (transactions) => {
     const batches = [];
     for (let i = 0; i < transactions.length; i += OPTIMAL_BATCH_SIZE) {
       batches.push(transactions.slice(i, i + OPTIMAL_BATCH_SIZE));
     }
     
     for (const batch of batches) {
       await gateway.executeMetaTransactions(batch);
     }
   };
   ```

### High Gas Costs

**Problem:** Gas costs are higher than expected.

**Optimization Strategies:**

1. **Contract Optimization:**
   ```solidity
   // Use packed structs
   struct PackedTransaction {
     address to;          // 20 bytes
     uint96 value;        // 12 bytes (enough for most values)
     uint32 nonce;        // 4 bytes (sufficient for nonce)
     uint32 deadline;     // 4 bytes (timestamp)
     // Total: 32 bytes (1 storage slot)
   }
   ```

2. **Batch Processing:**
   ```javascript
   // Process multiple transactions in one call
   const batchTransactions = async (transactions) => {
     // Combine multiple operations
     return await gateway.executeMetaTransactions(transactions);
   };
   ```

3. **Gas Token Integration:**
   ```solidity
   // Use CHI or GST2 tokens for gas optimization
   contract GasOptimizedGateway {
     function executeWithGasToken(
       MetaTransaction[] calldata transactions,
       uint256 gasTokenAmount
     ) external {
       // Burn gas tokens to reduce costs
       gasToken.burn(gasTokenAmount);
       // Execute transactions
     }
   }
   ```

## Monitoring and Debugging

### Transaction Tracking

```javascript
// Comprehensive transaction monitoring
class TransactionMonitor {
  constructor(provider) {
    this.provider = provider;
    this.pendingTx = new Map();
  }

  async trackTransaction(txHash, context) {
    this.pendingTx.set(txHash, {
      hash: txHash,
      context: context,
      startTime: Date.now(),
      status: 'pending'
    });

    try {
      const receipt = await this.provider.waitForTransaction(txHash);
      this.handleTransactionComplete(txHash, receipt);
      return receipt;
    } catch (error) {
      this.handleTransactionError(txHash, error);
      throw error;
    }
  }

  handleTransactionComplete(txHash, receipt) {
    const tx = this.pendingTx.get(txHash);
    if (tx) {
      tx.status = receipt.status === 1 ? 'success' : 'failed';
      tx.endTime = Date.now();
      tx.gasUsed = receipt.gasUsed;
      console.log('Transaction completed:', tx);
      this.pendingTx.delete(txHash);
    }
  }

  handleTransactionError(txHash, error) {
    const tx = this.pendingTx.get(txHash);
    if (tx) {
      tx.status = 'error';
      tx.error = error.message;
      tx.endTime = Date.now();
      console.error('Transaction failed:', tx);
      this.pendingTx.delete(txHash);
    }
  }
}
```

### Error Logging

```javascript
// Structured error logging
class ErrorLogger {
  static log(error, context = {}) {
    const errorInfo = {
      timestamp: new Date().toISOString(),
      message: error.message,
      stack: error.stack,
      context: context,
      userAgent: navigator.userAgent,
      url: window.location.href
    };

    // Log to console
    console.error('Error occurred:', errorInfo);

    // Send to monitoring service
    this.sendToMonitoring(errorInfo);
  }

  static sendToMonitoring(errorInfo) {
    // Send to error monitoring service (e.g., Sentry)
    if (window.Sentry) {
      window.Sentry.captureException(new Error(errorInfo.message), {
        contexts: { error: errorInfo }
      });
    }
  }
}
```

## Getting Help

### Before Asking for Help

1. **Check This Troubleshooting Guide**
2. **Review Error Messages Carefully**
3. **Check Network Status**
4. **Verify Contract Addresses**
5. **Test on Testnet First**

### Where to Get Help

1. **GitHub Issues**: [MetaTx-Contracts Issues](https://github.com/DINetworks/MetaTx-Contracts/issues)
2. **Discord Community**: Join our Discord server
3. **Stack Overflow**: Tag questions with `metatx-contracts`
4. **Documentation**: Browse this GitBook thoroughly
5. **Email Support**: support@metatx-contracts.com

### When Reporting Issues

Include the following information:

1. **Environment Details:**
   - Operating system
   - Browser version
   - MetaMask version
   - Network (mainnet/testnet)

2. **Error Information:**
   - Complete error message
   - Transaction hash (if available)
   - Code snippet causing the issue
   - Steps to reproduce

3. **Context:**
   - What you were trying to accomplish
   - Expected vs actual behavior
   - Any workarounds attempted

### Sample Issue Report

```markdown
**Environment:**
- OS: Windows 11
- Browser: Chrome 119.0.6045.159
- MetaMask: 11.5.0
- Network: BSC Mainnet (Chain ID: 56)

**Error:**
InvalidSignature() error when executing meta-transaction

**Code:**
```javascript
const signature = await signer.signTypedData(domain, types, message);
await gateway.executeMetaTransactions([{...transaction, signature}]);
```

**Expected:** Transaction should execute successfully
**Actual:** Contract reverts with InvalidSignature()

**Additional Info:**
- Domain separator verified against contract
- Signature verification works in tests
- Issue started after upgrading to v2.0.0
```

{% hint style="success" %}
**Need More Help?** If you can't find a solution here, don't hesitate to reach out to our community or support team. We're here to help! 🚀
{% endhint %}
