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
1. Validates `_initializerVersion = 0` (fresh deployment)
2. Initializes both AggchainBase and PolygonConsensusBase
3. Sets verification key flags to `false` (not used in ECDSA)
4. Configures initial signers and threshold

**Key Characteristics**:
- Does NOT use verification keys (`useDefaultVkeys = false`, zero vkey/selector)
- Relies on ECDSA signatures instead of SP1 proofs
- Signers and threshold are the primary security mechanism

### 1.2 Migration from PolygonPessimisticConsensus

**Purpose**: Upgrade existing PessimisticConsensus chain to ECDSA multisig.  
**Access Control**: Only callable by rollup manager with reinitializer(2).  

```solidity
function migrateFromPessimisticConsensus() external onlyRollupManager
```

**Migration Process**:
1. Validates `_initializerVersion = 1` (already initialized as PessimisticConsensus)
2. Sets `aggchainManager = admin` (preserves existing admin)
3. Adds `trustedSequencer` as the sole initial signer
4. Sets `threshold = 1` for backward compatibility
5. Handles empty `trustedSequencerURL` by using "NO_URL" placeholder

**Post-Migration State**:
- Single signer (trustedSequencer) with threshold of 1
- Maintains operational continuity
- Admin can later update signers and threshold via `updateSignersAndThreshold`

## 2. getVKeyAndAggchainParams Implementation

### 2.1 Function Signature

```solidity
function getVKeyAndAggchainParams(
    bytes memory aggchainData
) public pure override returns (bytes32, bytes32)
```

### 2.2 ECDSA Multisig Implementation Details

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

## 3. Aggchain Hash Computation

### 3.1 Hash Structure

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

### 3.2 Key Differences from Other Implementations

**vs FEP**:
- FEP uses verification keys and SP1 proofs
- FEP includes output roots and config in aggchainParams
- ECDSA uses only signers and signatures

**vs Standard Aggchains**:
- No verification key selector needed
- No aggchain data parameters
- Security comes from multisig threshold

## 4. Verification Flow

### 4.1 `onVerifyPessimistic`

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

## 5. Key Design Decisions

### 5.1 Why Reinitializer(2)?

- Version 0: Fresh deployments
- Version 1: Reserved for PolygonPessimisticConsensus
- Version 2: ECDSA multisig implementation
- Version 3: Reserved for FEP

**Upgrade Path**:
- ECDSA → FEP: Supported (via `initializeFromECDSAMultisig` in FEP)
- FEP → ECDSA: Currently not supported

### 5.2 Verification Key Handling

- All vkey-related functions from AggchainBase are present but not used
- `useDefaultVkeys` is always `false`
- `ownedAggchainVKeys` remains empty
- Maintains interface compatibility while using different security model

### 5.3 Signer Management

- Inherits full signer management from [AggchainBase](./AggchainBase.md)
- Can use local signers or gateway signers (`useDefaultSigners` flag)
- Threshold-based security instead of cryptographic proofs
- See AggchainBase documentation for detailed signer management functions

## 6. Constants and Architecture

### 6.1 Constants
- `AGGCHAIN_TYPE = 0x0000`: ECDSA multisig type identifier
- `AGGCHAIN_ECDSA_MULTISIG_VERSION = "v1.0.0"`: Current version
- `CONSENSUS_TYPE = 1`: Inherited from AggchainBase

### 6.2 Cross-References
- Inherits from [AggchainBase](./AggchainBase.md) for common functionality
- Can integrate with [AggLayerGateway](./AggLayerGateway-Multisig.md) for default signers
- Can be upgraded to [AggchainFEP](./AggchainFEP.md) but not vice versa