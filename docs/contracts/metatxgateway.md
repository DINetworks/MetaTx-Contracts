# MetaTxGateway

The MetaTxGateway is the core contract responsible for executing gasless meta-transactions with built-in native token support and automatic refund mechanisms.

## Overview

MetaTxGateway v2.0.0 represents a significant enhancement over traditional meta-transaction systems by introducing native token validation and automatic refund functionality, ensuring financial safety for both users and relayers.

## Key Features

### 🔒 Native Token Validation
Ensures exact native token amounts are provided for meta-transactions that require ETH/BNB transfers.

### 🔄 Automatic Refunds
Returns unused native tokens to relayers when transactions fail, preventing fund loss.

### 📦 Batch Processing
Execute multiple transactions in a single call, reducing gas costs and improving efficiency.

### 🖋️ EIP-712 Signatures
Cryptographically secure meta-transaction authorization with structured data signing.

### 🔧 UUPS Upgradeable
Safe upgrade patterns for future enhancements without disrupting existing functionality.

## Contract Interface

### Core Functions

#### executeMetaTransactions

```solidity
function executeMetaTransactions(
    address from,
    bytes calldata metaTxData,
    bytes calldata signature,
    uint256 nonce,
    uint256 deadline
) external payable nonReentrant returns (bool[] memory successes)
```

**Purpose**: Execute a batch of meta-transactions on behalf of a user.

**Parameters**:
- `from`: The user's address (signature signer)
- `metaTxData`: Encoded array of MetaTransaction structs
- `signature`: EIP-712 signature from the user
- `nonce`: User's current nonce for replay protection
- `deadline`: Transaction expiration timestamp

**Returns**: Array of boolean values indicating success/failure for each transaction

**Key Validations**:
- Relayer authorization check
- Signature verification using EIP-712
- Nonce validation for replay protection
- Native token amount validation
- Deadline enforcement

#### calculateRequiredValue

```solidity
function calculateRequiredValue(bytes calldata metaTxData) 
    external pure returns (uint256 totalValue)
```

**Purpose**: Calculate the total native token value required for a batch of meta-transactions.

**Use Case**: Frontend applications can use this to determine how much ETH/BNB to include with the relayer transaction.

### Administrative Functions

#### setRelayerAuthorization

```solidity
function setRelayerAuthorization(address relayer, bool authorized) 
    external onlyOwner
```

**Purpose**: Authorize or deauthorize a relayer address.

**Access Control**: Only contract owner can modify relayer permissions.

### View Functions

#### getVersion

```solidity
function getVersion() external pure returns (string memory version)
```

**Returns**: "v2.0.0-native-token-support"

#### getNonce

```solidity
function getNonce(address user) external view returns (uint256 currentNonce)
```

**Purpose**: Get the current nonce for a user address.

#### getDomainSeparator

```solidity
function getDomainSeparator() external view returns (bytes32 separator)
```

**Purpose**: Get the EIP-712 domain separator for signature verification.

**Note**: Uses version "2" to distinguish from earlier implementations.

## Data Structures

### MetaTransaction

```solidity
struct MetaTransaction {
    address to;        // Target contract address
    uint256 value;     // Native token amount (ETH/BNB)
    bytes data;        // Function call data
}
```

### BatchTransactionLog

```solidity
struct BatchTransactionLog {
    address user;           // User who signed the meta-transactions
    address relayer;        // Relayer who executed the batch
    bytes metaTxData;       // Original meta-transaction data
    uint256 gasUsed;        // Total gas consumed
    uint256 timestamp;      // Block timestamp
    bool[] successes;       // Success status for each transaction
}
```

## Events

### MetaTransactionExecuted

```solidity
event MetaTransactionExecuted(
    address indexed user,
    address indexed relayer,
    address indexed target,
    bool success
);
```

**Emitted**: For each individual meta-transaction execution.

### BatchTransactionExecuted

```solidity
event BatchTransactionExecuted(
    uint256 indexed batchId,
    address indexed user,
    address indexed relayer,
    uint256 gasUsed,
    uint256 transactionCount
);
```

**Emitted**: When a batch of meta-transactions is completed.

### NativeTokenUsed

```solidity
event NativeTokenUsed(
    uint256 indexed batchId,
    uint256 totalRequired,
    uint256 totalUsed,
    uint256 refunded
);
```

**Emitted**: When native tokens are used in meta-transactions, showing usage and refund details.

### RelayerAuthorized

```solidity
event RelayerAuthorized(
    address indexed relayer,
    bool authorized
);
```

**Emitted**: When relayer authorization status changes.

## EIP-712 Implementation

### Domain Separator

```solidity
EIP712Domain(
    string name,      // "MetaTxGateway"
    string version,   // "2"
    uint256 chainId,  // Network chain ID
    address verifyingContract // Contract address
)
```

### MetaTransaction Type

```solidity
MetaTransaction(
    address from,
    bytes metaTxData,
    uint256 nonce,
    uint256 deadline
)
```

### Signature Generation (Frontend)

```javascript
const domain = {
    name: 'MetaTxGateway',
    version: '2',
    chainId: await web3.eth.getChainId(),
    verifyingContract: contractAddress
};

const types = {
    MetaTransaction: [
        { name: 'from', type: 'address' },
        { name: 'metaTxData', type: 'bytes' },
        { name: 'nonce', type: 'uint256' },
        { name: 'deadline', type: 'uint256' }
    ]
};

const value = {
    from: userAddress,
    metaTxData: encodedMetaTxs,
    nonce: await contract.getNonce(userAddress),
    deadline: Math.floor(Date.now() / 1000) + 3600 // 1 hour
};

const signature = await signer._signTypedData(domain, types, value);
```

## Security Considerations

### Input Validation
- All addresses are validated for zero address
- Array lengths are checked for reasonable limits
- Signature recovery is performed safely

### Reentrancy Protection
- Uses OpenZeppelin's ReentrancyGuard
- External calls use try-catch for safe failure handling
- State changes occur before external calls

### Access Control
- Owner-only functions for critical operations
- Relayer authorization system
- Function-level access controls

### Financial Safety
- Exact value validation prevents over/under-funding
- Automatic refunds protect relayers from loss
- Failed transactions don't consume user funds

## Gas Optimization

### Batch Processing Benefits
- **Single Transaction**: ~150,000 gas
- **5 Transactions (Batch)**: ~400,000 gas (80,000 per tx)
- **Gas Savings**: 30-40% reduction per transaction in batches

### Optimization Techniques
- Efficient storage layout
- Minimal external calls
- Event-driven architecture
- Optimized loops and conditionals

## Integration Examples

### Basic Meta-Transaction

```javascript
// Prepare meta-transaction
const metaTx = {
    to: tokenContract.address,
    value: 0, // No ETH for ERC20 transfer
    data: tokenContract.interface.encodeFunctionData('transfer', [recipient, amount])
};

const metaTxData = ethers.utils.defaultAbiCoder.encode(
    ['tuple(address to, uint256 value, bytes data)[]'],
    [[metaTx]]
);

// Calculate required value
const requiredValue = await gateway.calculateRequiredValue(metaTxData);

// Execute meta-transaction
const tx = await gateway.executeMetaTransactions(
    userAddress,
    metaTxData,
    signature,
    nonce,
    deadline,
    { value: requiredValue }
);
```

### Native Token Meta-Transaction

```javascript
// Meta-transaction that sends ETH
const metaTx = {
    to: recipientAddress,
    value: ethers.utils.parseEther('0.1'), // Send 0.1 ETH
    data: '0x' // Empty data for simple transfer
};

const metaTxData = ethers.utils.defaultAbiCoder.encode(
    ['tuple(address to, uint256 value, bytes data)[]'],
    [[metaTx]]
);

// Must include 0.1 ETH with the relayer transaction
const requiredValue = await gateway.calculateRequiredValue(metaTxData);
// requiredValue = 0.1 ETH

const tx = await gateway.executeMetaTransactions(
    userAddress,
    metaTxData,
    signature,
    nonce,
    deadline,
    { value: requiredValue } // Relayer provides 0.1 ETH
);
```

## Next Steps

- **[Native Token Handling](metatxgateway/native-token-handling.md)** - Deep dive into value validation
- **[Batch Processing](metatxgateway/batch-processing.md)** - Optimize with batches
- **[EIP-712 Signatures](metatxgateway/eip-712-signatures.md)** - Signature implementation
- **[API Reference](../api/metatxgateway-api.md)** - Complete function reference
