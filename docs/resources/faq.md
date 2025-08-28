# FAQ

## Basics

Q: What is MetaTx-Contracts?  
A: A suite enabling gasless meta-transactions (MetaTxGateway), gas-credit management (GasCreditVault), and DI token/tokenomics (presale, staking).

Q: How do meta-transactions work?  
A: A user signs a batch using EIP‑712. An authorized relayer submits the batch and pays gas. If native value is required, the relayer supplies msg.value; unused value is refunded to the user.

Q: Who can be a relayer?  
A: Only addresses authorized by the contract owner via `setRelayerAuthorization`.

Q: How are refunds handled?  
A: The contract sums the required native value and requires the relayer to include exactly that `msg.value`. Any unused native value after execution is refunded to the user's address.

Q: Where can I find deployed contract addresses?  
A: See the respective contract docs (MetaTxGateway, GasCreditVault, DI Token pages) for deployed addresses.

Q: Where do I get DI Tokens?  
A: Through presale, staking rewards, or supported exchanges — see Token Presale and Token Staking docs.

## What Makes MetaTx-Contracts Different?

- Gas credit system for prepaid gas with supported tokens
- Native token support for meta-transactions (ETH/BNB)
- Batch processing to reduce user friction and gas
- UUPS upgradeability for safer upgrades
- EIP-712 standardized signatures

## Networks & Deployments

**Primary networks:**  
- BSC Mainnet & Testnet

**Additional deployments (see contract pages):**  
- Ethereum Mainnet, Polygon, Base, Optimism, Arbitrum, Avalanche (deployments may vary by component; check contract pages for exact addresses)

## Gas Credits & Pricing

Q: What tokens can I use for gas credits?  
A: On BSC mainnet common examples are USDT, USDC, DI(in the future). Additional tokens may be supported by governance.

Q: How are gas credits calculated?  
A: Credits are derived from token deposits and oracle prices (e.g., Chainlink) to price token amounts into native-gas-equivalent units. Example formula (conceptual):

```
credits = (tokenAmount × tokenPrice) / (gasPrice × normalization)
```

Exact implementations use token decimals and oracle price formatting; see GasCreditVault docs for precise formulas.

Q: Are gas credits actual ERC tokens?  
A: No — gas credits are internal accounting units that are backed by deposited tokens in GasCreditVault. They are spent by authorized systems per policy.

## Meta-Transaction Limits & Signatures

Q: What are recommended batch limits?  
A: Reasonable defaults (adjust per deployment):  
- Transactions per batch: typically 10 or fewer  
- Per-transaction gas: watch target contract limits; avoid extremely large individual calls  
- Signature deadline: short-lived (up to 10 minutes) depending on UX needs

Q: How long do signatures last?  
A: Signatures include a deadline timestamp. Recommended lifetimes:
- Interactive UX: 5–10 minutes
- Automated flows: 1–5 minutes
- Less time for high-value operations

Q: How is replay prevented?  
A: Nonces, deadlines, domain separation and chainId binding prevent replay attacks across time and chains.

## Security

Q: Is my private key safe?  
A: Yes — private keys never leave your wallet. Only signatures are shared. EIP‑712 prevents generic replay and makes domain-specific signing safe.

Q: What if the relayer is malicious?  
A: Relayers cannot alter signed content. You can run your own relayer or choose trusted relayers. Monitor relayer policies and logs.

Q: How are credits protected?  
A: Access control, reentrancy guards, audited libraries, and oracle validation help protect funds and pricing. See security disclosure for reporting vulnerabilities.

## Usage & Troubleshooting

Q: Do I need native ETH/BNB in my wallet?  
A: No for meta-transactions if gas credits are funded and the relayer is authorized. You may need native tokens for direct interactions, initial deposits, or emergency operations.

Q: Why is my meta-transaction failing?  
A: Common causes:
1. Insufficient gas credits or relay funds
2. Expired signature (deadline passed)
3. Incorrect nonce
4. Wrong network / chainId
5. Target contract reverted (application error)

Q: Why aren't my credits showing?  
A: Check network, contract address, transaction success on chain, and refresh frontend caches. Confirm deposit transaction succeeded.

Q: Can I transfer credits?  
A: Some deployments provide utilities to transfer internal credits between accounts — check GasCreditVault docs and contract capabilities.

Q: Can I run my own relayer?  
A: Yes. Relayer code, configuration, and deployment instructions are provided. Running your own relayer gives full control over fees and behavior.

## Development & Integration

Q: What languages / frameworks are supported?  
A: Frontend: JavaScript/TypeScript (ethers.js). Contracts: Solidity 0.8.20+. SDKs for other languages are planned.

Q: How do I sign a batch?  
A: Use EIP‑712 typed data. See the EIP‑712 Signatures doc for domain and types with examples for _signTypedData.

Q: How do I test meta-transactions locally?  
A: Use Hardhat, deploy contracts to a local node or testnet, and run unit/integration tests. Examples are in the `test/` directory.

## Business & Operations

Q: What are the common use cases?  
A: Gaming, DeFi, NFTs, social tipping, corporate expense flows, onboarding — any UX that benefits from gas abstraction.

Q: How much does it cost?  
A: Users consume gas credits equivalent to network gas. Relayers may charge fees. Costs depend on gas market rates and relayer policies.

## Support & Reporting

- GitHub Issues: for bugs and feature requests
- Security disclosure: follow the Security Disclosure page to report vulnerabilities
- Community channels: Discord / official forums
- Email: support@metatx-contracts.com

---

If your question is not answered here, search the docs, open a GitHub Issue with full reproduction details, or join community channels for help.

{% hint style="success" %}
**We're here to help!** The MetaTx-Contracts community is friendly and supportive. Don't hesitate to ask questions! 🤝
{% endhint %}
