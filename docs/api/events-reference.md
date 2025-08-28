# Events Reference

Common events emitted by MetaTx-Contracts components. Use these names/arg indices when parsing receipts.

## MetaTxGateway
- RelayerAuthorized(address indexed relayer, bool authorized)
- MetaTransactionExecuted(address indexed relayer, address indexed user, address indexed target, uint256 value, bytes data, bool success)
- NativeTokenUsed(uint256 indexed batchId, uint256 totalRequired, uint256 totalUsed, uint256 refunded)
- PausedWithReason(string reason)
- TokenRescued(address indexed token, address indexed to, uint256 amount)

## GasCreditVault (examples)
- Deposited(address indexed user, address indexed token, uint256 tokenAmount, uint256 creditsMinted)
- Withdrawn(address indexed user, address indexed token, uint256 tokenAmount, uint256 creditsBurned)
- CreditsConsumed(address indexed consumer, address indexed account, uint256 credits)
- TokenSupported(address indexed token)
- TokenRemoved(address indexed token)

## DI Token (ERC20)
- Transfer(address indexed from, address indexed to, uint256 value)
- Approval(address indexed owner, address indexed spender, uint256 value)

## Other system-level events
- BatchTransactionExecuted (if implemented by integrations): summary event for batches
- Governance events (proposal created, voted, executed) — see governance docs

## Parsing tips
- Use indexed fields to filter logs efficiently.
- Decode `bytes data` return payloads carefully — may vary by target ABI.
- Combine event logs with transaction status and internal receipts for full audit.
