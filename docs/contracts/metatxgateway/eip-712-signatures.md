# EIP-712 Signatures

MetaTxGateway uses the EIP-712 standard for secure, structured meta-transaction signing. This ensures signatures are valid, replay-protected, and compatible with wallets.

## EIP-712 Domain

```solidity
EIP712Domain(
    string name,      // "MetaTxGateway"
    string version,   // "1"
    uint256 chainId,  // Network chain ID
    address verifyingContract // Contract address
)
```

## MetaTransaction Type

```solidity
MetaTransaction(
    address to,
    uint256 value,
    bytes data
)
```

## Batch MetaTransactions Type

```solidity
MetaTransactions(
    address from,
    MetaTransaction[] metaTxs,
    uint256 nonce,
    uint256 deadline
)
```

## Signing a Batch (Frontend Example)

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

## Signature Verification (Contract)

The contract verifies the signature using the EIP-712 domain and the batch data. The signature must match the `from` address and current nonce.

## Security

- Nonce and deadline prevent replay attacks.
- Only the user who signed the batch can authorize execution.
- All meta-transactions in the batch are covered by a single signature.

---


**Related Topics**:
- [Native Token Handling](native-token-handling.md) - Signing value transactions
- [Batch Processing](batch-processing.md) - Signing batch transactions
- [MetaTxGateway Overview](../metatxgateway.md) - Main contract documentation
