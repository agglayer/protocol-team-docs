# Aggchain FEP

## 1. Interactions & Usage

The definition can be found [here](../SC-specs.md#52-fep).

### 1.1. Initialize AggchainFEP

To initialize the aggchain, it is necessary to differentiate according to the `initializerVersion`:

- `initializeBytesAggchain` if `_initializerVersion == 0`:
```
 // chain custom params
InitParams memory _initParams
// aggchainBase params
bool _useDefaultGateway
bytes32 _initOwnedAggchainVKey
bytes2 _initAggchainVKeyVersion
address _vKeyManager
// PolygonConsensusBase params
address _admin
address _trustedSequencer
address _gasTokenAddress
string memory _trustedSequencerURL
string memory _networkName
```

- `initializeBytesAggchain` if `_initializerVersion == 1`:
```
// chain custom params
InitParams memory _initParams,
// aggchainBase params
bool _useDefaultGateway,
bytes32 _initOwnedAggchainVKey,
bytes2 _initAggchainVKeyVersion,
address _vKeyManager
```

### 1.2. View functions
#### 1.2.1. getAggchainHash
Function to get resulting aggchain hash.

Parameters:
```
@param aggchainData custom bytes provided by the chain

    aggchainData:
        Field:           | _aggchainVKeyVersion | _outputRoot  | _l2BlockNumber |
        length (bits):   | 16                   | 256          | 256            |
    
    aggchainData._aggchainVKeyVersion First 2 bytes of the aggchain vkey selector
    aggchainData._outputRoot Proposed new output root
    aggchainData._l2BlockNumber Proposed new l2 bock number
```

#### 1.2.2. SUBMISSION_INTERVAL
Getter for the submissionInterval.
#### 1.2.3. L2_BLOCK_TIME
Getter for the l2BlockTime.
#### 1.2.4. getL2Output
Returns an output by index. Needed to return a struct instead of a tuple.
#### 1.2.5. latestOutputIndex
Returns the number of outputs that have been proposed.
Will revert if no outputs have been proposed yet.
#### 1.2.6. nextOutputIndex
Returns the index of the next output to be proposed.
#### 1.2.7. latestBlockNumber
Returns the block number of the latest submitted L2 output proposal.
If no proposals been submitted yet then this function will return the starting block number.
#### 1.2.8. nextBlockNumber
Computes the block number of the next L2 block that needs to be checkpointed.
#### 1.2.9. computeL2Timestamp
Returns the L2 timestamp corresponding to a given L2 block number.

Parameters:
```
@param _l2BlockNumber The L2 block number of the target block.
```

### 1.3. onVerifyPessimistic
Callback when pessimistic proof is verified, can only be called by the rollup manager stores the necessary chain data when the pessimistic proof is verified.

Parameters:
```
@param aggchainData Custom data provided by the chain
```

Events:
```
emit OutputProposed(outputRoot, l2OutputIndex, l2BlockNumber, l1Timestamp);
```

### 1.4. updateSubmissionInterval
Function to update the submission interval.

Parameters:
```
@param _submissionInterval The new submission interval
```

Events:
```
@param oldSubmissionInterval The old submission interval.
@param newSubmissionInterval The new submission interval.

event SubmissionIntervalUpdated(uint256 oldSubmissionInterval, uint256 newSubmissionInterval)
```

Errors:

- Thrown when new submission interval is 0:
```
error SubmissionIntervalMustBeGreaterThanZero()
```


### 1.5. updateAggregationVkey
Function to update the aggregation verification key.

Parameters:
```
@param _aggregationVkey The new aggregation verification key.
```

Events:
```
@param oldAggregationVkey The old aggregation verification key.
@param newAggregationVkey The new aggregation verification key.

event AggregationVkeyUpdated(
    bytes32 indexed oldAggregationVkey,
    bytes32 indexed newAggregationVkey
);
```

Errors:

- Thrown when new aggregationVKey is 0:
```
error AggregationVkeyMustBeDifferentThanZero();
```

### 1.6. updateRangeVkeyCommitment
Function to update the range verification key commitment.

Parameters:
```
@param _rangeVkeyCommitment The new range verification key commitment
```

Events:
```
@param oldRangeVkeyCommitment The old range verification key commitment.
@param newRangeVkeyCommitment The new range verification key commitment.
event RangeVkeyCommitmentUpdated(
    bytes32 indexed oldRangeVkeyCommitment,
    bytes32 indexed newRangeVkeyCommitment
);
```

Errors:

- Thrown when new rangeVkey commitment is 0:
```
error RangeVkeyCommitmentMustBeDifferentThanZero();
```

### 1.7. updateRollupConfigHash
Function to update the rollup config hash.

Parameters:
```
@param _rollupConfigHash The new rollup config hash
```

Events:
```
@param oldRollupConfigHash The old rollup config hash.
@param newRollupConfigHash The new rollup config hash.

event RollupConfigHashUpdated(
    bytes32 indexed oldRollupConfigHash,
    bytes32 indexed newRollupConfigHash
) 
```

Errors:

- Thrown when rollup config hash is 0
```
error RollupConfigHashMustBeDifferentThanZero();
```

### 1.8. enableOptimisticMode/disableOptimisticMode
Functions to enable or disable optimistic mode.

- `enableOptimisticMode`:

    - Events:
```
event EnableOptimisticMode(); 
```

    - Error:
    
        If optimistic mode is enabled
```
error OptimisticModeEnabled();
```

- `disableOptimisticMode`:

    - Events:
```
event DisableOptimisticMode();
```

    - Error:

        If optimistic mode is not enabled
```
error OptimisticModeNotEnabled();
```

### 1.9. transferAggchainManagerRole/acceptAggchainManagerRole

Functions to transfer and accept aggchain manager role. 

- `transferAggchainManagerRole`:

    Starts the aggchainManager role transfer. This is a two step process, the pending aggchainManager must accept to finalize the process.

    - Parameters:
```
@param newAggchainManager Address of the new aggchainManager
```

    - Events:
```
@param currentAggchainManager The current pending aggchainManager
@param newPendingAggchainManager The new pending aggchainManager

event TransferAggchainManagerRole(
    address currentAggchainManager,
    address newPendingAggchainManager
)
```

- `acceptAggchainManagerRole`:

    Allow the current pending aggchainManager to accept the aggchainManager role.

    - Event:
```
@param oldAggchainManager The old aggchainManager
@param newAggchainManager The new aggchainManager
event AcceptAggchainManagerRole(
    address oldAggchainManager,
    address newAggchainManager
)
```

    - Error:

        Thrown when the caller is not the pending aggchain manager
```
error OnlyPendingAggchainManager();
```

### 1.10. transferOptimisticModeManagerRole/acceptOptimisticModeManagerRole
Functions to transfer and accept optimistic mode manager role. 

- `transferOptimisticModeManagerRole`:

    Starts the optimisticModeManager role transfer. This is a two step process, the pending optimisticModeManager must accepted to finalize the process.

    - Parameters:
```
@param newOptimisticModeManager Address of the new optimisticModeManager
```

    - Events:
```
@param currentAggchainManager The current pending aggchainManager
@param newPendingAggchainManager The new pending aggchainManager

event TransferAggchainManagerRole(
    address currentAggchainManager,
    address newPendingAggchainManager
)
```

- `acceptOptimisticModeManagerRole`:

    Allow the current pending optimisticModeManager to accept the optimisticModeManager role.

    - Event:
```
@param oldOptimisticModeManager The old optimisticModeManager
@param newOptimisticModeManager The new optimisticModeManager

event AcceptOptimisticModeManagerRole(
    address oldOptimisticModeManager,
    address newOptimisticModeManager
)
```

    - Error:

        Thrown when the caller is not the pending optimistic mode manager.
```
error OnlyPendingOptimisticModeManager();
```

## 2. Tooling available

### 2.1. Change optimistic mode

[Tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/aggchainFEPTools/changeOptimisticMode) to change optimistic mode (`true/false`).

### 2.2. Transfer aggchain manager

[Tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/aggchainFEPTools/transferAggchainManager) to transfer and accept aggchain manager role.

### 2.3. Transfer optimistic mode manager role

[Tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/aggchainFEPTools/transferOptimisticManager) to transfer and accept optimistic mode manager role.

### 2.4. Update rollup config hash

[Tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/aggchainFEPTools/updateRollupConfigHash) to update rollup config hash.

### 2.5. Update submission interval

[Tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/aggchainFEPTools/updateSubmissionInterval) to update submission interval.

### 2.6. Tools to get aggchain data

[Tools](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/aggchainFEPTools/toolsData) to:

- Get aggchainData
- Get initiliaze bytes aggchain v0
- Get initiliaze bytes aggchain v1