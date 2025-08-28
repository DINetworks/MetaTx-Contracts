# Performance Optimization

Practical recommendations to improve gas efficiency and performance for MetaTxGateway and related contracts.

## High-level strategies

- Reduce external calls and on-chain computations where possible.
- Favor calldata over memory for read-only arrays.
- Batch operations to amortize per-transaction overhead.

## Specific optimizations

1. Use calldata for input arrays  
   - Functions that accept arrays (metaTxs) should use calldata to save gas.

2. Minimize storage writes  
   - Only write to storage when necessary (e.g., increment nonces once per batch).
   - Group storage writes to reduce SSTORE overhead.

3. Event design  
   - Emit concise events. Emit aggregate events for batches rather than excessive per-call logging if history needs permit.

4. Packing and types  
   - Pack booleans and small integers into single storage slots where applicable.
   - Use indexed fields in events selectively (up to 3 indexes).

5. Gas-aware external calls  
   - When invoking user-target contracts, avoid specifying large gas limits; allow call to use gasleft().
   - Use try-catch patterns to avoid bubbling errors that cause full revert when partial success is desired.

6. Reserve gas for cleanup  
   - When calling external contracts from within try-catch, reserve a small gas buffer for state updates and refunds.

7. Offload heavy work off-chain  
   - Signature aggregation, batch building, pre-validation, and retries should be handled by relayers or services off-chain.

8. Benchmark and iterate  
   - Use mainnet forks and measure gas for representative batches.
   - Keep a regression test for gas usage to detect accidental regressions.

## Example: Packing results

- Instead of returning bool[] in storage, compress results into a bitfield for on-chain summaries and expand off-chain when needed.

## Tools & Measurement

- Hardhat gas reporter and profiler.
- Tenderly or block explorer transaction traces for real-time analysis.
- OpenZeppelin Contracts-like audit tools to find costly patterns.

## Trade-offs

- Aggressive optimization may reduce readability and maintainability. Prefer clear code with targeted optimizations in hot paths.
