# Aggchain Contract Roles

Roles in the aggchain contracts — deployed per-chain via `AgglayerManager`.

Source: [agglayer-contracts v12.2.2](https://github.com/agglayer/agglayer-contracts/releases/tag/v12.2.2)

---

## 1. AggchainBase

[Source](https://github.com/agglayer/agglayer-contracts/blob/v12.2.2/contracts/lib/AggchainBase.sol) · Base contract inherited by all aggchain types.

| Role | Type | Modifier | Functions Gated |
|------|------|----------|-----------------|
| `aggchainManager` | `address` | `onlyAggchainManager` | `updateSignersAndThreshold()`, `transferAggchainManagerRole()`, `enableUseDefaultVkeysFlag()`, `disableUseDefaultVkeysFlag()`, `enableUseDefaultSignersFlag()`, `disableUseDefaultSignersFlag()`, `addOwnedAggchainVKey()`, `updateOwnedAggchainVKey()`, `setAggchainMetadataManager()`, `initialize()` |
| `aggchainMetadataManager` | `address` | `onlyAggchainMetadataManager` | `setAggchainMetadata()`, `batchSetAggchainMetadata()` |
| `admin` | `address` (from `PolygonConsensusBase`) | `onlyAdmin` | `setTrustedSequencer()`, `setTrustedSequencerURL()`, `transferAdminRole()` |

All address-based roles use **two-step transfer** (propose + accept).

### aggchainManager

- **Functionality**: Primary admin of the aggchain. Controls verification keys, signer configuration, metadata manager, and all chain configuration.
- **Security**: Very High. Full control over chain's proof verification and multisig settings.
- **Recommended Account**: Timelock (per chain).

### aggchainMetadataManager

- **Functionality**: Can set/update metadata key-value pairs on the aggchain. Appointed by `aggchainManager`.
- **Security**: Low. Metadata is informational; does not affect consensus or security.
- **Recommended Account**: EOA or Multisig.

### admin

- **Functionality**: Legacy admin from `PolygonConsensusBase`. Controls trusted sequencer address and URL.
- **Security**: Medium. Changing the trusted sequencer affects who can sequence batches.
- **Recommended Account**: Multisig.

---

## 2. AggchainECDSAMultisig

[Source](https://github.com/agglayer/agglayer-contracts/blob/v12.2.2/contracts/aggchains/AggchainECDSAMultisig.sol)

Inherits **all roles from AggchainBase**. No additional roles.

Uses pessimistic proof + ECDSA multisig authorization.

| Role | Additional Functions Gated |
|------|---------------------------|
| `onlyAggchainManager` | `initialize()` |

---

## 3. AggchainFEP

[Source](https://github.com/agglayer/agglayer-contracts/blob/v12.2.2/contracts/aggchains/AggchainFEP.sol)

Inherits **all roles from AggchainBase** plus one additional role:

| Role | Type | Modifier | Functions Gated |
|------|------|----------|-----------------|
| `optimisticModeManager` | `address` | `onlyOptimisticModeManager` | `enableOptimisticMode()`, `disableOptimisticMode()`, `transferOptimisticModeManagerRole()` |

Additional functions gated by inherited roles:

| Role | Additional Functions Gated |
|------|---------------------------|
| `onlyAggchainManager` | `initialize()`, `initializeFromLegacyConsensus()`, `initializeFromECDSAMultisig()`, `addOpSuccinctConfig()`, `deleteOpSuccinctConfig()`, `selectOpSuccinctConfig()`, `updateSubmissionInterval()` |

### optimisticModeManager

- **Functionality**: Controls optimistic mode — an emergency bypass of state transition verification. When active, the trusted sequencer's signature suffices instead of a full proof.
- **Security**: Very High. Optimistic mode is an emergency fallback that weakens verification guarantees. A compromised optimistic mode manager could enable a malicious sequencer to post invalid state.
- **Recommended Account**: Multisig (needs fast response for emergencies, but high-risk enough to require multiple signers).

---

## Summary Table

| Contract | Role | Security Risk | Recommended Account |
|----------|------|---------------|---------------------|
| AggchainBase | `aggchainManager` | Very High | Timelock (per chain) |
| AggchainBase | `aggchainMetadataManager` | Low | EOA or Multisig |
| AggchainBase | `admin` | Medium | Multisig |
| AggchainFEP | `optimisticModeManager` | Very High | Multisig |
