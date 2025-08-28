# MetaTxGateway API Reference

Summary of public/external functions, events and common errors for the MetaTxGateway contract version v2.0.0.

## Contract metadata
- Name: MetaTxGateway
- Upgrade pattern: UUPS (owner-authorized)
- Pausable: yes (pauseWithReason / unpause)

## Important structs
- MetaTransaction
  - to: address
  - value: uint256
  - data: bytes
  - nonce: uint256
  - deadline: uint256
  - signature: bytes

## Initialization
- initialize() external
  - Initialize the upgradeable contract (owner set via initializer).

## Relayer management
- setRelayerAuthorization(address relayer, bool authorized) external onlyOwner
  - Authorize / deauthorize relayer addresses.

- isRelayerAuthorized(address relayer) external view returns (bool)
  - Check relayer status.

## Pause / resume
- pauseWithReason(string calldata reason) external onlyOwner
  - Pause contract and store a human-readable reason.

- unpause() external onlyOwner
  - Unpause contract.

## Core execution
- executeMetaTransactions(
    MetaTransaction[] calldata transactions
  ) external payable
  - Executes a batch of meta-transactions with signature verification.
  - Validations:
    - Signature verified via EIP‑712 using domain (name: "MetaTxGateway", version: "2.0.0").
    - Nonce must equal `nonces[from]`.
    - Deadline must not be expired.
    - If msg.value > 0, msg.value must equal sum(metaTx.value).
  - Behavior:
    - Each metaTx is executed with try/catch; failures do not revert the entire batch.
    - Tracks value used; refunds unused native tokens to `from`.
    - Increments `nonces[from]` on success path.
  - Returns an array of booleans indicating per-transaction success.

## Helpers & view functions
- calculateRequiredValue(MetaTransaction[] calldata metaTxs) external pure returns (uint256 totalValue)
  - Sum of metaTx.value.

- getNonce(address user) external view returns (uint256 currentNonce)
  - Returns current nonce for `user`.

- name() external pure returns (string memory)
  - Returns "MetaTxGateway"

- version() external pure returns (string memory)
  - Returns "2.0.0"

- domainSeparator() external view returns (bytes32)
  - Returns EIP‑712 domain separator used to compute digest.

- UPGRADE_INTERFACE_VERSION() external pure returns (string memory)
  - Returns "5.0.0"

## Events
- event MetaTransactionExecuted(address indexed user, address indexed to, bool success, bytes returnData)
- event NativeTokenUsed(address indexed user, uint256 amount)
- event Upgraded(address indexed implementation)
- event RelayerAuthorized(address indexed relayer, bool authorized)
- event PausedWithReason(string reason)
- event TokenRescued(address indexed token, address indexed to, uint256 amount)

## Common error strings (revert reasons)
- "Invalid relayer address"
- "Unauthorized relayer"
- "Transaction expired"
- "Invalid nonce"
- "Invalid signature"
- "Empty batch Txs"
- "Incorrect native token amount"
- "Refund failed"
- "Only self-calls allowed"
- "Already paused"
- "Not paused"
- "Invalid address"

## Notes & integration tips
- Frontends should use `_signTypedData` with domain version "2.0.0" and the MetaTransactions type (array of MetaTransaction).
- Always call calculateRequiredValue(metaTxs) to compute exact msg.value for relayer transaction.
- Relayers must be authorized by owner to call executeMetaTransactions.
- Monitor NativeTokenUsed events for refunds and accounting.
    nonce: 1,
    deadline: 1640995200,
    signature: "0x..."
  }
];

// With native token value
const tx = await gateway.executeMetaTransactions(transactions, {
  value: ethers.parseEther("0.1")
});

// Without native token value  
const tx = await gateway.executeMetaTransactions(transactions);
```

### upgrade

Upgrades the contract implementation using UUPS pattern.

```solidity
function upgrade(address newImplementation) external
```

**Parameters:**
- `newImplementation`: Address of the new implementation contract

**Access Control:** Owner only

**Events Emitted:**
- `Upgraded(address indexed implementation)`

**Example Usage:**
```javascript
// Only contract owner can call this
await gateway.connect(owner).upgrade(newImplementationAddress);
```

## Read Functions

### getNonce

Returns the current nonce for a user address.

```solidity
function getNonce(address user) external view returns (uint256)
```

**Parameters:**
- `user`: User address to query

**Returns:** Current nonce value (starts at 0)

**Example Usage:**
```javascript
const nonce = await gateway.getNonce(userAddress);
console.log(`Current nonce: ${nonce}`);

// Use for next transaction
const nextTransaction = {
  // ... other fields
  nonce: nonce,
  // ...
};
```

### name

Returns the contract name used in EIP-712 domain separator.

```solidity
function name() external pure returns (string memory)
```

**Returns:** "MetaTxGateway"

**Usage in EIP-712:**
```javascript
const domain = {
  name: await gateway.name(), // "MetaTxGateway"
  version: await gateway.version(),
  chainId: 56,
  verifyingContract: await gateway.getAddress()
};
```

### version

Returns the contract version used in EIP-712 domain separator.

```solidity
function version() external pure returns (string memory)
```

**Returns:** "2.0.0"

**Usage:** Used for EIP-712 signature domain separation between contract versions.

### domainSeparator

Returns the EIP-712 domain separator hash.

```solidity
function domainSeparator() external view returns (bytes32)
```

**Returns:** Computed domain separator hash

**Example Usage:**
```javascript
const separator = await gateway.domainSeparator();
console.log(`Domain separator: ${separator}`);
```

### UPGRADE_INTERFACE_VERSION

Returns the UUPS upgrade interface version.

```solidity
function UPGRADE_INTERFACE_VERSION() external pure returns (string memory)
```

**Returns:** "5.0.0"

**Usage:** Internal compatibility checking for UUPS upgrades.

## Events

### MetaTransactionExecuted

Emitted for each executed meta-transaction in a batch.

```solidity
event MetaTransactionExecuted(
    address indexed user,
    address indexed to,
    bool success,
    bytes returnData
)
```

**Parameters:**
- `user`: Address of the transaction signer
- `to`: Target contract address
- `success`: Whether the transaction succeeded
- `returnData`: Return data from the target call

**Example Listening:**
```javascript
gateway.on("MetaTransactionExecuted", (user, to, success, returnData, event) => {
  console.log(`Transaction from ${user} to ${to}: ${success ? 'Success' : 'Failed'}`);
  if (returnData && returnData !== '0x') {
    console.log(`Return data: ${returnData}`);
  }
});
```

### NativeTokenUsed

Emitted when native tokens (ETH/BNB) are included in meta-transactions.

```solidity
event NativeTokenUsed(
    address indexed user,
    uint256 amount
)
```

**Parameters:**
- `user`: User whose tokens were used
- `amount`: Amount of native tokens in wei

**Example Listening:**
```javascript
gateway.on("NativeTokenUsed", (user, amount, event) => {
  console.log(`${user} used ${ethers.formatEther(amount)} native tokens`);
});
```

### Upgraded

Emitted when the contract implementation is upgraded.

```solidity
event Upgraded(address indexed implementation)
```

**Parameters:**
- `implementation`: Address of the new implementation contract

## Error Reference

### Custom Errors

#### InvalidSignature()
- **Cause:** EIP-712 signature verification failed
- **Solutions:** Check domain parameters, signature format, signer address

#### ExpiredDeadline()
- **Cause:** Transaction deadline has passed
- **Solutions:** Create new transaction with fresh deadline

#### InvalidNonce()
- **Cause:** Nonce doesn't match expected value
- **Solutions:** Fetch current nonce and use correct value

#### ExecutionFailed()
- **Cause:** Target transaction reverted
- **Solutions:** Check target contract state, parameters, and permissions

### Standard Errors

#### Revert Messages
- `"Address: low-level call failed"` - Target contract call failed
- `"Address: insufficient balance"` - Not enough ETH for value transfer
- `"Ownable: caller is not the owner"` - Access control violation

## EIP-712 Signature Specification

### Domain

```javascript
const domain = {
  name: "MetaTxGateway",
  version: "2.0.0",
  chainId: 56, // BSC Mainnet
  verifyingContract: "0x..." // Gateway contract address
};
```

### Types

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

### Message Format

```javascript
const message = {
  to: "0x742d35Cc6635C0532925a3b8D624Afce0c31a7f4",
  value: "100000000000000000", // 0.1 ETH in wei (as string)
  data: "0xa9059cbb...", // Function call data
  nonce: "1", // Current nonce (as string)
  deadline: "1640995200" // Unix timestamp (as string)
};
```

### Signing Process

```javascript
// Sign with ethers.js
const signature = await signer.signTypedData(domain, types, message);

// Verify signature (optional)
const recoveredAddress = ethers.verifyTypedData(domain, types, message, signature);
console.log(`Signer: ${recoveredAddress}`);
```

## Integration Examples

### Basic Meta-Transaction

```javascript
async function executeBasicTransaction(signer, targetAddress, callData) {
  const gateway = await ethers.getContractAt("MetaTxGateway", gatewayAddress);
  
  // Get current nonce
  const userAddress = await signer.getAddress();
  const nonce = await gateway.getNonce(userAddress);
  
  // Prepare transaction
  const deadline = Math.floor(Date.now() / 1000) + 300; // 5 minutes
  const transaction = {
    to: targetAddress,
    value: 0,
    data: callData,
    nonce: nonce,
    deadline: deadline
  };
  
  // Sign transaction
  const domain = {
    name: await gateway.name(),
    version: await gateway.version(),
    chainId: (await signer.provider.getNetwork()).chainId,
    verifyingContract: await gateway.getAddress()
  };
  
  const types = {
    MetaTransaction: [
      { name: "to", type: "address" },
      { name: "value", type: "uint256" },
      { name: "data", type: "bytes" },
      { name: "nonce", type: "uint256" },
      { name: "deadline", type: "uint256" }
    ]
  };
  
  const signature = await signer.signTypedData(domain, types, {
    to: transaction.to,
    value: transaction.value.toString(),
    data: transaction.data,
    nonce: transaction.nonce.toString(),
    deadline: transaction.deadline.toString()
  });
  
  // Execute transaction
  const tx = await gateway.executeMetaTransactions([{
    ...transaction,
    signature
  }]);
  
  return await tx.wait();
}
```

### Batch Transaction

```javascript
async function executeBatchTransactions(signer, transactions) {
  const gateway = await ethers.getContractAt("MetaTxGateway", gatewayAddress);
  const userAddress = await signer.getAddress();
  
  // Get starting nonce
  let nonce = await gateway.getNonce(userAddress);
  
  // Prepare all transactions
  const deadline = Math.floor(Date.now() / 1000) + 300;
  const signedTransactions = [];
  
  for (const tx of transactions) {
    const transaction = {
      to: tx.to,
      value: tx.value || 0,
      data: tx.data || "0x",
      nonce: nonce,
      deadline: deadline
    };
    
    // Sign each transaction
    const signature = await signTransaction(signer, transaction);
    signedTransactions.push({ ...transaction, signature });
    
    nonce = nonce + 1n; // Increment nonce for next transaction
  }
  
  // Calculate total native value needed
  const totalValue = signedTransactions.reduce(
    (sum, tx) => sum + BigInt(tx.value), 
    0n
  );
  
  // Execute batch
  const tx = await gateway.executeMetaTransactions(signedTransactions, {
    value: totalValue
  });
  
  return await tx.wait();
}
```

### Transaction with Native Tokens

```javascript
async function executeWithNativeTokens(signer, targetAddress, ethAmount) {
  const gateway = await ethers.getContractAt("MetaTxGateway", gatewayAddress);
  const userAddress = await signer.getAddress();
  
  const nonce = await gateway.getNonce(userAddress);
  const deadline = Math.floor(Date.now() / 1000) + 300;
  
  const transaction = {
    to: targetAddress,
    value: ethers.parseEther(ethAmount),
    data: "0x", // Simple ETH transfer
    nonce: nonce,
    deadline: deadline
  };
  
  const signature = await signTransaction(signer, transaction);
  
  // Include ETH value in the call
  const tx = await gateway.executeMetaTransactions([{
    ...transaction,
    signature
  }], {
    value: transaction.value // Must match transaction value
  });
  
  return await tx.wait();
}
```

## Gas Optimization

### Efficient Batch Sizes

```javascript
// Optimal batch size for gas efficiency
const OPTIMAL_BATCH_SIZE = 5;

async function optimizedBatchExecution(transactions) {
  const batches = [];
  for (let i = 0; i < transactions.length; i += OPTIMAL_BATCH_SIZE) {
    batches.push(transactions.slice(i, i + OPTIMAL_BATCH_SIZE));
  }
  
  const results = [];
  for (const batch of batches) {
    const receipt = await executeBatchTransactions(signer, batch);
    results.push(receipt);
  }
  
  return results;
}
```

### Gas Estimation

```javascript
async function estimateMetaTransactionGas(transactions) {
  try {
    const estimatedGas = await gateway.estimateGas.executeMetaTransactions(
      transactions,
      { value: calculateTotalValue(transactions) }
    );
    
    // Add 20% buffer for safety
    return estimatedGas * 120n / 100n;
  } catch (error) {
    console.warn("Gas estimation failed, using fallback");
    return 500000n; // Fallback gas limit
  }
}
```

## Security Considerations

### Signature Validation

Always validate signatures client-side before submission:

```javascript
function validateSignature(transaction, signature, expectedSigner) {
  const domain = getDomainSeparator();
  const types = getTypeDefinition();
  
  const recoveredAddress = ethers.verifyTypedData(
    domain, 
    types, 
    transaction, 
    signature
  );
  
  return recoveredAddress.toLowerCase() === expectedSigner.toLowerCase();
}
```

### Deadline Management

Set appropriate deadlines to prevent stale transactions:

```javascript
function createDeadline(minutesFromNow = 5) {
  return Math.floor(Date.now() / 1000) + (minutesFromNow * 60);
}

function validateDeadline(deadline) {
  const now = Math.floor(Date.now() / 1000);
  if (deadline <= now) {
    throw new Error("Transaction deadline has passed");
  }
  if (deadline > now + 3600) { // Max 1 hour
    throw new Error("Deadline too far in the future");
  }
}
```

### Nonce Management

Implement proper nonce tracking:

```javascript
class NonceManager {
  constructor(gateway, userAddress) {
    this.gateway = gateway;
    this.userAddress = userAddress;
    this.localNonce = null;
  }
  
  async getNextNonce() {
    if (this.localNonce === null) {
      this.localNonce = await this.gateway.getNonce(this.userAddress);
    }
    
    const nonce = this.localNonce;
    this.localNonce = this.localNonce + 1n;
    return nonce;
  }
  
  async syncWithContract() {
    this.localNonce = await this.gateway.getNonce(this.userAddress);
  }
}
```

## Testing Utilities

### Mock Setup

```javascript
// Test helper for contract interaction
class MetaTxGatewayTestHelper {
  constructor(gateway, signer) {
    this.gateway = gateway;
    this.signer = signer;
    this.userAddress = null;
  }
  
  async initialize() {
    this.userAddress = await this.signer.getAddress();
  }
  
  async createMockTransaction(targetAddress = this.userAddress, value = 0) {
    const nonce = await this.gateway.getNonce(this.userAddress);
    
    return {
      to: targetAddress,
      value: value,
      data: "0x",
      nonce: nonce,
      deadline: Math.floor(Date.now() / 1000) + 300
    };
  }
  
  async signAndExecute(transaction) {
    const signature = await this.signTransaction(transaction);
    return await this.gateway.executeMetaTransactions([{
      ...transaction,
      signature
    }]);
  }
}
```

## Migration Guide

### From v1.0.0 to v2.0.0

**Key Changes:**
1. Domain version updated to "2.0.0"
2. Added native token support
3. Enhanced error messages

**Migration Steps:**
```javascript
// Update domain separator
const domain = {
  name: "MetaTxGateway",
  version: "2.0.0", // Changed from "1.0.0"
  chainId: 56,
  verifyingContract: newContractAddress
};

// Handle native token transactions
if (hasNativeValue) {
  await gateway.executeMetaTransactions(transactions, {
    value: totalNativeValue
  });
}
```

{% hint style="warning" %}
**Breaking Change**: Signatures created with domain version "1.0.0" will not work with v2.0.0 contracts. Update your signing code to use version "2.0.0".
{% endhint %}

## Support

For technical support or questions about the MetaTxGateway API:

- **GitHub Issues**: [Report bugs or request features](https://github.com/DINetworks/MetaTx-Contracts/issues)
- **Documentation**: [Browse complete documentation](../README.md)
- **Community**: Join our Discord for community support
- **Email**: [support@metatx-contracts.com](mailto:support@metatx-contracts.com)
