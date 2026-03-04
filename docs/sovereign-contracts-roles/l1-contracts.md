# L1 Core Contract Roles

Roles in the core L1 Agglayer contracts deployed on Ethereum mainnet.

Source: [agglayer-contracts v12.2.2](https://github.com/agglayer/agglayer-contracts/releases/tag/v12.2.2)

---

## 1. AgglayerManager

[Source](https://github.com/agglayer/agglayer-contracts/blob/v12.2.2/contracts/AgglayerManager.sol) · Mainnet: `0x5132A183E9F3CB7C848b0AAC5Ae0c4f0491B7aB2`

Uses `PolygonAccessControlUpgradeable` (OZ-style role-based access control with `onlyRole` modifier).

| Role | Keccak of | Functions Gated |
|------|-----------|-----------------|
| `DEFAULT_ADMIN_ROLE` | `0x00` | `grantRole()`, `revokeRole()` for all roles without explicit admin |
| `_ADD_ROLLUP_TYPE_ROLE` | `"ADD_ROLLUP_TYPE_ROLE"` | `addNewRollupType()` |
| `_OBSOLETE_ROLLUP_TYPE_ROLE` | `"OBSOLETE_ROLLUP_TYPE_ROLE"` | `obsoleteRollupType()` |
| `_CREATE_ROLLUP_ROLE` | `"CREATE_ROLLUP_ROLE"` | `attachAggchainToAL()` |
| `_ADD_EXISTING_ROLLUP_ROLE` | `"ADD_EXISTING_ROLLUP_ROLE"` | `addExistingRollup()` |
| `_UPDATE_ROLLUP_ROLE` | `"UPDATE_ROLLUP_ROLE"` | `updateRollup()`, `initMigration()`, `rollbackBatches()` |
| `_TRUSTED_AGGREGATOR_ROLE` | `"TRUSTED_AGGREGATOR_ROLE"` | `verifyBatchesTrustedAggregator()`, `verifyPessimisticTrustedAggregator()` |
| `_TRUSTED_AGGREGATOR_ROLE_ADMIN` | `"TRUSTED_AGGREGATOR_ROLE_ADMIN"` | Admin role for `_TRUSTED_AGGREGATOR_ROLE` |
| `_TWEAK_PARAMETERS_ROLE` | `"TWEAK_PARAMETERS_ROLE"` | Reserved (legacy, kept for storage compatibility) |
| `_SET_FEE_ROLE` | `"SET_FEE_ROLE"` | `setBatchFee()` |
| `_STOP_EMERGENCY_ROLE` | `"STOP_EMERGENCY_ROLE"` | `deactivateEmergencyState()` |
| `_EMERGENCY_COUNCIL_ROLE` | `"EMERGENCY_COUNCIL_ROLE"` | `activateEmergencyState()` (bypasses halt timeout) |
| `_EMERGENCY_COUNCIL_ADMIN` | `"EMERGENCY_COUNCIL_ADMIN"` | Admin role for `_EMERGENCY_COUNCIL_ROLE` |

### Role Details

#### DEFAULT_ADMIN_ROLE

- **Security**: Critical. Super-admin that can grant/revoke any role whose admin is `DEFAULT_ADMIN_ROLE`.
- **Recommended Account**: Timelock.

#### _ADD_ROLLUP_TYPE_ROLE

- **Functionality**: Register new rollup types (consensus implementations). Controls what chain types can be deployed.
- **Security**: High. Registering malicious rollup types could compromise new chains.
- **Recommended Account**: Timelock.

#### _OBSOLETE_ROLLUP_TYPE_ROLE

- **Functionality**: Mark rollup types as obsolete, preventing new chains from using them.
- **Security**: Medium. Cannot affect existing chains, only prevents new ones.
- **Recommended Account**: Timelock.

#### _CREATE_ROLLUP_ROLE

- **Functionality**: Deploy and register new chains/rollups. Creates proxy contracts and assigns chain IDs.
- **Security**: High. Controls chain onboarding.
- **Recommended Account**: Timelock.

#### _ADD_EXISTING_ROLLUP_ROLE

- **Functionality**: Add already-deployed rollup contracts without requiring a rollup type. Sets genesis/init state directly.
- **Security**: High. Can introduce arbitrary state for a chain.
- **Recommended Account**: Timelock.

#### _UPDATE_ROLLUP_ROLE

- **Functionality**:
    - Upgrade any rollup to a new type (`updateRollup()`)
    - Initiate ST→PP/ALGateway migrations (`initMigration()`)
    - Rollback batches (`rollbackBatches()` — also callable by chain admin)
- **Security**: Very High. Most powerful chain management role. Can change consensus logic for any chain.
- **Recommended Account**: Timelock.

#### _TRUSTED_AGGREGATOR_ROLE

- **Functionality**: Submit and verify batch proofs / pessimistic proofs. Controls state transitions for all chains.
- **Security**: Very High. Can finalize state for any chain.
- **Recommended Account**: Aggregator service (automated).

#### _SET_FEE_ROLE

- **Functionality**: Set the batch fee (POL cost per batch).
- **Security**: Medium. Financial parameter only.
- **Recommended Account**: Timelock.

#### _STOP_EMERGENCY_ROLE

- **Functionality**: Deactivate emergency state on both AgglayerManager and the bridge.
- **Security**: High. Resumes normal operations after emergency.
- **Recommended Account**: Timelock.

#### _EMERGENCY_COUNCIL_ROLE

- **Functionality**: Activate emergency state immediately, bypassing the halt aggregation timeout. Note: *anyone* can activate emergency state once the timeout expires — this role only bypasses the timeout.
- **Security**: High. Can halt all operations.
- **Recommended Account**: Emergency Council Multisig (fast response).

---

## 2. AgglayerGateway

[Source](https://github.com/agglayer/agglayer-contracts/blob/v12.2.2/contracts/AggLayerGateway.sol) · Mainnet: `0x046Bb8bb98Db4ceCbB2929542686B74b516274b3`

Uses OZ `AccessControlUpgradeable` (standard v5 role-based access control).

| Role | Keccak of | Functions Gated |
|------|-----------|-----------------|
| `DEFAULT_ADMIN_ROLE` | `0x00` | `grantRole()`, `revokeRole()` for all roles |
| `AGGCHAIN_DEFAULT_VKEY_ROLE` | `"AGGCHAIN_DEFAULT_VKEY_ROLE"` | `addDefaultAggchainVKey()`, `updateDefaultAggchainVKey()`, `unsetDefaultAggchainVKey()` |
| `AL_ADD_PP_ROUTE_ROLE` | `"AL_ADD_PP_ROUTE_ROLE"` | `addPessimisticVKeyRoute()` |
| `AL_FREEZE_PP_ROUTE_ROLE` | `"AL_FREEZE_PP_ROUTE_ROLE"` | `freezePessimisticVKeyRoute()` |
| `AL_MULTISIG_ROLE` | `"AL_MULTISIG_ROLE"` | `updateSignersAndThreshold()` |

### Role Details

#### AGGCHAIN_DEFAULT_VKEY_ROLE

- **Functionality**: Manage default aggchain verification keys used by chains with `useDefaultVkeys=true`.
- **Security**: High. Affects proof verification for chains using defaults.
- **Recommended Account**: Timelock.

#### AL_ADD_PP_ROUTE_ROLE

- **Functionality**: Add new pessimistic proof verification key routes (verifier + vkey combos). One-way: routes can be added but never removed, only frozen.
- **Security**: High. Routes cannot be reverted once added.
- **Recommended Account**: Timelock.

#### AL_FREEZE_PP_ROUTE_ROLE

- **Functionality**: Freeze PP verification key routes, permanently disabling a proof path. **Irreversible**.
- **Security**: Very High. Could DoS chains relying on a specific route.
- **Recommended Account**: Timelock.

#### AL_MULTISIG_ROLE

- **Functionality**: Manage the default multisig signers and threshold used by chains with `useDefaultSigners=true`.
- **Security**: High. Controls shared signer configuration.
- **Recommended Account**: Multisig.

---

## 3. AgglayerTimelock

[Source](https://github.com/agglayer/agglayer-contracts/blob/v12.2.2/contracts/AgglayerTimelock.sol) · Mainnet: `0xEf1462451C30Ea7aD8555386226059Fe837CA4EF`

Uses OZ v4 `TimelockController`. **Not upgradeable**.

| Role | Functions Gated |
|------|-----------------|
| `TIMELOCK_ADMIN_ROLE` | Manage timelock configuration (`updateDelay`) |
| `PROPOSER_ROLE` | Schedule (propose) operations |
| `CANCELLER_ROLE` | Cancel pending operations (auto-granted to proposers) |
| `EXECUTOR_ROLE` | Execute ready operations |

!!! warning
    When `AgglayerManager.isEmergencyState()` is true, `getMinDelay()` returns **0**, allowing immediate execution of all pending proposals. Mainnet `minDelay` is 3 days under normal conditions.

---

## 4. AgglayerBridge

[Source](https://github.com/agglayer/agglayer-contracts/blob/v12.2.2/contracts/AgglayerBridge.sol) · Mainnet: `0x2a3DD3EB832aF982ec71669E178424b10Dca2EDe`

No OZ AccessControl. Uses a custom single-address role pattern.

| Role | Type | Functions Gated |
|------|------|-----------------|
| `polygonRollupManager` | `address` (set at init, immutable after) | `activateEmergencyState()`, `deactivateEmergencyState()` |
| `proxiedTokensManager` | `address` (two-step transfer) | Admin of all `TokenWrappedTransparentProxy`, can upgrade wrapped token implementations |

- **Emergency state** (from `EmergencyManager`): pauses `bridgeAsset()`, `bridgeMessage()`, `bridgeMessageWETH()`, `claimAsset()`, `claimMessage()`.
- `proxiedTokensManager` is auto-set from the proxy's admin owner at initialization (typically the Timelock).

---

## 5. AgglayerGER

[Source](https://github.com/agglayer/agglayer-contracts/blob/v12.2.2/contracts/AgglayerGER.sol) · Mainnet: `0x580bda1e7A0CFAe92Fa7F6c20A3794F169CE3CFb`

No roles. Uses **immutable** address checks set at construction.

| Role | Type | Functions Gated |
|------|------|-----------------|
| `bridgeAddress` | `address immutable` | `updateExitRoot()` (mainnet exit root) |
| `rollupManager` | `address immutable` | `updateExitRoot()` (rollup exit root) |

Only these two addresses can call `updateExitRoot()`. All others revert with `OnlyAllowedContracts()`.
