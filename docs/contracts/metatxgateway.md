# MetaTxGateway

The MetaTxGateway is the core contract responsible for executing gasless meta-transactions with built-in native token support and automatic refund mechanisms.

**This protocol also includes the DI Token, Token Presale, and Token Staking contracts, providing a complete tokenomics suite.**

## Overview

MetaTxGateway v1.0.0-native-token-support enables secure, gasless meta-transactions with native token (ETH/BNB) support, batch execution, and relayer authorization.

## Key Features

### 🔒 Native Token Validation
Ensures exact native token amounts are provided for meta-transactions that require ETH/BNB transfers.

### 🔄 Automatic Refunds
Returns unused native tokens to users when transactions fail, preventing fund loss.

### 📦 Batch Processing
Execute multiple transactions in a single call, reducing gas costs and improving efficiency.

### 🖋️ EIP-712 Signatures
Cryptographically secure meta-transaction authorization with structured data signing.

### 🔧 UUPS Upgradeable
Safe upgrade patterns for future enhancements without disrupting existing functionality.

### ⏸️ Pausable
Owner can pause/unpause contract with a reason.

## Contract Interface

### Core Functions

#### executeMetaTransactions

```solidity
function executeMetaTransactions(
    address from,
    MetaTransaction[] calldata metaTxs,
    bytes calldata signature,
    uint256 nonce,
    uint256 deadline
) external payable nonReentrant whenNotPaused returns (bool[] memory successes)
```

**Purpose**: Execute a batch of meta-transactions on behalf of a user.

**Parameters**:
- `from`: The user's address (signature signer)
- `metaTxs`: Array of MetaTransaction structs
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
function calculateRequiredValue(MetaTransaction[] calldata metaTxs) 
    external pure returns (uint256 totalValue)
```

**Purpose**: Calculate the total native token value required for a batch of meta-transactions.

**Use Case**: Frontend applications can use this to determine how much ETH/BNB to include with the relayer transaction.

#### setRelayerAuthorization

```solidity
function setRelayerAuthorization(address relayer, bool authorized) 
    external onlyOwner
```

**Purpose**: Authorize or deauthorize a relayer address.

#### pauseWithReason

```solidity
function pauseWithReason(string calldata reason) external onlyOwner
```

**Purpose**: Pause the contract with a reason.

#### unpause

```solidity
function unpause() external onlyOwner
```

**Purpose**: Unpause the contract.

### View Functions

#### getNonce

```solidity
function getNonce(address user) external view returns (uint256 currentNonce)
```

**Purpose**: Get the current nonce for a user address.

#### isRelayerAuthorized

```solidity
function isRelayerAuthorized(address relayer) external view returns (bool isAuthorized)
```

**Purpose**: Check if a relayer is authorized.

#### getDomainSeparator

```solidity
function getDomainSeparator() external view returns (bytes32 separator)
```

**Purpose**: Get the EIP-712 domain separator for signature verification.

#### getMetaTransactionTypehash

```solidity
function getMetaTransactionTypehash() external pure returns (bytes32 typehash)
```

**Purpose**: Get the MetaTransaction struct typehash for EIP-712.

#### getMainTypehash

```solidity
function getMainTypehash() external pure returns (bytes32 typehash)
```

**Purpose**: Get the main typehash for batch meta-transactions.

#### getSigningDigest

```solidity
function getSigningDigest(
    address from,
    MetaTransaction[] calldata metaTxs,
    uint256 nonce,
    uint256 deadline
) external view returns (bytes32 digest)
```

**Purpose**: Helper for frontend to generate the EIP-712 digest for signing.

#### getTotalBatchCount

```solidity
function getTotalBatchCount() external view returns (uint256 count)
```

**Purpose**: Get the total number of batch transactions processed.

#### getVersion

```solidity
function getVersion() external pure returns (string memory version)
```

**Returns**: "v1.0.0-native-token-support"

## Data Structures

### MetaTransaction

```solidity
struct MetaTransaction {
    address to;        // Target contract address
    uint256 value;     // Native token amount (ETH/BNB)
    bytes data;        // Function call data
}
```

## Events

### RelayerAuthorized

```solidity
event RelayerAuthorized(address indexed relayer, bool authorized);
```

**Emitted**: When relayer authorization status changes.

### MetaTransactionExecuted

```solidity
event MetaTransactionExecuted(
    address indexed relayer,
    address indexed user,
    address indexed target,
    uint256 value,
    bytes data,
    bool success
);
```

**Emitted**: For each individual meta-transaction execution.

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

### PausedWithReason

```solidity
event PausedWithReason(string reason);
```

**Emitted**: When the contract is paused with a reason.

### TokenRescued

```solidity
event TokenRescued(address indexed token, address indexed to, uint256 amount);
```

**Emitted**: When tokens are rescued by the owner.

## EIP-712 Implementation

### Domain Separator

```solidity
EIP712Domain(
    string name,      // "MetaTxGateway"
    string version,   // "1"
    uint256 chainId,  // Network chain ID
    address verifyingContract // Contract address
)
```

### MetaTransaction Type

```solidity
MetaTransaction(
    address to,
    uint256 value,
    bytes data
)
```

### Batch MetaTransactions Type

```solidity
MetaTransactions(
    address from,
    MetaTransaction[] metaTxs,
    uint256 nonce,
    uint256 deadline
)
```

### Signature Generation (Frontend)

```javascript
const domain = {
    name: 'MetaTxGateway',
    version: '1',
    chainId: await web3.eth.getChainId(),
    verifyingContract: contractAddress
};

const types = {
    MetaTransaction: [
        { name: 'to', type: 'address' },
        { name: 'value', type: 'uint256' },
        { name: 'data', type: 'bytes' }
    ],
    MetaTransactions: [
        { name: 'from', type: 'address' },
        { name: 'metaTxs', type: 'MetaTransaction[]' },
        { name: 'nonce', type: 'uint256' },
        { name: 'deadline', type: 'uint256' }
    ]
};

const value = {
    from: userAddress,
    metaTxs: metaTxsArray, // Array of {to, value, data}
    nonce: await contract.getNonce(userAddress),
    deadline: Math.floor(Date.now() / 1000) + 3600 // 1 hour
};

const signature = await signer._signTypedData(domain, types, value);
```

## Security Considerations

- All addresses are validated for zero address.
- Signature recovery is performed safely.
- Uses OpenZeppelin's ReentrancyGuard and Pausable.
- Only owner can authorize relayers and upgrades.
- Refunds unused native tokens to users.

## Integration Examples

### Basic Meta-Transaction

```javascript
const metaTx = {
    to: tokenContract.address,
    value: 0,
    data: tokenContract.interface.encodeFunctionData('transfer', [recipient, amount])
};

const metaTxs = [metaTx];

const requiredValue = await gateway.calculateRequiredValue(metaTxs);

const tx = await gateway.executeMetaTransactions(
    userAddress,
    metaTxs,
    signature,
    nonce,
    deadline,
    { value: requiredValue }
);
```

### Native Token Meta-Transaction

```javascript
const metaTx = {
    to: recipientAddress,
    value: ethers.utils.parseEther('0.1'),
    data: '0x'
};

const metaTxs = [metaTx];

const requiredValue = await gateway.calculateRequiredValue(metaTxs);

const tx = await gateway.executeMetaTransactions(
    userAddress,
    metaTxs,
    signature,
    nonce,
    deadline,
    { value: requiredValue }
);
```

## Deployed Contracts

- MetaTxGateway (deployed)  
  Chains: Mainnet, BSC, Base, Polygon, Optimism, Arbitrum, Avalanche  
  Address: 0xbee9591415128F7d52279C8df327614d8fD8a9b2

- GasCreditVault (BSC)  
  Address: 0x0A4467D2D63dB133eC34162Ca0f738948d40A28c

## Next Steps

- **[Native Token Handling](metatxgateway/native-token-handling.md)** - Deep dive into value validation
- **[Batch Processing](metatxgateway/batch-processing.md)** - Optimize with batches
- **[EIP-712 Signatures](metatxgateway/eip-712-signatures.md)** - Signature implementation
- **[API Reference](../api/metatxgateway-api.md)** - Complete function reference
- **[DI Token](../tokenomics/di-token.md)** - Token details and governance
- **[Token Presale](../tokenomics/token-presale.md)** - Presale participation guide
- **[Token Staking](../tokenomics/token-staking.md)** - Staking and rewards
- **Vesting schedule** (optional)
- **Funds forwarding** to treasury

#### Contract Interface

```solidity
function buyTokens() external payable;
function claimTokens() external;
function setRate(uint256 newRate) external onlyOwner;
function setSaleActive(bool active) external onlyOwner;
function withdrawFunds(address payable to) external onlyOwner;
```

### Token Staking

The Token Staking contract allows users to lock DI tokens and earn rewards. Staking supports flexible or fixed terms, with rewards distributed in DI tokens.

#### Key Features

- **Stake/unstake** at any time (or after lock period)
- **Reward calculation** based on staked amount and duration
- **Penalty for early withdrawal** (optional)
- **View functions** for user and pool stats

#### Contract Interface

```solidity
function stake(uint256 amount) external;
function unstake(uint256 amount) external;
function claimRewards() external;
function getStaked(address user) external view returns (uint256);
function getPendingRewards(address user) external view returns (uint256);
```

## Next Steps

- **[Native Token Handling](metatxgateway/native-token-handling.md)** - Deep dive into value validation
- **[Batch Processing](metatxgateway/batch-processing.md)** - Optimize with batches
- **[EIP-712 Signatures](metatxgateway/eip-712-signatures.md)** - Signature implementation
- **[API Reference](../api/metatxgateway-api.md)** - Complete function reference
- **[DI Token](./di-token.md)** - Token details and governance
- **[Token Presale](./token-presale.md)** - Presale participation guide
- **[Token Staking](./token-staking.md)** - Staking and rewards
