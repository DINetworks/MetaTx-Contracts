# Multi-Chain Support

MetaTxGateway can be deployed across multiple EVM-compatible chains. This page covers critical considerations.

## Domain separator & chainId

- EIP-712 domain includes chainId. Signatures are chain-specific; a signature for one chain will not be valid on another.
- When deploying to a new chain, ensure frontends use the correct chainId and verifyingContract address when building EIP-712 domain.

## Deployment checklist per chain

1. Deploy DI and related token contracts (or map to existing token addresses).
2. Deploy MetaTxGateway implementation and proxy.
3. Initialize gateway and authorize relayers for that chain.
4. Configure treasury and staking addresses specific to the chain.
5. Verify contract addresses and update documentation and frontends.

## Bridging & Cross-chain UX

- Tokens and state are chain-specific. If users move assets across chains, integrate trusted bridges and clearly indicate token provenance in UI.
- Avoid expecting signatures to be valid across chains; treat each deployment independently.

## Relayers & Network Topology

- Use relayers with nodes and gas funding on each target chain.
- Consider a global relayer fleet with per-chain wallets or dedicated relayers per chain.

## Monitoring and Operations

- Track per-chain metrics: transaction throughput, gas usage, refunds, failure rates.
- Centralize logs and alerts for faster incident response across chains.

## Common pitfalls

- Incorrect chainId in frontend signature builder.
- Address mismatch between deployed gateway and domain verifyingContract.
- Assuming same token liquidity across chains — adjust liquidity/tokens per network.
