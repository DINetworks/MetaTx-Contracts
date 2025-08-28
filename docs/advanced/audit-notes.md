# Audit Notes & Security Checklist

This page outlines the security considerations, threat model and a checklist to prepare for formal audits.

## Threat model

- Malicious relayers attempting to steal funds or disrupt service.
- Compromised owner/multisig keys performing unauthorized upgrades.
- Target contracts called by meta-transactions may behave maliciously.
- Replay or signature misuse across chains.

## Key security controls implemented

- EIP-712 signatures with nonce and deadline checks.
- ReentrancyGuard on public execution paths.
- Pausable functionality with reason logging.
- Relayer authorization controlled by owner.
- UUPS upgrade pattern with owner-only authorization.

## Pre-audit checklist

- [ ] Run static analysis (Solhint, Slither).
- [ ] Run unit and integration tests, including forked mainnet scenarios.
- [ ] Validate storage layout compatibility for upgrades.
- [ ] Document expected invariants and assumptions (e.g., who holds funds, refund recipients).
- [ ] Produce threat model and attack scenarios.
- [ ] Prepare a changelog and rationale for design decisions.

## Audit focus areas

1. Signature verification & domain separation  
   - Ensure domain uses correct chainId and verifyingContract.
   - Confirm hashing of dynamic arrays (metaTxs) matches frontend signing logic.

2. Refund and ETH handling  
   - Verify no scenario where user funds can be stolen during refunds.
   - Confirm safe handling of call failures and that refunds go to the intended recipient.

3. Upgrade and access control  
   - Ensure only multisig/DAO can upgrade in production.
   - Validate pause/unpause race conditions.

4. External contract calls  
   - Consider adding call limits or whitelists for high-risk integrations.
   - Ensure try-catch and event logging for failed calls.

5. Edge cases & DoS vectors  
   - Maliciously large batches or reentrancy through target contracts.
   - Exhausting gas or reverting refunds.

## Post-audit actions

- Address findings and re-run tests.
- Publish audit report summary and remediation steps in docs.
- Implement monitoring and on-chain instrumentation to detect exploit attempts.

---

For formal audits, provide auditors with up-to-date contracts, deployment addresses, tests, and replication scripts.
