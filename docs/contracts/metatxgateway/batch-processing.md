# Batch Processing

The MetaTxGateway contract allows multiple meta-transactions to be executed in a single blockchain transaction. This reduces gas costs, improves user experience, and enables complex workflows to be performed atomically.

## Overview

Batch processing in MetaTxGateway enables:
- **Atomic execution** of multiple operations in a single transaction
- **Gas cost optimization** by reducing per-transaction overhead
- **Simplified workflows** for users and relayers

## How It Works

- The user signs a batch of meta-transactions (array of `MetaTransaction` structs) using EIP-712.
- The relayer submits the batch to `executeMetaTransactions`.
- Each transaction in the batch is executed in order.
- If a transaction fails, it does not revert the entire batch; each transaction's success is tracked individually.
- Unused native tokens (ETH/BNB) are refunded to the user if some transactions fail.

## Example: Batch Execution

```solidity
function executeMetaTransactions(
    address from,
    MetaTransaction[] calldata metaTxs,
    bytes calldata signature,
    uint256 nonce,
    uint256 deadline
) external payable nonReentrant whenNotPaused returns (bool[] memory successes)
```

- `metaTxs`: Array of transactions to execute.
- `signature`: EIP-712 signature for the batch.
- Returns: Array of booleans indicating success/failure for each transaction.

## MetaTransaction Struct

```solidity
struct MetaTransaction {
    address to;        // Target contract address
    uint256 value;     // Native token amount (ETH/BNB)
    bytes data;        // Function call data
}
```

## Batch Execution Flow

1. **Relayer collects meta-transactions from the user.**
2. **User signs the batch using EIP-712.**
3. **Relayer calls `executeMetaTransactions` with the batch and signature.**
4. **Contract verifies signature, nonce, and deadline.**
5. **Each transaction is executed in order.**
6. **Success/failure for each transaction is returned.**
7. **Unused native tokens are refunded to the user.**
8. **Relayer deducts user credits from GasCreditVault to cover gas fees.**

## Example (JavaScript)

```javascript
const metaTxs = [
  {
    to: contractA.address,
    value: 0,
    data: contractA.interface.encodeFunctionData('doSomething', [arg1])
  },
  {
    to: contractB.address,
    value: ethers.utils.parseEther('0.1'),
    data: '0x'
  }
];

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

## Notes

- All meta-transactions in the batch must be signed together.
- The batch does not revert if one transaction fails; each result is reported individually.
- There are no advanced execution modes (all-or-nothing, partial, etc.) in the current contract.

---

**Related Topics**:
- [Native Token Handling](native-token-handling.md)
- [EIP-712 Signatures](eip-712-signatures.md)
- [MetaTxGateway Overview](../metatxgateway.md)