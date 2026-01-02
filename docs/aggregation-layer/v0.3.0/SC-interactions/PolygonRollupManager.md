# PolygonRollupManager

Contract responsible for managing rollups and the verification of their batches.
This contract will create and update rollups and store all the hashed sequenced data from them.
The logic for sequence batches is moved to the `consensus` contracts, while the verification of all of them will be done in this one. In this way, the proof aggregation of the rollups will be easier on a close future.

## 1. Interactions & Usage

### 1.1. addNewRollupType

Function to add a new rollup type.

Parameters:
```
@param consensusImplementation Consensus implementation
@param verifier Verifier address
@param forkID ForkID of the verifier
@param rollupVerifierType rollup verifier type
@param genesis Genesis block of the rollup
@param description Description of the rollup type
@param programVKey Hashed program that will be executed in case of using a "general purpose ZK verifier" e.g SP1
```

Events:
```
event AddNewRollupType(
    uint32 indexed rollupTypeID,
    address consensusImplementation,
    address verifier,
    uint64 forkID,
    VerifierType rollupVerifierType,
    bytes32 genesis,
    string description,
    bytes32 programVKey
);
```

Errors:

- Invalid Rollup type parameters:
```
error InvalidRollupType();
```

### 1.2. obsoleteRollupType

Function to obsolete Rollup type.

Parameters:
```
@param rollupTypeID Rollup type to obsolete
```

Events:
```
event ObsoleteRollupType(uint32 indexed rollupTypeID);
```

Errors:

- When a rollup type does not exist:
```
error RollupTypeDoesNotExist();
```

- When a rollup type is obsoleted:
```
error RollupTypeObsolete();
```


### 1.3. attachAggchainToAL

Function to create a new rollup.

Parameters:
```
@param rollupTypeID Rollup type to deploy
@param chainID ChainID of the rollup, must be a new one, can not have more than 32 bits
@param initializeBytesAggchain Encoded params to initialize the chain. Each aggchain has its encoded params.
@dev in case of rollupType state transition or pessimistic, the encoded params are the following: (address admin, address sequencer, address gasTokenAddress, string sequencerURL, string networkName)
```

Events:

- Emitted when a new rollup is created based on a rollupType
```
event CreateNewAggchain(
    uint32 indexed rollupID,
    uint32 rollupTypeID,
    address rollupAddress,
    uint64 chainID,
    uint8 rollupVerifierType,
    bytes initializeBytesAggchain
)
```

- Emitted when a new rollup is created based on a rollupType
```
event CreateNewRollup(
    uint32 indexed rollupID,
    uint32 rollupTypeID,
    address rollupAddress,
    uint64 chainID,
    address gasTokenAddress
)
```

Errors:

- When a rollup type does not exist:
```
error RollupTypeDoesNotExist();
```

- When a rollup type is obsoleted:
```
error RollupTypeObsolete();
```

- When try to create a new rollup and set a chainID bigger than 32 bits:
```
error ChainIDOutOfRange();
```

- Thrown when the caller is not the pending admin:
```
error ChainIDAlreadyExist();
```

### 1.4. addExistingRollup

Function to add an already deployed rollup-

Parameters:
```
@param rollupAddress Rollup address
@param verifier Verifier address, must be added before
@param forkID Fork id of the added rollup
@param chainID Chain id of the added rollup
@param initRoot Genesis block for StateTransitionChains & localExitRoot for pessimistic chain
@param rollupVerifierType Compatibility ID for the added rollup
@param programVKey Hashed program that will be executed in case of using a "general purpose ZK verifier" e.g SP1
@param initPessimisticRoot Pessimistic root to init the chain.
```

Events:
```
event AddExistingRollup(
    uint32 indexed rollupID,
    uint64 forkID,
    address rollupAddress,
    uint64 chainID,
    VerifierType rollupVerifierType,
    uint64 lastVerifiedBatchBeforeUpgrade,
    bytes32 programVKey,
    bytes32 initPessimisticRoot
)
```

Errors:

- Thrown when chainID already exist:
```
error ChainIDAlreadyExist();
```

- When try to create a new rollup and set a chainID bigger than 32 bits:
```
error ChainIDOutOfRange();
```

- When adding an existing rollup where the rollup address already was added
```
error RollupAddressAlreadyExist();
```

- Thrown when trying to create a rollup but the input parameters are not  according with the chosen rollupType
```
error InvalidInputsForRollupType();
```

### 1.5. updateRollupByRollupAdmin

Function to Upgrade an existing rollup from the rollup admin address.
This address is able to update the rollup with more restrictions that the _UPDATE_ROLLUP_ROLE.

Parameters:
```
@param rollupContract Rollup consensus proxy address
@param newRollupTypeID New rollupTypeID to upgrade to
```

Events:
```
event UpdateRollup(
    uint32 indexed rollupID,
    uint32 newRollupTypeID,
    uint64 lastVerifiedBatchBeforeUpgrade
);
```

Errors:

- When try to upgrade a rollup a sender that's not the admin of the rollup
```
error OnlyRollupAdmin();
```

- When try to update a rollup with sequences pending to verify
```
error AllSequencedMustBeVerified();
```

- Update to old rollup ID:
```
error UpdateToOldRollupTypeID();
```

- When update to not compatible rollup type:
```
error UpdateNotCompatible();
```

- When a rollup type does not exist:
```
error RollupTypeDoesNotExist();
```

- When rollup does not exist:
```
error RollupMustExist();
```

- When old rollupTypeID is newRollupTypeID
```
error UpdateToSameRollupTypeID();
```

- When a rollup type is obsoleted:
```
error RollupTypeObsolete();
```

### 1.6. updateRollup

Function to upgrade an existing rollup.

Parameters:
```
@param rollupContract Rollup consensus proxy address
@param newRollupTypeID New rollupTypeID to upgrade to
@param upgradeData Upgrade data
```

Events:
```
event UpdateRollup(
    uint32 indexed rollupID,
    uint32 newRollupTypeID,
    uint64 lastVerifiedBatchBeforeUpgrade
);
```

Errors:
- When a rollup type does not exist:
```
error RollupTypeDoesNotExist();
```

- When rollup does not exist:
```
error RollupMustExist();
```

- When old rollupTypeID is newRollupTypeID
```
error UpdateToSameRollupTypeID();
```

- When a rollup type is obsoleted:
```
error RollupTypeObsolete();
```

-  When update to not compatible rollup type
```
error UpdateNotCompatible();
```

### 1.7. initMigration
Function to init migration to PP or ALGateway.

Parameters:
```
@param rollupID Rollup ID that is being migrated
@param newRollupTypeID New rollup type ID that the rollup will be migrated to
@param upgradeData Upgrade data
```

Events:
```
event InitMigration(
    uint32 indexed rollupID,
    uint32 newRollupTypeID
);
```

Errors:

- Only for StateTransition chains:
```
error OnlyStateTransitionChains();
```

- No pending batches to verify allowed before migration:
```
error AllSequencedMustBeVerified();
```

- NewRollupType must be pessimistic or ALGateway:
```
error NewRollupTypeMustBePessimisticOrALGateway();
```

### 1.8. rollbackBatches

Function to batches of the target rollup (Only applies to state transition rollups).

Parameters:
```
@param rollupContract Rollup consensus proxy address
@param targetBatch Batch to rollback up to but not including this batch
```

Events:
```
event RollbackBatches(
    uint32 indexed rollupID,
    uint64 indexed targetBatch,
    bytes32 accInputHashToRollback
);
```

Errors:

- `rollbackBatches` is called from a non authorized address:
```
error NotAllowedAddress();
```

- Thrown when rollup does not exist:
```
error RollupMustExist();
```

- When rollup isn't state transition type:
```
error OnlyStateTransitionChains();
```

- Rollback batch is not sequenced:
```
error RollbackBatchIsNotValid();
```

- Rollback batch is not the end of any sequence
```
error RollbackBatchIsNotEndOfSequence();
```

### 1.9. onSequenceBatches

Function to sequence batches, callback called by one of the consensus managed by this contract.

Parameters:
```
@param newSequencedBatches Number of batches sequenced
@param newAccInputHash New accumulate input hash
```

Events:
```
event OnSequenceBatches(
    uint32 indexed rollupID,
    uint64 lastBatchSequenced
);
```

Errors:

- Thrown when sender isn't a rollup
```
error SenderMustBeRollup();
```

- Thrown when `newSequencedBatches` = 0
```
error MustSequenceSomeBatch();
```

- When rollup isn't state transition type:
```
error OnlyStateTransitionChains();
```


### 1.10. verifyBatchesTrustedAggregator

Allows a trusted aggregator to verify multiple batches-

Parameters:
```
@param rollupID Rollup identifier
@param pendingStateNum Init pending state, 0 if consolidated state is used (deprecated)
@param initNumBatch Batch which the aggregator starts the verification
@param finalNewBatch Last batch aggregator intends to verify
@param newLocalExitRoot New local exit root once the batch is processed
@param newStateRoot New State root once the batch is processed
@param beneficiary Address that will receive the verification reward
@param proof Fflonk proof
```

Events:
```
event VerifyBatchesTrustedAggregator(
    uint32 indexed rollupID,
    uint64 numBatch,
    bytes32 stateRoot,
    bytes32 exitRoot,
    address indexed aggregator
)
```

Errors:

- Pending state num exist:
```
error PendingStateNumExist();
```

- When rollup isn't state transition type:
```
error OnlyStateTransitionChains();
```

- When initNumBatch is lower than last verified batch before upgrade:
```
error InitBatchMustMatchCurrentForkID();
```

- Thrown when the old state root of a certain batch does not exist:
```
error OldStateRootDoesNotExist();
```

- Thrown when the init verification batch is above the last verification batch:
```
error InitNumBatchAboveLastVerifiedBatch();
```

- Thrown when the final verification batch is below or equal the last verification batch:
```
error FinalNumBatchBelowLastVerifiedBatch();
```

- Thrown when the old accumulate input hash does not exist:
```
error OldAccInputHashDoesNotExist();
```

- Thrown when the new accumulate input hash does not exist:
```
error NewAccInputHashDoesNotExist();
```

- Thrown when the new state root is not inside prime:
```
error NewStateRootNotInsidePrime();
```

### 1.11. verifyPessimisticTrustedAggregator

Allows a trusted aggregator to verify pessimistic proof.

Parameters:
```
@param rollupID Rollup identifier
@param l1InfoTreeLeafCount Count of the L1InfoTree leaf that will be used to verify imported bridge exits
@param newLocalExitRoot New local exit root
@param newPessimisticRoot New pessimistic information, Hash(localBalanceTreeRoot, nullifierTreeRoot)
@param proof SP1 proof (Plonk)
@param aggchainData Specific custom data to verify Aggregation layer chains
```

Events:

```
event VerifyBatchesTrustedAggregator(
    uint32 indexed rollupID,
    uint64 numBatch,
    bytes32 stateRoot,
    bytes32 exitRoot,
    address indexed aggregator
);

event VerifyPessimisticStateTransition(
    uint32 indexed rollupID,
    bytes32 prevPessimisticRoot,
    bytes32 newPessimisticRoot,
    bytes32 prevLocalExitRoot,
    bytes32 newLocalExitRoot,
    bytes32 l1InfoRoot,
    address indexed trustedAggregator
);
```

- If it's a migration:
```
event CompletedMigration(uint32 indexed rollupID);
```

Errors:

-  Thrown when a function is executed for a State transition chains when it is not allowed:
```
error StateTransitionChainsNotAllowed();
```

- Custom chain data must be zero for pessimistic verifier type:
```
error AggchainDataMustBeZeroForPessimisticVerifierType();
```

- Not valid L1 info tree leaf count:
```
error L1InfoTreeLeafCountInvalid();
```

- If it's a migration, it's a hard requirement that the newLocalExitRoot matches the current lastLocalExitRoot meaning that the certificates covers all the bridges:
```
error InvalidNewLocalExitRoot();
```

### 1.12. activateEmergencyState

Function to activate emergency state, which also enables the emergency mode on both PolygonRollupManager and PolygonZkEVMBridge contracts.

Events:
```
emit EmergencyStateActivated();
```

Errors:

- Thrown when the halt timeout is not expired when attempting to activate the emergency state:
```
error HaltTimeoutNotExpired();
```

- Only allows a function to be callable if emergency state is unactive:
```
error OnlyNotEmergencyState();
```

### 1.13. deactivateEmergencyState

Function to deactivate emergency state on both PolygonRollupManager and PolygonZkEVMBridge contracts.

Events:
```
emit EmergencyStateDeactivated();
```

Errors:

- Only allows a function to be callable if emergency state is active:
```
error OnlyEmergencyState();
```

### 1.14. setBatchFee

Function to set the current batch fee.

Parameters:
```
@param newBatchFee new batch fee
```

Events:
```
emit SetBatchFee(newBatchFee);
```

Errors:

- When batch fee isn't within the limits:
```
error BatchFeeOutOfRange();
```

### 1.15. Getters

- getRollupExitRoot
- getLastVerifiedBatch
- calculateRewardPerBatch
- getBatchFee
- getForcedBatchFee
- getInputPessimisticBytes
- getInputSnarkBytes
- getRollupBatchNumToStateRoot
- getRollupSequencedBatches
- rollupIDToRollupData
- rollupIDToRollupDataDeserialized
- rollupIDToRollupDataV2
- rollupIDToRollupDataV2Deserialized


## 2. Tooling available

### 2.1. addRollupType

[Tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/addRollupType) to add new rollup type.

### 2.2. createNewRollup

[Tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/createNewRollup) to create new rollup.

### 2.3. getRollupData

[Tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/getRollupData) to get rollup data.

### 2.4. updateRollup

[Tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/updateRollup) to update rollup.
