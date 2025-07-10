# Changes v0.3.0 --> v0.3.1
## Motivation

The motivation behind these changes is to enable the upgrade of a zkEVM rollup to a pessimistic consensus rollup (PP).

Our goal has been to introduce this functionality with minimal modifications across all system components. To support this transition, we designed a migration mechanism that integrates smoothly into the current rollup architecture.

Specifically, we added a new function to initiate the migration process, and structured the system so that the migration is automatically finalized upon the successful verification of the first proof following the upgrade. This ensures consistency and security during the transition while maintaining alignment with existing rollup lifecycle flows.

## Sources

- New [TAG](https://github.com/agglayer/agglayer-contracts/releases/tag/v11.0.0-rc.2)
- Git diff [PR](https://github.com/agglayer/agglayer-contracts/pull/478/files)
- Git diff [v10.1.0-rc.5 - v11.0.0-rc.2](https://github.com/agglayer/agglayer-contracts/compare/v10.1.0-rc.5...v11.0.0-rc.2?diff=unified&w)

## Contract Updates for Migration to Pessimistic Proof (PP)

This update introduces a new version (`al-v0.3.1`) of the `PolygonRollupManager` contract, focusing on enabling rollup migrations from a state transition system to a pessimistic proof (PP) system. The following core updates were implemented:

This update (version `al-v0.3.1`) of the PolygonRollupManager contract includes extended functionality to support the migration of rollups from a standard state transition mechanism (ZK) to a pessimistic proof (PP) system. The following components and logic were added or updated to enable this capability:

### New Mapping and Events:

- `isRollupMigrating`: A new [mapping](https://github.com/agglayer/agglayer-contracts/blob/feature/zkEVMToPP/contracts/v2/PolygonRollupManager.sol#L322) has been added to keep track of rollups that are in the process of migrating.

- `InitMigration` and `CompletedMigration`: Two events are emitted to signal the [start](https://github.com/agglayer/agglayer-contracts/blob/feature/zkEVMToPP/contracts/v2/PolygonRollupManager.sol#L454) and [completion](https://github.com/agglayer/agglayer-contracts/blob/feature/zkEVMToPP/contracts/v2/PolygonRollupManager.sol#L460) of the migration flow, respectively.

```
    /**
     * @dev Emitted when `initMigration` is called
     * @param rollupID Rollup ID that is being migrated
     * @param newRollupTypeID New rollup type ID that the rollup will be migrated to
     */
    event InitMigration(uint32 indexed rollupID, uint32 newRollupTypeID);

    /**
     * @dev Emitted when a rollup completes the migration to Pessimistic or ALGateway, just after proving bootstrapped batch
     * @param rollupID Rollup ID that completed the migration
     */
    event CompletedMigration(uint32 indexed rollupID);  
```

### Flow migration

The migration flow can be found explained in this section: [flow migration](./Diagrams.md#migration-to-pp-or-algateway).

### New Error Conditions

- `NewRollupTypeMustBePessimisticOrALGateway`: [Thrown](https://github.com/agglayer/agglayer-contracts/blob/feature/zkEVMToPP/contracts/v2/PolygonRollupManager.sol#L974) when trying to migrate a rollup to a non pessimistic or ALGateway rollup type with `initMigration` function.
- `InvalidNewLocalExitRoot`: [Thrown](https://github.com/agglayer/agglayer-contracts/blob/feature/zkEVMToPP/contracts/v2/PolygonRollupManager.sol#L1324) when trying to finish a migration of a rollup to a pessimistic rollup type with `verifyPessimisticTrustedAggregator` function and the proposed new local exit root does not match the expected new local exit root.

### Remedations audit
- [Comment localExitRoot](https://github.com/agglayer/agglayer-contracts/commit/b0e950539c14d565868d9de2c3f40df0b65a443a): add new comment
- [Renamed legacy vars function rollupIDToRollupDataDeserialized](https://github.com/agglayer/agglayer-contracts/commit/1e0428374e4c7f62e11e008ffc63ea8ae8315a3b)
- [Unifying logic sequenced batches check](https://github.com/agglayer/agglayer-contracts/commit/9d8f9adc1a6d0228b44a78f1ca79a2f83ac7a5ec)

### Internal audit fixes
[Commit](https://github.com/agglayer/agglayer-contracts/commit/6db876c9a761d4b68a5fd142d73ceef5ee5b09e4) with follow changes:

- Typo in comment
- Update `reinitializer(4)` -> `reinitializer(5)`

### Check global index
It has been detected that a new check is necessary for the `globalIndex` to ensure that unused bits are set to 0.
[Commit](https://github.com/agglayer/agglayer-contracts/commit/0f134b48d11fafbeddd386e698d1e878478c0f2f) with new check for global index in internal function `_verifyLeaf`:

- If `globalIndex & _GLOBAL_INDEX_MAINNET_FLAG != 0` check all unused bits are 0 with:
```
require(
    _GLOBAL_INDEX_MAINNET_FLAG + uint256(leafIndex) == globalIndex,
    InvalidGlobalIndex()
);
```
- Else, check all unused bits bits are 0 with:
```
require(
    (uint256(indexRollup) << uint256(32)) + uint256(leafIndex) == globalIndex,
    InvalidGlobalIndex()
);
```
- Add new error for this check:
```
/**
 * @dev Thrown when the global index has any unused bits set to 1
*/
error InvalidGlobalIndex();
```

### Push Claim Event
[Commit](https://github.com/agglayer/agglayer-contracts/commit/81c511ef3914667eebc0f0f801829ce564645e07) with fix for reentrancy call:
Now, the event will occur before the call. This way, there won’t be an ordering error if there is reentrancy.

- Before:
```
- call function
- SC call reentrancy
- ClaimEvent
```
- Now:
```
- call function
- ClaimEvent
- SC call reentrancy
```

### Tools
- e2e [instructions](https://github.com/0xPolygonHermez/protocol-team-kanban/issues/604)
- [upgrade script](https://github.com/agglayer/agglayer-contracts/tree/feature/zkEVMToPP/upgrade/upgrade-rollupManager-v0.3.1)
- [migate SC call ](https://github.com/agglayer/agglayer-contracts/tree/feature/zkEVMToPP/tools/initMigration)