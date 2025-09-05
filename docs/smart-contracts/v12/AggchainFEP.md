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

### 1.2 Migration from PolygonPessimisticConsensus

**Purpose**: Migrate existing PessimisticConsensus chain to FEP.  
**Access Control**: Only callable by aggchain manager with reinitializer(3).  
**Why AggchainManager**: This migration requires adding new parameters and configurations, making it more appropriate for the aggchain manager to handle.

```solidity
function initializeFromPessimisticConsensus(
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
- `_initializerVersion = 1` (initialized as PessimisticConsensus)
- Does NOT call `_initializePolygonConsensusBase` (already initialized)
- Initializes FEP params and AggchainBase components
- Sets up multisig signers and threshold

### 1.3 Migration from AggchainECDSAMultisig

**Purpose**: Upgrade from ECDSA multisig to FEP with SP1 proving.  
**Access Control**: Only callable by aggchain manager with reinitializer(3).  
**Note**: Migration from FEP back to ECDSA multisig is currently not supported.

```solidity
function initializeFromECDSAMultisig(
    InitParams memory _initParams
) external onlyAggchainManager
```

**Requirements**:
- `_initializerVersion = 2` (initialized as ECDSA multisig)
- `l2Outputs.length = 0` (no existing outputs)
- Only initializes FEP-specific parameters
- Assumes AggchainBase and PolygonConsensusBase already initialized
- Preserves existing multisig configuration

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
- `aggchainSignersHash = bytes32(0)` (no signers hash set)

**Migration Process**:
1. Migrates existing vkey configuration to genesis config:
   - Creates `GENESIS_CONFIG_NAME` configuration
   - Moves `aggregationVkey`, `rangeVkeyCommitment`, `rollupConfigHash` to config
   - Sets `selectedOpSuccinctConfigName = GENESIS_CONFIG_NAME`
2. Sets up initial multisig:
   - Adds `trustedSequencer` as sole signer
   - Sets `threshold = 1`
   - Computes and stores `aggchainSignersHash`

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
- `aggchainData`: 32 bytes containing the vkey selector (4 bytes selector ABI-encoded as 32 bytes)

**Process**:
1. Decodes the 4-byte selector from the 32-byte input
2. Retrieves the verification key using `getAggchainVKey(selector)`
3. Fetches the current configuration from `opSuccinctConfigs[selectedOpSuccinctConfigName]`
4. Computes aggchainParams including output roots, config values, and mode settings

**Returns**:
- `aggchainVKey`: The verification key for the specified selector
- `aggchainParams`: Hash of FEP-specific parameters including:
  - Previous and current output roots
  - L2 block number
  - Rollup config hash
  - Optimistic mode flag
  - Trusted sequencer
  - Range vkey commitment
  - Aggregation vkey

**Hash Structure**:
```
aggchainParams = keccak256(
    previousOutputRoot ||
    currentOutputRoot ||
    l2BlockNumber ||
    rollupConfigHash ||
    optimisticMode ||
    trustedSequencer ||
    rangeVkeyCommitment ||
    aggregationVkey
)
```

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
function selectOpSuccinctConfig(bytes32 configName) external onlyAggchainManager
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
function deleteOpSuccinctConfig(bytes32 configName) external onlyAggchainManager
```

**Event Emitted**:
```solidity
event OpSuccinctConfigDeleted(bytes32 indexed configName);
```

### 3.4 Configuration Selection Logic

The system **always** uses `selectedOpSuccinctConfigName` to determine which configuration to use:

1. When proposing L2 outputs, fetches config from `opSuccinctConfigs[selectedOpSuccinctConfigName]`
2. If the config is invalid (all zeros), reverts with `ConfigDoesNotExist()`
3. A valid config must be selected before any L2 output can be proposed

**Key Points**:
- No fallback to "default" values - a config must be explicitly selected
- Genesis config is automatically created and selected during upgrades
- Allows for multiple proving configurations for different scenarios
- Enables A/B testing and graceful upgrades

### 3.5 Special Configuration: Genesis

- **GENESIS_CONFIG_NAME**: `keccak256("opsuccinct_genesis")`
- Special configuration name used during upgrades
- Created automatically when upgrading from FEP v2 to v3
- Preserves existing proving configuration

## 4. Key Design Aspects

### 4.1 Constants
- `AGGCHAIN_TYPE = 0x0001`: FEP type identifier for vkey selection
- `AGGCHAIN_FEP_VERSION = "v3.0.0"`: Current implementation version

### 4.2 Reinitializer Versions
- Version 3 is used for all FEP initialization/migration paths
- Allows upgrades from versions 0 (fresh), 1 (PessimisticConsensus), and 2 (ECDSA or old FEP)

### 4.3 Cross-References
- Inherits from [AggchainBase](./AggchainBase.md) for common aggchain functionality
- Uses multisig management from base contract
- Integrates with AggLayerGateway for optional default keys/signers