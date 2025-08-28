# Glossary

Meta-transaction (MetaTx) — A signed instruction allowing a relayer to execute a transaction on a user's behalf.  
Relayer — A service or address that submits user-signed meta-transactions and pays gas.  
EIP-712 — Ethereum typed structured data signing standard used for secure signatures.  
Domain Separator — EIP-712 domain hash including name, version, chainId and contract address.  
Gas credit — Off-chain or on-chain mechanism for paying relayer fees via credits/tokens.  
DI Token — Platform ERC20 token used for governance, staking, and rewards.  
Nonce — Replay protection counter per user in MetaTxGateway.  
UUPS — Upgradeable proxy pattern used for safe contract upgrades.  
ReentrancyGuard — Protection against reentrancy attacks.  
Batch — An array of MetaTransaction executed in a single call.

---

**Note**: This glossary covers terms specific to MetaTx-Contracts and general blockchain development. For more detailed explanations of any term, refer to the relevant sections in this documentation or the external resources mentioned above.

**Last Updated**: Aug 2025  
**Version**: 1.0.0

For suggestions or corrections to this glossary, please open an issue on our [GitHub repository](https://github.com/DINetworks/MetaTx-Contracts/issues) or contact us at docs@metatx-contracts.com.
The ability to execute multiple transactions atomically in a single blockchain transaction. MetaTx-Contracts supports batching up to 10 meta-transactions.

### BSC (Binance Smart Chain)
A blockchain network compatible with Ethereum that offers faster transactions and lower fees. Currently the primary supported network for MetaTx-Contracts.

### BNB
The native cryptocurrency of Binance Smart Chain, used for paying transaction fees and as a store of value.

## C

### Chainlink
A decentralized oracle network that provides real-world data to smart contracts. Used by MetaTx-Contracts for getting token price feeds.

### Circuit Breaker
A safety mechanism that automatically pauses operations when abnormal conditions are detected, such as extreme price movements or technical failures.

### Contract Verification
The process of publishing smart contract source code on block explorers (like BSCScan) to prove that the deployed bytecode matches the claimed source code.

### Credit
Internal accounting units in the GasCreditVault that represent prepaid gas fees. Credits are backed by real tokens and can be transferred between accounts.

## D

### Deadline
A timestamp that specifies when a meta-transaction expires. Transactions cannot be executed after their deadline, preventing stale transaction execution.

### Domain Separator
A unique identifier used in EIP-712 signatures that prevents signature replay attacks across different contracts or networks.

### DApp (Decentralized Application)
An application that runs on a blockchain network, typically involving smart contracts and a user interface.

## E

### EIP-712
An Ethereum Improvement Proposal that standardizes the signing of structured data, providing better security and user experience for meta-transactions.

### EOA (Externally Owned Account)
A regular Ethereum account controlled by a private key, as opposed to a smart contract account.

### Event
A log entry emitted by smart contracts that can be monitored by external applications. MetaTx-Contracts emits events for transaction execution, credit usage, and other important operations.

### Ethers.js
A popular JavaScript library for interacting with Ethereum and EVM-compatible blockchains.

## F

### Frontend Integration
The process of connecting a user interface (web or mobile app) to the MetaTx-Contracts system for submitting meta-transactions.

### Fuzzing
A testing technique that involves providing random or malformed inputs to find bugs and vulnerabilities in smart contracts.

## G

### Gas
The unit of computation used on Ethereum and compatible networks. Users must pay gas fees to execute transactions.

### Gas Credits
Prepaid units in the MetaTx-Contracts system that allow users to pay for transaction fees using supported ERC-20 tokens instead of native tokens.

### Gas Limit
The maximum amount of gas that a transaction is allowed to consume. If a transaction requires more gas than the limit, it will fail.

### Gas Price
The price per unit of gas, typically measured in gwei (10^-9 ETH). Higher gas prices result in faster transaction confirmation.

### Gwei
A denomination of ETH equal to 10^-9 ETH, commonly used to express gas prices.

## H

### Hardware Wallet
A physical device that securely stores private keys offline, providing enhanced security for cryptocurrency and smart contract interactions.

### Hardhat
A development environment for Ethereum software, used for compiling, testing, and deploying smart contracts.

## I

### Implementation Contract
In the proxy pattern, the implementation contract contains the actual business logic, while the proxy contract delegates calls to it.

### Initializer
A function in upgradeable contracts that serves as the constructor replacement, since constructors can't be used with proxies.

## L

### Low-level Call
A Solidity function that allows calling other contracts with arbitrary data, providing more control but requiring careful error handling.

## M

### Meta-transaction
A transaction that is signed by a user but submitted and paid for by a third party (relayer), enabling gasless interactions for users.

### MetaMask
A popular browser extension wallet that allows users to interact with Ethereum and compatible blockchain networks.

### Multi-signature (Multi-sig)
A security mechanism that requires multiple signatures to execute certain operations, reducing the risk of single points of failure.

## N

### Native Token
The cryptocurrency that is native to a blockchain network (e.g., ETH on Ethereum, BNB on BSC), used for paying transaction fees.

### NatSpec
Natural Language Specification format for documenting Solidity smart contracts, providing standardized documentation comments.

### Nonce
A number that ensures transaction uniqueness and prevents replay attacks. Each user has an incrementing nonce for meta-transactions.

## O

### Oracle
A service that provides external data to smart contracts. MetaTx-Contracts uses Chainlink oracles for token price feeds.

### OpenZeppelin
A library of secure, community-audited smart contract components and tools for blockchain development.

## P

### Payable
A Solidity function modifier that allows the function to receive native tokens (ETH/BNB) as part of the transaction.

### Price Feed
A data source that provides real-time price information for tokens, typically delivered through oracle networks like Chainlink.

### Proxy Pattern
A design pattern that allows smart contracts to be upgraded by separating the contract logic (implementation) from the contract storage (proxy).

### Private Key
A secret cryptographic key that controls ownership of a blockchain account and is used to sign transactions.

## Q

### Query
A read operation that retrieves data from smart contracts without modifying the blockchain state.

## R

### Reentrancy
A vulnerability where a contract calls back into itself before the first execution is complete, potentially leading to unexpected behavior.

### Relayer
A service that submits meta-transactions to the blockchain on behalf of users, paying the gas fees and potentially charging a service fee.

### Replay Attack
An attack where a valid transaction signature is reused maliciously. Prevented by nonces and domain separators in MetaTx-Contracts.

### RPC (Remote Procedure Call)
A protocol that allows applications to communicate with blockchain nodes, used for sending transactions and querying data.

## S

### SDK (Software Development Kit)
A set of tools, libraries, and documentation that helps developers integrate MetaTx-Contracts into their applications.

### Signature
A cryptographic proof that a transaction was authorized by the holder of a private key, created using elliptic curve cryptography.

### Smart Contract
A self-executing program on a blockchain that automatically enforces the terms of an agreement without intermediaries.

### Solidity
The primary programming language for writing smart contracts on Ethereum and compatible networks.

### Staleness
The condition when oracle price data becomes outdated, potentially leading to inaccurate calculations. MetaTx-Contracts checks for stale prices.

## T

### Testnet
A blockchain network used for testing purposes, where tokens have no real value but functionality mirrors the mainnet.

### Transaction Hash (TxHash)
A unique identifier for a blockchain transaction, used to track and verify transaction status.

### TypeScript
A strongly-typed programming language that builds on JavaScript, providing better development tools and error checking.

## U

### UUPS (Universal Upgradeable Proxy Standard)
An upgradeable proxy pattern where the upgrade functionality is in the implementation contract rather than the proxy.

### User Agent
Information about the client software (browser, app) making a request, used for analytics and debugging.

## V

### Vault
In MetaTx-Contracts, refers to the GasCreditVault contract that manages gas credits and token deposits.

### Verification
The process of confirming that deployed smart contract bytecode matches the published source code.

## W

### Wallet
Software or hardware that manages private keys and enables users to interact with blockchain networks.

### Web3
The decentralized web built on blockchain technology, enabling peer-to-peer interactions without intermediaries.

### Wei
The smallest denomination of ETH, equal to 10^-18 ETH. Used for precise calculations in smart contracts.

## Abbreviations and Acronyms

### Technical Terms
- **ABI**: Application Binary Interface
- **API**: Application Programming Interface
- **BSC**: Binance Smart Chain
- **CLI**: Command Line Interface
- **DApp**: Decentralized Application
- **DEX**: Decentralized Exchange
- **EIP**: Ethereum Improvement Proposal
- **EOA**: Externally Owned Account
- **ERC**: Ethereum Request for Comments
- **EVM**: Ethereum Virtual Machine
- **JSON**: JavaScript Object Notation
- **NFT**: Non-Fungible Token
- **RPC**: Remote Procedure Call
- **SDK**: Software Development Kit
- **TPS**: Transactions Per Second
- **UI**: User Interface
- **UUPS**: Universal Upgradeable Proxy Standard

### Tokens and Currencies
- **BNB**: Build and Build (Binance Coin)
- **BUSD**: Binance USD
- **ETH**: Ether
- **USDC**: USD Coin
- **USDT**: Tether USD

### Organizations and Standards
- **BSC**: Binance Smart Chain
- **OpenZeppelin**: Smart contract security framework
- **Chainlink**: Decentralized oracle network
- **EIP**: Ethereum Improvement Proposal
- **ERC**: Ethereum Request for Comments

## Code Examples

### Common Patterns

**Basic Meta-transaction Structure**
```javascript
const transaction = {
  to: "0x...",           // Target address
  value: "0",            // ETH value in wei
  data: "0x...",         // Call data
  nonce: "1",            // User nonce
  deadline: "1640995200" // Unix timestamp
};
```

**EIP-712 Domain**
```javascript
const domain = {
  name: "MetaTxGateway",
  version: "2.0.0",
  chainId: 56,
  verifyingContract: "0x..."
};
```

**Gas Credit Deposit**
```javascript
// Approve tokens first
await token.approve(vaultAddress, amount);

// Deposit for credits
await vault.depositCredits(tokenAddress, amount);
```

## Related Resources

### External Documentation
- **Ethereum Yellow Paper**: Technical specification of Ethereum
- **EIP-712 Specification**: Structured data signing standard
- **OpenZeppelin Docs**: Smart contract development guides
- **Chainlink Docs**: Oracle integration documentation
- **Hardhat Docs**: Development environment documentation

### Standards and Specifications
- **ERC-20**: Fungible token standard
- **ERC-721**: Non-fungible token standard
- **EIP-712**: Structured data signing
- **EIP-1967**: Proxy storage slots
- **EIP-2612**: Permit (gasless approvals)

### Tools and Libraries
- **Ethers.js**: Ethereum JavaScript library
- **Web3.js**: Alternative Ethereum JavaScript library
- **MetaMask**: Browser wallet extension
- **Remix**: Online Solidity IDE
- **Truffle**: Development framework

---

**Note**: This glossary covers terms specific to MetaTx-Contracts and general blockchain development. For more detailed explanations of any term, refer to the relevant sections in this documentation or the external resources mentioned above.

**Last Updated**: December 2024  
**Version**: 2.0.0

For suggestions or corrections to this glossary, please open an issue on our [GitHub repository](https://github.com/DINetworks/MetaTx-Contracts/issues) or contact us at docs@metatx-contracts.com.
