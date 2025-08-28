# Error Codes & Revert Reasons

Common revert messages across MetaTx-Contracts and troubleshooting hints.

| Revert message | Likely cause | Suggested fix |
|----------------|--------------|---------------|
| "Invalid relayer address" | setRelayerAuthorization called with zero address | Supply a valid relayer address |
| "Unauthorized relayer" | Caller not authorized to submit batch | Authorize relayer via owner or use authorized relayer |
| "Transaction expired" | Deadline passed | Recreate signature with a later deadline |
| "Invalid nonce" | Nonce mismatch | Fetch current nonce via getNonce and resubmit |
| "Invalid signature" | Signature mismatch or wrong domain/typed data | Recompute EIP‑712 digest with correct domain and types, ensure signing account matches `from` |
| "Empty batch Txs" | metaTxs array length == 0 | Provide at least one MetaTransaction |
| "Incorrect native token amount" | msg.value != sum(metaTx.value) | Call calculateRequiredValue and send exact value in relayer tx |
| "Refund failed" | Native refund call reverted | Check recipient fallback/receive behavior; ensure `from` can receive native tokens |
| "Only self-calls allowed" | Internal helper called externally | Do not call internal safe-execution helpers directly from external transactions |
| "Already paused" / "Not paused" | Pause state misuse | Check pause state before calling pause/unpause |
| "Invalid address" | Zero address or missing address provided | Supply valid non-zero addresses |
| "Unsupported token" | Token not enabled in GasCreditVault | Add token or use supported token |
| "Oracle not set" | Price feed missing | Configure oracle for token |

Notes:
- Some revert strings may be concatenated or originate from OpenZeppelin libraries (e.g., Ownable).
- For ambiguous failures, inspect transaction revert data and events and reproduce locally with hardhat traces.

