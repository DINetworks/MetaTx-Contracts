# Upgrade Strategies

This guide explains recommended upgrade strategies for UUPS upgradeable contracts used in this project.

## UUPS Pattern (used by MetaTxGateway)

- Implementation contract contains the logic and an _authorizeUpgrade function guarded by owner access.
- A minimal proxy (ERC1967) holds storage and delegates calls to the implementation.

## Best Practices

1. Access control for upgrades  
   - Only a secure multisig / DAO-controlled address should be owner and allowed to authorize upgrades.

2. Upgrade process
   - Write a migration script that:
     - Deploys new implementation.
     - Runs on-chain tests against a staging proxy (optional).
     - Calls the proxy upgrade via a signed multisig transaction.
   - Verify the new implementation on block explorers.

3. Backwards-compatible changes
   - Prefer additive changes (new functions, new storage at the end).
   - Avoid changing existing storage layout; if absolutely necessary, write careful migration logic.

4. Tests and gating
   - Unit and integration tests that exercise state migration.
   - Automated upgrade simulation (fork mainnet and test upgrade).
   - Manual review and security audit for any upgrade touching critical logic.

## Upgrade Safety Checklist

- Confirm _authorizeUpgrade is restricted to multisig/DAO.
- Validate storage layout (use tools like OpenZeppelin upgrades plugin).
- Run full test suite on a fork of the mainnet with real state, when applicable.
- Produce a migration script; include rollback strategy where possible.
- Announce upgrade windows and maintain monitoring during/after upgrade.

## Emergency Process

- Pause contract operations if the new implementation introduces issues.
- If multisig is compromised, follow governance emergency protocol (revoke compromised keys, rotate owners).

## Notes on Proxy Storage

- Use explicit storage gaps only when necessary and document any reserved slots.
- For safe storage changes: add new variables at the end of storage structs and test thoroughly.
