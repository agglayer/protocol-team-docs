## AggchainECDSAMultisig `v1.0.0`

## 1. Initialization and Migration Paths

### 1.1 Fresh Deployment Initialization

**Purpose**: Initialize new ECDSA multisig-based aggchain.  
**Access Control**: Only callable by aggchain manager with reinitializer(2).  

```solidity
function initialize(
    address _admin,
    address _trustedSequencer,
    address _gasTokenAddress,
    string memory _trustedSequencerURL,
    string memory _networkName,
    bool _useDefaultSigners,
    SignerInfo[] memory _signersToAdd,
    uint256 _newThreshold
) external onlyAggchainManager
```

**Process Flow**:

1. Uses `getInitializedVersion` modifier to capture current version in transient storage
2. Validates `_initializerVersion = 0` (fresh deployment)
3. Calls `_initializeAggchainBaseAndConsensusBase` with:
   - All standard consensus parameters
   - `useDefaultVkeys = false` (ECDSA doesn't use verification keys)
   - `initOwnedAggchainVKey = bytes32(0)` (not used)
   - `initAggchainVKeySelector = bytes4(0)` (not used)
4. Configures signers based on `_useDefaultSigners` flag:
   - If `true`: Must have empty `_signersToAdd` and `threshold = 0`, uses gateway signers
   - If `false`: Calls `_updateSignersAndThreshold` with provided signers and threshold
5. Validates consistency: reverts with `ConflictingDefaultSignersConfiguration()` if using default signers but also providing custom signers or threshold

**Key Characteristics**:

- Does NOT use verification keys (`useDefaultVkeys = false`, zero vkey/selector)
- Relies on ECDSA signatures instead of SP1 proofs
- Signers and threshold are the primary security mechanism
- Strict validation prevents mixing default and custom signer configurations

### 1.2 Migration from Legacy Consensus

**Purpose**: Upgrade existing PolygonPessimisticConsensus or PolygonRollupBaseEtrog chain to ECDSA multisig.  
**Access Control**: Only callable by rollup manager with reinitializer(2).  

```solidity
function migrateFromLegacyConsensus() external onlyRollupManager
```

**Migration Process**:

1. Validates `_initializerVersion = 1` (already initialized as legacy consensus)
2. ConsensusBase is already initialized from the legacy contract
3. AggchainBase is initialized using values from ConsensusBase
4. Sets `aggchainManager = admin` (preserves existing admin)
5. Adds `trustedSequencer` as the sole initial signer
6. Sets `threshold = 1` for backward compatibility
7. Handles empty `trustedSequencerURL` by using "NO_URL" placeholder (cannot be empty)
8. Updates `aggchainMultisigHash` to reflect new configuration

**Post-Migration State**:

- Single signer (trustedSequencer) with threshold of 1
- Maintains operational continuity
- Admin can later update signers and threshold via `updateSignersAndThreshold`
- `useDefaultVkeys` and `useDefaultSigners` both set to `false`

## 2. Custom Errors

The contract defines specific custom errors for better error handling:

**`InvalidInitializer()`**

- Thrown when trying to call an initialization function with the wrong initializer version
- Used to ensure migration functions are only called from the correct state

**`FunctionNotSupported()`**

- Thrown when attempting to call verification key management functions
- These functions are disabled in ECDSA multisig implementation

Note: Additional errors are inherited from `AggchainBase`, including:

- `InvalidAggchainDataLength()`: Thrown when aggchainData is not empty (must be empty for ECDSA)
- `ConflictingDefaultSignersConfiguration()`: Thrown when mixing default signers with custom signers/threshold

## 3. getVKeyAndAggchainParams Implementation

### 3.1 Function Signature

```solidity
function getVKeyAndAggchainParams(
    bytes memory aggchainData
) public pure override returns (bytes32, bytes32)
```

### 3.2 ECDSA Multisig Implementation Details

**Input Validation**:

- `aggchainData` MUST be empty (length = 0)
- Non-empty data causes revert with `InvalidAggchainDataLength()`

**Returns**:

- First `bytes32`: Always `0x0` (no verification key used)
- Second `bytes32`: Always `0x0` (no custom params)

**Rationale**:

- ECDSA multisig doesn't use SP1 verification keys
- Signers hash and threshold are handled directly in AggchainBase
- The aggchain hash includes signers configuration from base contract

## 4. Aggchain Hash Computation

### 4.1 Hash Structure

The aggchain hash for ECDSA multisig is computed as:

```
keccak256(
    CONSENSUS_TYPE ||       // 32 bits (value: 1)
    bytes32(0) ||          // 256 bits (no vkey)
    bytes32(0) ||          // 256 bits (no params)
    aggchainSignersHash    // 256 bits (from base)
)
```

Where:

- `CONSENSUS_TYPE = 1` (inherited from AggchainBase)
- `aggchainSignersHash = keccak256(threshold || aggchainSigners[])`

### 4.2 Key Differences from Other Implementations

**vs FEP**:

- FEP uses verification keys and SP1 proofs
- FEP includes output roots and config in aggchainParams
- ECDSA uses only signers and signatures

**vs Standard Aggchains**:

- No verification key selector needed
- No aggchain data parameters
- Security comes from multisig threshold

## 5. Verification Flow

### 5.1 `onVerifyPessimistic`

**Purpose**: Handle pessimistic proof verification callback.  
**Access Control**: Only callable by rollup manager.  

```solidity
function onVerifyPessimistic(bytes calldata aggchainData) external onlyRollupManager
```

**Behavior**:

- Validates `aggchainData` is empty
- Emits `OnVerifyPessimisticECDSAMultisig` event
- No actual proof verification (handled by signature validation elsewhere)

**Event Emitted**:
```solidity
event OnVerifyPessimisticECDSAMultisig();
```

## 6. Function Overrides and Unsupported Operations

### 6.1 Disabled Verification Key Functions

The following functions are inherited from AggchainBase but explicitly disabled in ECDSA multisig:

**`enableUseDefaultVkeysFlag()`**
```solidity
function enableUseDefaultVkeysFlag() external view override onlyAggchainManager
```

- Always reverts with `FunctionNotSupported()`
- ECDSA doesn't use verification keys

**`disableUseDefaultVkeysFlag()`**
```solidity
function disableUseDefaultVkeysFlag() external view override onlyAggchainManager
```

- Always reverts with `FunctionNotSupported()`
- ECDSA doesn't use verification keys

**`addOwnedAggchainVKey(bytes4, bytes32)`**
```solidity
function addOwnedAggchainVKey(bytes4, bytes32) external view override onlyAggchainManager
```

- Always reverts with `FunctionNotSupported()`
- Cannot add verification keys to ECDSA implementation

**`updateOwnedAggchainVKey(bytes4, bytes32)`**
```solidity
function updateOwnedAggchainVKey(bytes4, bytes32) external view override onlyAggchainManager
```

- Always reverts with `FunctionNotSupported()`
- Cannot update verification keys in ECDSA implementation

### 6.2 Overridden Verification Key Getter

**`getAggchainVKey(bytes4)`**
```solidity
function getAggchainVKey(bytes4) public pure override returns (bytes32 aggchainVKey)
```

- Always returns `bytes32(0)`
- ECDSA multisig doesn't use verification keys
- Maintains interface compatibility

### 6.3 Version Function

**`version()`**
```solidity
function version() external pure returns (string memory)
```

- Returns `"v1.0.0"` (value of `AGGCHAIN_ECDSA_MULTISIG_VERSION`)
- Used to retrieve the current contract version

## 7. Key Design Decisions

### 7.1 Why Reinitializer(2)?

- Version 0: Fresh deployments
- Version 1: Reserved for PolygonPessimisticConsensus and PolygonRollupBaseEtrog
- Version 2: ECDSA multisig implementation
- Version 3+: Reserved for future implementations (e.g., FEP)

**Upgrade Path**:

- ECDSA → FEP: Supported (via `initializeFromECDSAMultisig` in FEP)
- FEP → ECDSA: Currently not supported

### 7.2 Verification Key Handling

- All vkey-related functions from AggchainBase are explicitly disabled
- `useDefaultVkeys` is always `false`
- `ownedAggchainVKeys` remains empty
- Functions revert with `FunctionNotSupported()` to prevent misuse
- Maintains interface compatibility while using different security model

### 7.3 Signer Management

- Inherits full signer management from [AggchainBase](./AggchainBase.md)
- Can use local signers or gateway signers (`useDefaultSigners` flag)
- Threshold-based security instead of cryptographic proofs
- See AggchainBase documentation for detailed signer management functions

## 8. Constructor and Modifiers

### 8.1 Constructor

**Constructor Parameters**:
```solidity
constructor(
    IAgglayerGER _globalExitRootManager,
    IERC20Upgradeable _pol,
    IAgglayerBridge _bridgeAddress,
    AgglayerManager _rollupManager,
    IAgglayerGateway _aggLayerGateway
)
```

All parameters are passed to the `AggchainBase` parent constructor:

- `_globalExitRootManager`: Global exit root manager contract address
- `_pol`: POL token contract address (used for fees/staking)
- `_bridgeAddress`: Bridge contract address for L1-L2 interactions
- `_rollupManager`: Rollup manager contract address (manages aggchains)
- `_aggLayerGateway`: AgglayerGateway contract address (provides default signers if needed)

### 8.2 Custom Modifiers

**`getInitializedVersion`**
```solidity
modifier getInitializedVersion() {
    _initializerVersion = _getInitializedVersion();
    _;
}
```

This modifier:

- Captures the current initializer version from OpenZeppelin's Initializable contract
- Stores it in transient storage (`_initializerVersion`)
- Used before `reinitializer(2)` to determine which initialization path to follow
- Enables validation logic to differentiate between:
  - Version 0: Fresh deployment → use `initialize()`
  - Version 1: Existing legacy consensus → use `migrateFromLegacyConsensus()`

## 9. Constants and Architecture

### 9.1 Constants

- `AGGCHAIN_TYPE = 0x0000`: ECDSA multisig type identifier
- `AGGCHAIN_ECDSA_MULTISIG_VERSION = "v1.0.0"`: Current version
- `CONSENSUS_TYPE = 1`: Inherited from AggchainBase

### 9.2 Transient Storage

The contract uses transient storage for the initializer version:
```solidity
uint8 private transient _initializerVersion;
```

- Used in the `getInitializedVersion` modifier
- Retrieves the initialized version before applying the `reinitializer` modifier
- Enables proper validation in both `initialize` and `migrateFromLegacyConsensus`

### 9.3 Cross-References

- Inherits from [AggchainBase](./AggchainBase.md) for common functionality
- Can integrate with [AgglayerGateway](./AgglayerGateway.md) for default signers
- Can be upgraded to [AggchainFEP](./AggchainFEP.md) but not vice versa