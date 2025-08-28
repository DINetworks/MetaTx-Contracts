# Native Token Handling

MetaTxGateway supports meta-transactions that require native tokens (ETH/BNB). The contract ensures the correct amount is provided and refunds any unused value.

## How It Works

- Each `MetaTransaction` in the batch can specify a `value` (amount of native token to send).
- The relayer must send exactly the total required value (`sum(metaTx.value)` for all transactions) as `msg.value`.
- If some transactions fail, the unused value is refunded to the user.

## Example

Suppose you want to batch two meta-transactions:
- First sends 0.1 ETH to an address.
- Second calls a contract with no ETH.

```javascript
const metaTxs = [
  {
    to: recipientAddress,
    value: ethers.utils.parseEther('0.1'),
    data: '0x'
  },
  {
    to: contractAddress,
    value: 0,
    data: contract.interface.encodeFunctionData('doSomething', [arg])
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

## Refunds

- If a transaction fails, its `value` is not spent.
- After execution, any unused value is refunded to the user (`from` address).
- The `NativeTokenUsed` event logs the required, used, and refunded amounts.

## Security

- The contract checks that `msg.value` matches the total required value.
- No overpayment or underpayment is allowed.
- Refunds are automatic and cannot be intercepted by relayers.

## Best Practices

### For Developers

1. **Always validate value amounts** before execution
2. **Implement proper refund logic** for failed transactions
3. **Use reentrancy guards** on all value-handling functions
4. **Check contract balance consistency** regularly
5. **Handle edge cases** like zero values and failed transfers

### For Users

1. **Monitor the balance of native tokens of Relayer** for better execution guarantees
2. **Monitor your credits to cover costs of native tokens** in the gateway
3. **Be aware of gas costs** when using native token features
4. **Test with small amounts** before large transactions
5. **Keep backup funds** for emergency withdrawals

### For Relayers

1. **Calculate value requirements** accurately before execution
2. **Implement retry logic** for failed value transfers
3. **Monitor contract balance** for anomalies
4. **Use batch operations** to optimize gas costs
5. **Implement proper accounting** for fronted values

## Gas Considerations

Native token handling adds gas overhead:

- **Simple value transfer**: +2,100 gas (native send)
- **Contract call with value**: +2,100 + call overhead
- **Refund operations**: +21,000 gas per refund
- **Balance checks**: +2,100 gas per check

Plan your gas limits accordingly when using native token features.


---

**Related Topics**:
- [Batch Processing](batch-processing.md) - Combining multiple value transfers
- [EIP-712 Signatures](eip-712-signatures.md) - Signing value transactions
- [MetaTxGateway Overview](../metatxgateway.md) - Main contract documentation
