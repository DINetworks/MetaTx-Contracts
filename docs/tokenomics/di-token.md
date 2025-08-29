# DI Token

The DI Token is the core utility and governance token of the ecosystem, designed to empower users, incentivize participation, and enable decentralized governance.

## What is DI Token?

DI Token is an ERC20-compliant digital asset that serves as the backbone of the platform. It is used for payments, rewards, staking, and voting on key decisions.

## Key Features

- **Utility:** Pay for services, access premium features, and participate in platform activities.
- **Governance:** Vote on proposals, protocol upgrades, and community initiatives.
- **Staking:** Lock DI Tokens to earn rewards and support network security.
- **Rewards:** Earn DI Tokens by contributing to the ecosystem, staking, or providing liquidity.

## Token Distribution

The total supply of DI Token is **1,000,000,000 DI**. The distribution is as follows:

| Allocation         | Amount (DI)      | Percentage |
|--------------------|------------------|------------|
| Presale            | 150,000,000      | 15%        |
| Marketing          | 100,000,000      | 10%        |
| KOL                | 50,000,000       | 5%         |
| Team               | 50,000,000       | 5%         |
| Treasury           | 150,000,000      | 15%        |
| Ecosystem          | 300,000,000      | 30%        |
| Staking            | 100,000,000      | 10%        |
| Liquidity          | 150,000,000      | 15%        |
| Airdrop            | 50,000,000       | 5%         |
| **Total**          | **1,000,000,000**| **100%**   |

**Notes:**
- "Ecosystem" includes allocations for growth, partnerships, and community incentives.
- "KOL" refers to Key Opinion Leaders and strategic partners.
- "Staking" is reserved for staking rewards.
- "Liquidity" is used to provide liquidity on exchanges.

## How to Get DI Token

1. **Participate in the Token Presale:** Buy DI Tokens during the presale event.
2. **Stake and Earn:** Stake your DI Tokens to earn additional tokens as rewards.
3. **Exchange:** After launch, DI Tokens may be available on supported exchanges.

## Governance

Holding DI Tokens gives you the right to participate in the platform’s governance:

- **Voting:** Propose and vote on changes, upgrades, and community initiatives.
- **Transparency:** All votes and proposals are recorded on-chain for full transparency.

## Staking

- **Earn Rewards:** Stake DI Tokens to receive regular rewards.
- **Flexible Terms:** Choose how much and how long to stake.
- **Unstaking:** Withdraw your tokens and rewards at any time (subject to lock periods, if any).

## Security

- **ERC20 Standard:** Built on audited, industry-standard smart contracts.
- **Non-custodial:** You always control your tokens in your own wallet.
- **Transparency:** All transactions and token movements are visible on the blockchain.

## Frequently Asked Questions

**Q: What can I do with DI Tokens?**  
A: Use them for payments, staking, voting, and accessing exclusive features.

**Q: How do I participate in governance?**  
A: Hold DI Tokens and use the governance portal to vote on proposals.

**Q: Are there any risks?**  
A: As with any digital asset, token values can fluctuate. Only stake or purchase what you are comfortable with.

## Technical Reference

```solidity
function mint(address to, uint256 amount) external onlyOwner;
function burn(uint256 amount) external;
function totalSupply() external view returns (uint256);
function balanceOf(address account) external view returns (uint256);
```

## Deployed Addresses (BNB Smart Chain)

| Contract Name     | Address                                      |
|-------------------|----------------------------------------------|
| DI Token          | 0xBE13AaeCf1f68f4AC7e94391ABC29747De51BBDC   |
| DIVote            | 0x397629bBFbaE39c9fe1aF62347aF8fd7278BB2cb   |
| TokenAirdrop      | 0x5f1DE17f53aDe921C8832D0Fa28F06C13dfc3d16   |
| TokenPresale      | 0x925c5175331ba07c8F91234C0214348fEC8A248A   |
| TokenStaking      | 0x5cE964707AaBf798998EE357bC077B70DDf6D3cA   |

## Learn More

- [Token Presale](../../tokenomics/token-presale.md)
- [Token Staking](../../tokenomics/token-staking.md)
- [Governance Guide](../../guides/governance.md)
