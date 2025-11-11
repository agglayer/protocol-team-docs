## AggchainFEP `v3.0.0`

## 1. Initialization and Migration Paths

FEP supports four different initialization/migration paths depending on the current state of the contract:

### 1.1 Fresh Deployment Initialization

**Purpose**: Initialize new FEP chain deployment.  
**Access Control**: Only callable by aggchain manager with reinitializer(3).  

```solidity
function initialize(
    InitParams memory _initParams,
    SignerInfo[] memory _signersToAdd,
    uint256 _newThreshold,
    bool _useDefaultVkeys,
    bool _useDefaultSigners,
    bytes32 _initOwnedAggchainVKey,
    bytes4 _initAggchainVKeySelector,
    address _admin,
    address _trustedSequencer,
    address _gasTokenAddress,
    string memory _trustedSequencerURL,
    string memory _networkName
) external onlyAggchainManager
```

**Requirements**:

- `_initializerVersion = 0` (fresh deployment)
- If `_useDefaultVkeys = true`: vkey selector and owned vkey must be zero
- If `_useDefaultVkeys = false`: must provide valid vkey and selector
- Initializes both AggchainBase and PolygonConsensusBase
- Sets up FEP-specific parameters and multisig configuration

### 1.2 Migration from Legacy Consensus (PolygonPessimisticConsensus or PolygonRollupBaseEtrog)

**Purpose**: Migrate existing PessimisticConsensus or RollupBaseEtrog chain to FEP.  
**Access Control**: Only callable by aggchain manager with reinitializer(3).  
**Why AggchainManager**: This migration requires adding new parameters and configurations, making it more appropriate for the aggchain manager to handle.

```solidity
function initializeFromLegacyConsensus(
    InitParams memory _initParams,
    bool _useDefaultVkeys,
    bool _useDefaultSigners,
    bytes32 _initOwnedAggchainVKey,
    bytes4 _initAggchainVKeySelector,
    SignerInfo[] memory _signersToAdd,
    uint256 _newThreshold
) external onlyAggchainManager
```

**Requirements**:

- `_initializerVersion = 1` (initialized as PessimisticConsensus or RollupBaseEtrog)
- Does NOT call `_initializePolygonConsensusBase` (already initialized)
- Initializes FEP params and AggchainBase components
- Sets up multisig signers and threshold

### 1.3 Migration from AggchainECDSAMultisig

**Purpose**: Upgrade from ECDSA multisig to FEP with SP1 proving.  
**Access Control**: Only callable by aggchain manager with reinitializer(3).  
**Note**: Migration from FEP back to ECDSA multisig is currently not supported.

```solidity
function initializeFromECDSAMultisig(
    InitParams memory _initParams,
    bool _useDefaultVkeys,
    bytes32 _initOwnedAggchainVKey,
    bytes4 _initAggchainVKeySelector
) external onlyAggchainManager
```

**Requirements**:

- `_initializerVersion = 2` (initialized as ECDSA multisig)
- `l2Outputs.length = 0` (no existing outputs)
- Only initializes FEP-specific parameters
- Assumes AggchainBase and PolygonConsensusBase already initialized
- Preserves existing multisig configuration (keeps `useDefaultSigners` value)

**Key Difference**: This path only adds FEP functionality, keeping existing base configuration intact.

### 1.4 Upgrade from Previous FEP Version

**Purpose**: Upgrade existing FEP v2 to v3 with config management.  
**Access Control**: Only callable by rollup manager with reinitializer(3).  
**Why RollupManager**: This is a cleaner/faster migration that doesn't require new parameters, so it can be handled directly by the rollup manager.

```solidity
function upgradeFromPreviousFEP() external onlyRollupManager
```

**Requirements**:

- `_initializerVersion = 2` (previous FEP version)
- `aggchainMultisigHash = bytes32(0)` (no multisig hash set)

**Migration Process**:

1. Migrates existing vkey configuration to genesis config:
   - Creates `GENESIS_CONFIG_NAME` configuration
   - Moves `aggregationVkey`, `rangeVkeyCommitment`, `rollupConfigHash` to config
   - Sets `selectedOpSuccinctConfigName = GENESIS_CONFIG_NAME`
2. Sets up initial multisig:
   - Adds `trustedSequencer` as sole signer (with URL, or "NO_URL" if empty)
   - Sets `threshold = 1`
   - Computes and stores `aggchainMultisigHash`

**Purpose**: Enables config management features for existing FEP deployments.

## 2. getVKeyAndAggchainParams Implementation

### 2.1 Function Signature

```solidity
function getVKeyAndAggchainParams(
    bytes memory aggchainData
) public view returns (bytes32 aggchainVKey, bytes32 aggchainParams)
```

### 2.2 FEP Implementation Details

**Input Format**:

- `aggchainData`: 96 bytes (3 * 32 bytes) ABI-encoded containing:
  - `bytes4 _aggchainVKeySelector`: Verification key selector (ABI-encoded as 32 bytes)
  - `bytes32 _outputRoot`: Proposed new output root
  - `uint256 _l2BlockNumber`: Proposed new L2 block number

**Process**:

1. Validates input length is exactly 96 bytes (32 * 3)
2. Decodes the three parameters from aggchainData
3. Validates aggchain type from selector matches `AGGCHAIN_TYPE = 0x0001`
4. Validates L2 block number >= `nextBlockNumber()` (current + submissionInterval)
5. Validates L2 timestamp is not in the future using `computeL2Timestamp(_l2BlockNumber)`
6. Validates output root is not zero
7. Fetches the current configuration from `opSuccinctConfigs[selectedOpSuccinctConfigName]`
8. Validates configuration exists (all fields non-zero)
9. Retrieves the verification key using `getAggchainVKey(selector)`
10. Computes aggchainParams hash

**Returns**:

- `aggchainVKey`: The verification key for the specified selector
- `aggchainParams`: Hash of FEP-specific parameters including:
  - Previous output root (from `l2Outputs[latestOutputIndex()]`)
  - Current output root (from input)
  - L2 block number (from input)
  - Rollup config hash (from selected config)
  - Optimistic mode flag
  - Trusted sequencer address
  - Range vkey commitment (from selected config)
  - Aggregation vkey (from selected config)

**Hash Structure**:

```
aggchainParams = keccak256(
    l2Outputs[latestOutputIndex()].outputRoot ||  // previousOutputRoot
    _outputRoot ||                                 // currentOutputRoot
    _l2BlockNumber ||                             // l2BlockNumber
    config.rollupConfigHash ||
    optimisticMode ||
    trustedSequencer ||
    config.rangeVkeyCommitment ||
    config.aggregationVkey
)
```

**Reverts**:

- `InvalidAggchainDataLength()`: If aggchainData length != 96 bytes
- `InvalidAggchainType()`: If selector doesn't start with `AGGCHAIN_TYPE`
- `L2BlockNumberLessThanNextBlockNumber()`: If block number too low
- `CannotProposeFutureL2Output()`: If computed timestamp >= current time
- `L2OutputRootCannotBeZero()`: If output root is zero
- `ConfigDoesNotExist()`: If selected config is invalid

**Note**: FEP always uses `selectedOpSuccinctConfigName` to fetch configuration. If no config is selected or the config doesn't exist, it reverts with `ConfigDoesNotExist()`.

## 3. Configuration Management (FEP-Specific)

### 3.1 `addOpSuccinctConfig`

**Purpose**: Add a new OP Succinct configuration.  
**Access Control**: Only callable by aggchain manager.  

```solidity
function addOpSuccinctConfig(
    bytes32 _configName,
    bytes32 _rollupConfigHash,
    bytes32 _aggregationVkey,
    bytes32 _rangeVkeyCommitment
) external onlyAggchainManager
```

**Parameters**:

- `_configName`: Unique identifier for the configuration (cannot be empty)
- `_rollupConfigHash`: Chain configuration hash
- `_aggregationVkey`: SP1 aggregation program verification key
- `_rangeVkeyCommitment`: Range program vkey commitment

**Validations**:

- Config name must not be empty (bytes32(0))
- Config must not already exist (checked via `isValidOpSuccinctConfig`)
- All config parameters must be non-zero (aggregationVkey, rangeVkeyCommitment, rollupConfigHash)

**Event Emitted**:

```solidity
event OpSuccinctConfigUpdated(
    bytes32 indexed configName,
    bytes32 aggregationVkey,
    bytes32 rangeVkeyCommitment,
    bytes32 rollupConfigHash
);
```

### 3.2 `selectOpSuccinctConfig`

**Purpose**: Choose which configuration to use for proof submissions.  
**Access Control**: Only callable by aggchain manager.  

```solidity
function selectOpSuccinctConfig(bytes32 _configName) external onlyAggchainManager
```

**Behavior**:

- Configuration must exist (validated via `isValidOpSuccinctConfig`)
- Sets `selectedOpSuccinctConfigName` to the specified config
- All subsequent L2 output proposals will use this configuration

**Event Emitted**:

```solidity
event OpSuccinctConfigSelected(bytes32 indexed configName);
```

### 3.3 `deleteOpSuccinctConfig`

**Purpose**: Remove a named configuration.  
**Access Control**: Only callable by aggchain manager.  

```solidity
function deleteOpSuccinctConfig(bytes32 _configName) external onlyAggchainManager
```

**Event Emitted**:

```solidity
event OpSuccinctConfigDeleted(bytes32 indexed configName);
```

### 3.4 Configuration Selection Logic

The system **always** uses `selectedOpSuccinctConfigName` to determine which configuration to use:

1. When calling `getVKeyAndAggchainParams`, fetches config from `opSuccinctConfigs[selectedOpSuccinctConfigName]`
2. If the config is invalid (all zeros), reverts with `ConfigDoesNotExist()`
3. A valid config must be selected before any L2 output can be proposed

**Key Points**:

- No fallback to "default" values - a config must be explicitly selected
- Genesis config is automatically created and selected during initialization/upgrades
- Allows for multiple proving configurations for different scenarios
- Enables A/B testing and graceful upgrades

### 3.5 Special Configuration: Genesis

**GENESIS_CONFIG_NAME**: `keccak256("opsuccinct_genesis")`

- Special configuration name used during initialization and upgrades
- Created automatically during:
  - Fresh deployments via `initialize()`
  - Legacy consensus migrations via `initializeFromLegacyConsensus()`
  - ECDSA multisig migrations via `initializeFromECDSAMultisig()`
  - FEP v2 to v3 upgrades via `upgradeFromPreviousFEP()`
- Preserves existing proving configuration during upgrades

## 4. Aggchain Manager Functions

### 4.1 `updateSubmissionInterval`

**Purpose**: Update the minimum interval between L2 output submissions.  
**Access Control**: Only callable by aggchain manager.

```solidity
function updateSubmissionInterval(uint256 _submissionInterval) external onlyAggchainManager
```

**Parameters**:

- `_submissionInterval`: New submission interval in L2 blocks (must be > 0)

**Event Emitted**:

```solidity
event SubmissionIntervalUpdated(
    uint256 oldSubmissionInterval,
    uint256 newSubmissionInterval
);
```

**Reverts**:

- `SubmissionIntervalMustBeGreaterThanZero()`: If new interval is 0

## 5. Optimistic Mode Management

### 5.1 `enableOptimisticMode`

**Purpose**: Enable optimistic mode to bypass state transition verification.  
**Access Control**: Only callable by optimistic mode manager.  
**Use Case**: Emergency mode when normal verification is not possible.

```solidity
function enableOptimisticMode() external onlyOptimisticModeManager
```

**Event Emitted**:

```solidity
event EnableOptimisticMode();
```

**Reverts**:

- `OptimisticModeEnabled()`: If optimistic mode is already enabled

### 5.2 `disableOptimisticMode`

**Purpose**: Disable optimistic mode and return to normal verification.  
**Access Control**: Only callable by optimistic mode manager.

```solidity
function disableOptimisticMode() external onlyOptimisticModeManager
```

**Event Emitted**:

```solidity
event DisableOptimisticMode();
```

**Reverts**:

- `OptimisticModeNotEnabled()`: If optimistic mode is not currently enabled

### 5.3 `transferOptimisticModeManagerRole`

**Purpose**: Initiate transfer of optimistic mode manager role (step 1 of 2).  
**Access Control**: Only callable by current optimistic mode manager.

```solidity
function transferOptimisticModeManagerRole(
    address newOptimisticModeManager
) external onlyOptimisticModeManager
```

**Parameters**:

- `newOptimisticModeManager`: Address of the new optimistic mode manager

**Event Emitted**:

```solidity
event TransferOptimisticModeManagerRole(
    address currentOptimisticModeManager,
    address newPendingOptimisticModeManager
);
```

**Reverts**:

- `InvalidZeroAddress()`: If new manager address is zero

### 5.4 `acceptOptimisticModeManagerRole`

**Purpose**: Accept the optimistic mode manager role (step 2 of 2).  
**Access Control**: Only callable by pending optimistic mode manager.

```solidity
function acceptOptimisticModeManagerRole() external
```

**Event Emitted**:

```solidity
event AcceptOptimisticModeManagerRole(
    address oldOptimisticModeManager,
    address newOptimisticModeManager
);
```

**Reverts**:

- `OnlyPendingOptimisticModeManager()`: If caller is not pending manager

## 6. Rollup Manager Callbacks

### 6.1 `onVerifyPessimistic`

**Purpose**: Callback invoked when pessimistic proof is verified.  
**Access Control**: Only callable by rollup manager.

```solidity
function onVerifyPessimistic(bytes memory aggchainData) external onlyRollupManager
```

**Parameters**:

- `aggchainData`: 96 bytes containing selector, outputRoot, and l2BlockNumber

**Behavior**:

1. Decodes outputRoot and l2BlockNumber from aggchainData
2. Creates new OutputProposal with current timestamp
3. Appends to l2Outputs array
4. Emits OutputProposed event

**Event Emitted**:

```solidity
event OutputProposed(
    bytes32 indexed outputRoot,
    uint256 indexed l2OutputIndex,
    uint256 indexed l2BlockNumber,
    uint256 l1Timestamp
);
```

**Note**: This stores the verified L2 state on L1, making it available for withdrawals.

## 7. View Functions

### 7.1 Output Query Functions

**`getL2Output(uint256 _l2OutputIndex)`**

Returns the output proposal at the specified index.

**`latestOutputIndex()`**

Returns the index of the latest output (length - 1).

**`nextOutputIndex()`**

Returns the index where the next output will be stored (length).

**`latestBlockNumber()`**

Returns the L2 block number of the latest output, or startingBlockNumber if no outputs.

**`nextBlockNumber()`**

Returns the next L2 block number that can be proposed: `latestBlockNumber() + submissionInterval`.

### 7.2 Timestamp Functions

**`computeL2Timestamp(uint256 _l2BlockNumber)`**

Computes the L2 timestamp for a given block number:

```
timestamp = startingTimestamp + ((l2BlockNumber - startingBlockNumber) * l2BlockTime)
```

### 7.3 Legacy Getters

**`SUBMISSION_INTERVAL()`**

Returns `submissionInterval` (legacy getter, use direct state variable instead).

**`L2_BLOCK_TIME()`**

Returns `l2BlockTime` (legacy getter, use direct state variable instead).

### 7.4 Config Validation

**`isValidOpSuccinctConfig(OpSuccinctConfig memory _config)`**

Returns true if all config parameters are non-zero:

- `aggregationVkey != bytes32(0)`
- `rangeVkeyCommitment != bytes32(0)`
- `rollupConfigHash != bytes32(0)`

## 8. Key Design Aspects

### 8.1 Constants

- `AGGCHAIN_TYPE = 0x0001`: FEP type identifier for vkey selection
- `AGGCHAIN_FEP_VERSION = "v3.0.0"`: Current implementation version
- `GENESIS_CONFIG_NAME = keccak256("opsuccinct_genesis")`: Default config name

### 8.2 Storage Structures

**OutputProposal**:

- `bytes32 outputRoot`: L2 state root hash
- `uint128 timestamp`: L1 block timestamp when proposed
- `uint128 l2BlockNumber`: L2 block number

**OpSuccinctConfig**:

- `bytes32 aggregationVkey`: SP1 aggregation program vkey
- `bytes32 rangeVkeyCommitment`: SP1 range program vkey commitment
- `bytes32 rollupConfigHash`: Chain configuration hash

### 8.3 Reinitializer Versions

- Version 3 is used for all FEP initialization/migration paths
- Allows upgrades from versions 0 (fresh), 1 (PessimisticConsensus), and 2 (ECDSA or old FEP)
- Uses transient storage `_initializerVersion` to detect previous initialization state

### 8.4 Cross-References

- Inherits from [AggchainBase](./AggchainBase.md) for common aggchain functionality
- Uses multisig management from base contract
- Integrates with AgglayerGateway for optional default keys/signers