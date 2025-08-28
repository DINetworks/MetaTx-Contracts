# Voting and Delegation

Overview
- Voting power is represented by DI token holdings (ERC20Votes compatible).
- Holders may delegate voting power to other addresses.

Typical voting parameters
- Quorum: configurable (example: 5% of circulating supply)
- Passing threshold: simple majority of votes cast, unless otherwise specified
- Voting period: defined in proposal metadata

How to vote
- Use the governance UI or sign on-chain transactions to cast votes.
- Delegation: call `delegate` on DI token (ERC20Votes) to delegate power.

Off-chain coordination
- Proposals are usually discussed off-chain (forums, Discord) before submission.

