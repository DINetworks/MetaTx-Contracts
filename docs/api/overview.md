# API Reference

Complete API reference for MetaTx-Contracts system.

## MetaTxGateway Contract

### Write Functions

#### executeMetaTransactions

```solidity
function executeMetaTransactions(
    MetaTransaction[] calldata transactions
) external payable
```

Executes a batch of meta-transactions.

**Parameters:**
- `transactions`: Array of meta-transaction structures

**MetaTransaction Structure:**
```solidity
struct MetaTransaction {
    address to;        // Target contract address
    uint256 value;     // ETH value to send
    bytes data;        // Transaction data
    uint256 nonce;     // User's nonce
    uint256 deadline;  // Expiration timestamp
    bytes signature;   // EIP-712 signature
}
```

**Events Emitted:**
- `MetaTransactionExecuted(address indexed user, address indexed to, bool success, bytes returnData)`
- `NativeTokenUsed(address indexed user, uint256 amount)` (if ETH sent)

**Errors:**
- `InvalidSignature()`: Signature verification failed
- `ExpiredDeadline()`: Transaction deadline exceeded
- `InvalidNonce()`: Nonce mismatch
- `ExecutionFailed()`: Target transaction failed

**Example:**
```javascript
const tx = await gateway.executeMetaTransactions([
  {
    to: "0x...",
    value: ethers.parseEther("0.1"),
    data: "0x",
    nonce: 1,
    deadline: Math.floor(Date.now() / 1000) + 300,
    signature: "0x..."
  }
], { value: ethers.parseEther("0.1") });
```

#### upgrade

```solidity
function upgrade(address newImplementation) external
```

Upgrades the contract implementation (UUPS pattern).

**Parameters:**
- `newImplementation`: Address of new implementation contract

**Access Control:** Owner only

**Example:**
```javascript
await gateway.upgrade(newImplementationAddress);
```

### Read Functions

#### getNonce

```solidity
function getNonce(address user) external view returns (uint256)
```

Returns the current nonce for a user.

**Parameters:**
- `user`: User address

**Returns:** Current nonce value

**Example:**
```javascript
const nonce = await gateway.getNonce(userAddress);
```

#### name

```solidity
function name() external pure returns (string memory)
```

Returns the contract name for EIP-712 domain.

**Returns:** "MetaTxGateway"

#### version

```solidity
function version() external pure returns (string memory)
```

Returns the contract version for EIP-712 domain.

**Returns:** "2.0.0"

#### domainSeparator

```solidity
function domainSeparator() external view returns (bytes32)
```

Returns the EIP-712 domain separator.

**Returns:** Domain separator hash

#### UPGRADE_INTERFACE_VERSION

```solidity
function UPGRADE_INTERFACE_VERSION() external pure returns (string memory)
```

Returns the UUPS upgrade interface version.

**Returns:** "5.0.0"

### Events

#### MetaTransactionExecuted

```solidity
event MetaTransactionExecuted(
    address indexed user,
    address indexed to,
    bool success,
    bytes returnData
)
```

Emitted for each executed meta-transaction.

**Parameters:**
- `user`: Transaction signer
- `to`: Target address
- `success`: Execution result
- `returnData`: Return data from target call

#### NativeTokenUsed

```solidity
event NativeTokenUsed(
    address indexed user,
    uint256 amount
)
```

Emitted when native tokens (ETH/BNB) are used.

**Parameters:**
- `user`: Token sender
- `amount`: Amount of native tokens

#### Upgraded

```solidity
event Upgraded(address indexed implementation)
```

Emitted when contract is upgraded.

**Parameters:**
- `implementation`: New implementation address

## GasCreditVault Contract

### Write Functions

#### depositCredits

```solidity
function depositCredits(
    address token,
    uint256 amount
) external
```

Deposits tokens and mints gas credits.

**Parameters:**
- `token`: ERC-20 token address
- `amount`: Token amount to deposit

**Events Emitted:**
- `CreditsDeposited(address indexed user, address indexed token, uint256 tokenAmount, uint256 credits)`

**Errors:**
- `UnsupportedToken(address token)`: Token not supported
- `InvalidAmount(uint256 amount)`: Amount is zero
- `TransferFailed(address token, address from, uint256 amount)`: Token transfer failed

**Example:**
```javascript
// Approve token first
await token.approve(vaultAddress, amount);

// Deposit credits
await vault.depositCredits(tokenAddress, amount);
```

#### useCredits

```solidity
function useCredits(
    address user,
    uint256 gasUsed,
    uint256 gasPrice
) external returns (bool)
```

Burns credits to pay for gas fees.

**Parameters:**
- `user`: User whose credits to burn
- `gasUsed`: Gas amount consumed
- `gasPrice`: Gas price in wei

**Returns:** Success status

**Access Control:** Authorized contracts only

**Events Emitted:**
- `CreditsUsed(address indexed user, uint256 gasUsed, uint256 gasPrice, uint256 totalCost)`

**Errors:**
- `InsufficientCredits(uint256 required, uint256 available)`: Not enough credits
- `Unauthorized(address caller)`: Caller not authorized

#### transferCredits

```solidity
function transferCredits(
    address to,
    uint256 amount
) external
```

Transfers credits between accounts.

**Parameters:**
- `to`: Recipient address
- `amount`: Credit amount to transfer

**Events Emitted:**
- `CreditsTransferred(address indexed from, address indexed to, uint256 amount)`

**Errors:**
- `InsufficientCredits(uint256 required, uint256 available)`: Not enough credits
- `InvalidAmount(uint256 amount)`: Amount is zero

**Example:**
```javascript
await vault.transferCredits(recipientAddress, ethers.parseEther("10"));
```

#### addToken

```solidity
function addToken(
    address token,
    address priceFeed
) external
```

Adds a new supported token.

**Parameters:**
- `token`: ERC-20 token address
- `priceFeed`: Chainlink price feed address

**Access Control:** Owner only

**Events Emitted:**
- `TokenAdded(address indexed token, address indexed priceFeed)`

#### removeToken

```solidity
function removeToken(address token) external
```

Removes a supported token.

**Parameters:**
- `token`: Token address to remove

**Access Control:** Owner only

**Events Emitted:**
- `TokenRemoved(address indexed token)`

### Read Functions

#### getCreditBalance

```solidity
function getCreditBalance(address user) external view returns (uint256)
```

Returns user's credit balance.

**Parameters:**
- `user`: User address

**Returns:** Credit balance in wei units

#### getTokenPrice

```solidity
function getTokenPrice(address token) external view returns (uint256)
```

Returns current token price from oracle.

**Parameters:**
- `token`: Token address

**Returns:** Price in USD with 8 decimals

**Errors:**
- `UnsupportedToken(address token)`: Token not supported
- `StalePrice(uint256 updatedAt, uint256 staleness)`: Price data stale

#### calculateCredits

```solidity
function calculateCredits(
    address token,
    uint256 tokenAmount
) external view returns (uint256)
```

Calculates credits for token amount.

**Parameters:**
- `token`: Token address
- `tokenAmount`: Token amount

**Returns:** Equivalent credits

#### isTokenSupported

```solidity
function isTokenSupported(address token) external view returns (bool)
```

Checks if token is supported.

**Parameters:**
- `token`: Token address

**Returns:** Support status

#### getSupportedTokens

```solidity
function getSupportedTokens() external view returns (address[] memory)
```

Returns array of supported token addresses.

**Returns:** Token addresses array

### Events

#### CreditsDeposited

```solidity
event CreditsDeposited(
    address indexed user,
    address indexed token,
    uint256 tokenAmount,
    uint256 credits
)
```

#### CreditsUsed

```solidity
event CreditsUsed(
    address indexed user,
    uint256 gasUsed,
    uint256 gasPrice,
    uint256 totalCost
)
```

#### CreditsTransferred

```solidity
event CreditsTransferred(
    address indexed from,
    address indexed to,
    uint256 amount
)
```

#### TokenAdded

```solidity
event TokenAdded(
    address indexed token,
    address indexed priceFeed
)
```

#### TokenRemoved

```solidity
event TokenRemoved(address indexed token)
```

## EIP-712 Signatures

### Domain Separator

```javascript
const domain = {
  name: "MetaTxGateway",
  version: "2.0.0",
  chainId: 56, // BSC mainnet
  verifyingContract: "0x..." // MetaTxGateway address
};
```

### Types Definition

```javascript
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

### Signing Process

```javascript
// Prepare message
const message = {
  to: "0x...",
  value: "1000000000000000000", // 1 ETH in wei
  data: "0x",
  nonce: "1",
  deadline: "1640995200" // Unix timestamp
};

// Sign with ethers.js
const signature = await signer.signTypedData(domain, types, message);

// Verify signature
const recoveredAddress = ethers.verifyTypedData(domain, types, message, signature);
```

## Relayer API Endpoints

### POST /meta-transactions

Submits meta-transactions for execution.

**Request Body:**
```json
{
  "userAddress": "0x...",
  "transactions": [
    {
      "to": "0x...",
      "value": "1000000000000000000",
      "data": "0x",
      "nonce": "1",
      "deadline": "1640995200",
      "signature": "0x..."
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "txHash": "0x...",
  "gasUsed": "50000"
}
```

### POST /meta-transactions/estimate

Estimates gas for meta-transactions.

**Request Body:** Same as execution endpoint

**Response:**
```json
{
  "success": true,
  "estimatedGas": "50000",
  "gasPrice": "5000000000"
}
```

### GET /transactions/:hash

Gets transaction status.

**Response:**
```json
{
  "hash": "0x...",
  "status": "confirmed",
  "blockNumber": 12345678,
  "gasUsed": "50000",
  "logs": [...]
}
```

### GET /health

Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "uptime": 3600
}
```

## Error Codes

### Contract Errors

| Error | Code | Description |
|-------|------|-------------|
| `InvalidSignature()` | 4001 | EIP-712 signature verification failed |
| `ExpiredDeadline()` | 4002 | Transaction deadline exceeded |
| `InvalidNonce()` | 4003 | Nonce doesn't match expected value |
| `ExecutionFailed()` | 4004 | Target transaction execution failed |
| `InsufficientCredits()` | 4005 | Not enough gas credits |
| `UnsupportedToken()` | 4006 | Token not supported for credits |
| `Unauthorized()` | 4007 | Caller not authorized |

### Relayer Errors

| Error | Code | Description |
|-------|------|-------------|
| Invalid Request | 400 | Malformed request body |
| Unauthorized | 401 | Invalid API key |
| Rate Limited | 429 | Too many requests |
| Internal Error | 500 | Server error |
| Service Unavailable | 503 | Relayer temporarily down |

## Rate Limits

### Relayer API

- **Requests per minute**: 60
- **Transactions per hour**: 100
- **Gas limit per transaction**: 500,000

### Contract Limits

- **Max transactions per batch**: 10
- **Max deadline**: 1 hour
- **Min deadline**: 1 minute

## Gas Estimates

### Typical Gas Usage

| Operation | Gas Cost |
|-----------|----------|
| Simple transfer | ~25,000 |
| ERC-20 transfer | ~45,000 |
| Meta-transaction execution | ~80,000 |
| Credit deposit | ~65,000 |
| Credit transfer | ~35,000 |

### Gas Optimization

1. **Batch Transactions**: Combine multiple operations
2. **Minimize Data**: Use minimal transaction data
3. **Optimize Signatures**: Use efficient signature schemes
4. **Cache Verification**: Reuse verification where possible

## SDK Integration

### JavaScript/TypeScript

```bash
npm install @metatx-contracts/sdk
```

```javascript
import { MetaTxSDK } from '@metatx-contracts/sdk';

const sdk = new MetaTxSDK({
  provider: ethers.provider,
  signer: ethers.signer,
  chainId: 56,
  relayerUrl: 'https://relayer.example.com'
});

// Execute meta-transaction
const txHash = await sdk.executeMetaTransaction({
  to: '0x...',
  value: ethers.parseEther('0.1'),
  data: '0x'
});
```

### Python

```bash
pip install metatx-contracts-sdk
```

```python
from metatx_contracts import MetaTxSDK

sdk = MetaTxSDK(
    provider_url='https://bsc-dataseed1.binance.org/',
    private_key='0x...',
    chain_id=56,
    relayer_url='https://relayer.example.com'
)

# Execute meta-transaction
tx_hash = sdk.execute_meta_transaction({
    'to': '0x...',
    'value': 100000000000000000,  # 0.1 ETH
    'data': '0x'
})
```

## Testing Utilities

### Mock Contracts

```solidity
// MockERC20.sol
contract MockERC20 {
    mapping(address => uint256) public balances;
    
    function mint(address to, uint256 amount) external {
        balances[to] += amount;
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        balances[msg.sender] -= amount;
        balances[to] += amount;
        return true;
    }
}
```

### Test Helpers

```javascript
// Test helper functions
const helpers = {
  async signMetaTransaction(signer, domain, transaction) {
    return await signer.signTypedData(domain, types, transaction);
  },
  
  async getNextNonce(gateway, user) {
    return await gateway.getNonce(user.address);
  },
  
  async deployTestContracts() {
    // Deploy contracts for testing
  }
};
```

## Migration Guide

### From v1.0.0 to v2.0.0

**Breaking Changes:**
1. Updated domain separator version
2. Added native token support
3. Enhanced error handling

**Migration Steps:**
```javascript
// Update domain version
const domain = {
  name: "MetaTxGateway",
  version: "2.0.0", // Changed from "1.0.0"
  chainId: 56,
  verifyingContract: newContractAddress
};

// Handle native token transactions
if (hasNativeTokenValue) {
  await gateway.executeMetaTransactions(transactions, {
    value: totalNativeValue
  });
}
```

## Best Practices

### Security

1. **Validate Signatures**: Always verify EIP-712 signatures
2. **Check Deadlines**: Ensure reasonable transaction timeframes
3. **Rate Limiting**: Implement request rate limits
4. **Gas Limits**: Set appropriate gas limits
5. **Error Handling**: Graceful error handling and recovery

### Performance

1. **Batch Operations**: Combine multiple transactions
2. **Cache Data**: Cache frequently accessed data
3. **Optimize Gas**: Minimize gas consumption
4. **Connection Pooling**: Reuse network connections
5. **Async Processing**: Use asynchronous operations

### Monitoring

1. **Transaction Tracking**: Monitor transaction status
2. **Error Logging**: Log errors and failures
3. **Performance Metrics**: Track response times
4. **Resource Usage**: Monitor gas and credit usage
5. **Health Checks**: Regular system health monitoring

{% hint style="info" %}
**API Documentation**: This reference covers all public functions and interfaces. For internal implementation details, refer to the contract source code.
{% endhint %}

## Support

- **Documentation**: Browse this GitBook
- **GitHub Issues**: Report bugs and request features
- **Community**: Join our Discord/Telegram
- **Email**: support@metatx-contracts.com
