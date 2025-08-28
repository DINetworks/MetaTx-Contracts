# GasCreditVault API Reference

Quick reference for GasCreditVault public interface and events (BSC deployment available).

## Purpose
- Manage deposits of ERC20 tokens that back internal "gas credits".
- Convert token deposits to gas-credit units (oracle-backed).
- Allow authorized relayers or systems to consume credits.

## Typical functions (public/external)

- depositTokens(address token, uint256 amount) external
  - Deposit ERC20 tokens to mint internal credit balance for msg.sender.

- withdrawTokens(address token, uint256 amount) external
  - Withdraw previously deposited tokens (reverses credits).

- getCreditBalance(address account) external view returns (uint256)
  - Returns internal credit units for account.

- consumeCredits(address account, uint256 creditAmount) external
  - Consume credits for gas payment (caller typically an authorized relayer or system).

## Events
- event Deposited(address indexed user, address indexed token, uint256 tokenAmount, uint256 creditsMinted)
- event Withdrawn(address indexed user, address indexed token, uint256 tokenAmount, uint256 creditsBurned)
- event CreditsConsumed(address indexed consumer, address indexed account, uint256 credits)
- event CreditTransfer(address indexed sender, address indexed receiver, uint256 creditAmount)

## Common error strings
- "Unsupported token"
- "Insufficient deposited balance"
- "Oracle not set"
- "Unauthorized"
- "Min deposit not met"
- "Transfer failed"

## Integration notes
- Credit calculus uses token price × token amount → native gas equivalent.
- Offchain systems should read CreditsDeposited/CreditsConsumed events to reconcile accounting.
- Use oracles (Chainlink recommended) for price feeds to reduce manipulation risk.
