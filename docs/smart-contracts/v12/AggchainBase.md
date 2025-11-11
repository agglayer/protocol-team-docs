## AggchainBase

## 1. Overview

**AggchainBase** is an abstract contract that provides common functionality for aggchain implementations. It extends `PolygonConsensusBase` and implements core features for:

- Verification key management (local or gateway-based)
- Multisig signer management (local or gateway-based)  
- Aggchain manager role management
- Metadata management
- Aggchain hash computation for pessimistic proof verification

Inheriting contracts must implement the abstract function `getVKeyAndAggchainParams`.

## 2. Core Initialization

### 2.1 `initAggchainManager`

**Purpose**: Sets the aggchain manager during rollup deployment.  
**Access Control**: Only callable by the rollup manager.  

```solidity
function initAggchainManager(address newAggchainManager) external onlyRollupManager
```

**Parameters**:

- `newAggchainManager`: Address of the aggchain manager (cannot be zero address)

**Validation**:

- Can only be initialized if current aggchainManager is zero
- Reverts with `AggchainManagerAlreadyInitialized()` if already set
- Reverts with `AggchainManagerCannotBeZero()` if zero address

**Event Emitted**:

```solidity
event AcceptAggchainManagerRole(address indexed oldAggchainManager, address indexed newAggchainManager);
```

### 2.2 `_initializeAggchainBaseAndConsensusBase`

**Purpose**: Internal initialization for both AggchainBase and PolygonConsensusBase.  
**Access Control**: Internal function, only during initialization.  

```solidity
function _initializeAggchainBaseAndConsensusBase(
    address _admin,
    address sequencer,
    address _gasTokenAddress,
    string memory sequencerURL,
    string memory _networkName,
    bool _useDefaultVkeys,
    bool _useDefaultSigners,
    bytes32 _initOwnedAggchainVKey,
    bytes4 _initAggchainVKeySelector
) internal onlyInitializing
```

**Process**:

1. Validates that admin and sequencer are not zero addresses
2. Calls `_initializePolygonConsensusBase` with consensus parameters
3. Calls `_initializeAggchainBase` with aggchain-specific parameters

### 2.3 `_initializeAggchainBase`

**Purpose**: Internal initialization for AggchainBase storage.  
**Access Control**: Internal function, only during initialization.  

```solidity
function _initializeAggchainBase(
    bool _useDefaultVkeys,
    bool _useDefaultSigners,
    bytes32 _initOwnedAggchainVKey,
    bytes4 _initAggchainVKeySelector
) internal onlyInitializing
```

**Process**:

1. Sets `useDefaultVkeys` flag
2. Sets `useDefaultSigners` flag
3. Stores initial aggchain verification key in `ownedAggchainVKeys` mapping

## 3. Aggchain Hash Computation

### 3.1 `getAggchainHash`

**Purpose**: Computes the aggchain hash for pessimistic proof verification.  
**Access Control**: External view function (called by rollup manager).  

```solidity
function getAggchainHash(bytes memory aggchainData) external view returns (bytes32)
```

**Hash Structure**:

```
keccak256(
    CONSENSUS_TYPE ||      // 32 bits
    aggchainVKey ||        // 256 bits  
    aggchainParams ||      // 256 bits
    multisigHash           // 256 bits
)
```

**Process**:

1. Retrieves multisig hash (from gateway if `useDefaultSigners` is true, otherwise local)
2. Calls `getVKeyAndAggchainParams` to extract vkey and params
3. Computes and returns the combined hash

**Returns**:

- Aggchain hash combining consensus type, verification key, parameters, and signers hash

### 3.2 `getVKeyAndAggchainParams` (Abstract)

**Purpose**: Extract verification key and parameters from aggchain data.  
**Implementation**: Must be implemented by inheriting contracts.  

```solidity
function getVKeyAndAggchainParams(bytes memory aggchainData) 
    public view virtual returns (bytes32 aggchainVKey, bytes32 aggchainParams)
```

## 4. Multisig Management

### 4.1 `updateSignersAndThreshold`

**Purpose**: Batch update signers and threshold in a single transaction.  
**Access Control**: Only callable by aggchain manager.  

```solidity
function updateSignersAndThreshold(
    RemoveSignerInfo[] memory _signersToRemove,
    SignerInfo[] memory _signersToAdd,
    uint256 _newThreshold
) external onlyAggchainManager
```

**Parameters**:

- `_signersToRemove`: Array of signers to remove (must be in descending index order)
- `_signersToAdd`: Array of new signers to add with URLs
- `_newThreshold`: New threshold value

**Process**:

1. Validates that indices in `_signersToRemove` are in descending order
2. Removes specified signers (in descending order to avoid index shifting)
3. Adds new signers
4. Validates total signers don't exceed `MAX_AGGCHAIN_SIGNERS` (255)
5. Validates threshold is valid: `threshold <= signers.length` and `threshold != 0` if signers exist
6. Updates threshold
7. Updates aggchain multisig hash

**Event Emitted**:

```solidity
event SignersAndThresholdUpdated(
    address[] aggchainSigners, 
    uint256 threshold, 
    bytes32 aggchainSignersHash
);
```

### 4.2 Internal Signer Management

**`_addSignerInternal(address _signer, string memory url)`**

Validates and adds a signer:

- Reverts with `SignerCannotBeZero()` if signer is zero address
- Reverts with `SignerURLCannotBeEmpty()` if URL is empty
- Reverts with `SignerAlreadyExists()` if signer already exists

**`_removeSignerInternal(address _signer, uint256 _signerIndex)`**

Validates and removes a signer:

- Reverts with `SignerDoesNotExist()` if index is out of bounds or address doesn't match

**`_updateAggchainMultisigHash()`**

Updates the multisig hash:

```
aggchainMultisigHash = keccak256(abi.encodePacked(threshold, aggchainSigners))
```

## 5. Aggchain Manager Role Management

### 5.1 `transferAggchainManagerRole`

**Purpose**: Initiates a two-step aggchain manager role transfer.  
**Access Control**: Only callable by current aggchain manager.  

```solidity
function transferAggchainManagerRole(address newAggchainManager) external onlyAggchainManager
```

**Parameters**:

- `newAggchainManager`: Address of the new aggchain manager (cannot be zero)

**Event Emitted**:

```solidity
event TransferAggchainManagerRole(address indexed currentAggchainManager, address indexed pendingAggchainManager);
```

### 5.2 `acceptAggchainManagerRole`

**Purpose**: Completes the aggchain manager role transfer.  
**Access Control**: Only callable by pending aggchain manager.  

```solidity
function acceptAggchainManagerRole() external
```

**Process**:

1. Validates caller is `pendingAggchainManager`
2. Updates `aggchainManager` to pending manager
3. Clears `pendingAggchainManager`

**Event Emitted**:

```solidity
event AcceptAggchainManagerRole(address indexed oldAggchainManager, address indexed newAggchainManager);
```

## 6. Metadata Management

### 6.1 `setAggchainMetadataManager`

**Purpose**: Sets the aggchain metadata manager address.  
**Access Control**: Only callable by aggchain manager.  

```solidity
function setAggchainMetadataManager(address newAggchainMetadataManager) external onlyAggchainManager
```

**Event Emitted**:

```solidity
event SetAggchainMetadataManager(address indexed oldManager, address indexed newManager);
```

### 6.2 `setAggchainMetadata`

**Purpose**: Sets or updates a single metadata entry.  
**Access Control**: Only callable by aggchain metadata manager.  

```solidity
function setAggchainMetadata(string calldata key, string calldata value) external onlyAggchainMetadataManager
```

**Parameters**:

- `key`: The metadata key to set
- `value`: The metadata value to set (empty values allowed to clear metadata)

**Event Emitted**:

```solidity
event AggchainMetadataSet(string key, string value);
```

### 6.3 `batchSetAggchainMetadata`

**Purpose**: Sets or updates multiple metadata entries in a single transaction.  
**Access Control**: Only callable by aggchain metadata manager.  

```solidity
function batchSetAggchainMetadata(
    string[] calldata keys,
    string[] calldata values
) external onlyAggchainMetadataManager
```

**Parameters**:

- `keys`: Array of metadata keys to set
- `values`: Array of metadata values to set (must be same length as keys)

**Validation**:

- Reverts with `MetadataArrayLengthMismatch()` if array lengths differ

## 7. Verification Key Management

### 7.1 Verification Key Getters

**`getAggchainVKey(bytes4 aggchainVKeySelector)`**

Returns verification key:

- If `useDefaultVkeys = true`: Returns from `aggLayerGateway.getDefaultAggchainVKey()`
- If `useDefaultVkeys = false`: Returns from local `ownedAggchainVKeys` mapping
- Reverts with `AggchainVKeyNotFound()` if local key is not found

### 7.2 Verification Key Management

**`addOwnedAggchainVKey(bytes4 aggchainVKeySelector, bytes32 newAggchainVKey)`**

Adds a new verification key:

- Access Control: Only aggchain manager
- Reverts with `ZeroValueAggchainVKey()` if key is zero
- Reverts with `OwnedAggchainVKeyAlreadyAdded()` if selector already has a key

**`updateOwnedAggchainVKey(bytes4 aggchainVKeySelector, bytes32 updatedAggchainVKey)`**

Updates an existing verification key:

- Access Control: Only aggchain manager
- Reverts with `OwnedAggchainVKeyNotFound()` if key doesn't exist

### 7.3 Verification Key Flag Management

**`enableUseDefaultVkeysFlag()`**

Enables gateway verification keys:

- Access Control: Only aggchain manager (virtual, can be overridden)
- Reverts with `UseDefaultVkeysAlreadyEnabled()` if already enabled

**`disableUseDefaultVkeysFlag()`**

Disables gateway verification keys:

- Access Control: Only aggchain manager (virtual, can be overridden)
- Reverts with `UseDefaultVkeysAlreadyDisabled()` if already disabled

### 7.4 Verification Key Selector Utilities

**`getAggchainVKeySelector(bytes2 aggchainVKeyVersion, bytes2 aggchainType)`**

Computes the selector by combining version and type:

```
[            aggchainVKeySelector         ]
[  aggchainVKeyVersion   |  AGGCHAIN_TYPE ]
[        2 bytes         |    2 bytes     ]
```

**`getAggchainTypeFromSelector(bytes4 aggchainVKeySelector)`**

Extracts aggchain type (last 2 bytes) from selector.

**`getAggchainVKeyVersionFromSelector(bytes4 aggchainVKeySelector)`**

Extracts aggchain verification key version (first 2 bytes) from selector.

## 8. Signer Management

**Important Note**: All signer getter functions will use **gateway values** if `useDefaultSigners = true`, otherwise they use **local storage values**.

### 8.1 Signer Query Functions

**`isSigner(address _signer)`**

Check if address is a signer:

- If `useDefaultSigners = true`: Queries `aggLayerGateway.isSigner()`
- If `useDefaultSigners = false`: Checks local `signerToURLs` mapping

**`getAggchainSigners()`**

Get all signer addresses:

- If `useDefaultSigners = true`: Returns from `aggLayerGateway.getAggchainSigners()`
- If `useDefaultSigners = false`: Returns local `aggchainSigners` array

**`getAggchainSignersCount()`**

Get number of signers:

- If `useDefaultSigners = true`: Returns from `aggLayerGateway.getAggchainSignersCount()`
- If `useDefaultSigners = false`: Returns `aggchainSigners.length`

**`getAggchainMultisigHash()`**

Get signers configuration hash:

- If `useDefaultSigners = true`: Returns from `aggLayerGateway.getAggchainMultisigHash()`
- If `useDefaultSigners = false`: Returns local `aggchainMultisigHash`
- Reverts with `AggchainSignersHashNotInitialized()` if local hash is zero

**`getAggchainSignerInfos()`**

Get signers with URLs:

- If `useDefaultSigners = true`: Returns from `aggLayerGateway.getAggchainSignerInfos()`
- If `useDefaultSigners = false`: Builds array from local storage

**`getThreshold()`**

Get the threshold for multisig:

- If `useDefaultSigners = true`: Returns from `aggLayerGateway.getThreshold()`
- If `useDefaultSigners = false`: Returns local `threshold`

### 8.2 Signer Flag Management

**`enableUseDefaultSignersFlag()`**

Enables gateway signers:

- Access Control: Only aggchain manager
- Reverts with `UseDefaultSignersAlreadyEnabled()` if already enabled

**`disableUseDefaultSignersFlag()`**

Disables gateway signers:

- Access Control: Only aggchain manager
- Reverts with `UseDefaultSignersAlreadyDisabled()` if already disabled

## 9. Internal Validation Functions

### 9.1 `_validateVKeysConsistency`

**Purpose**: Validates consistency of verification key initialization parameters.  
**Access Control**: Internal pure function.  

```solidity
function _validateVKeysConsistency(
    bool _useDefaultVkeys,
    bytes4 _initAggchainVKeySelector,
    bytes32 _initOwnedAggchainVKey,
    bytes2 aggchainType
) internal pure
```

**Validation Rules**:

If `_useDefaultVkeys = true`:

- `_initAggchainVKeySelector` must be `bytes4(0)`
- `_initOwnedAggchainVKey` must be `bytes32(0)`
- Reverts with `InvalidInitAggchainVKey()` if violated

If `_useDefaultVkeys = false`:

- Aggchain type extracted from selector must match provided `aggchainType`
- Reverts with `InvalidAggchainType()` if mismatch

## 10. Constants and Architecture

### 10.1 Key Constants

- `CONSENSUS_TYPE = 1`: Generic aggchain hash support identifier
- `MAX_AGGCHAIN_SIGNERS = 255`: Maximum number of signers supported

### 10.2 Immutables

- `aggLayerGateway`: IAgglayerGateway address (set in constructor)

### 10.3 Constructor

```solidity
constructor(
    IAgglayerGER _globalExitRootManager,
    IERC20Upgradeable _pol,
    IAgglayerBridge _bridgeAddress,
    AgglayerManager _rollupManager,
    IAgglayerGateway _aggLayerGateway
)
```

Validates all addresses are non-zero and sets the immutable gateway address.

### 10.4 Abstract Contract Design

- **AggchainBase** is an abstract contract providing common functionality
- Inherits from `PolygonConsensusBase`, `IAggchainBase`, and `IVersion`
- Inheriting contracts must implement `getVKeyAndAggchainParams`
- Each implementation defines its own `AGGCHAIN_TYPE` constant
- Base `initialize` function from PolygonConsensusBase is disabled (reverts with `InvalidInitializeFunction()`)

### 10.5 Gateway Integration

- Verification keys and signers can be managed locally or via gateway
- Gateway functions don't check flags - flag validation happens in aggchain contracts
- Provides flexibility for chains to use shared or custom configurations
- Gateway address is immutable and validated in constructor

### 10.6 Legacy Storage

The contract includes legacy storage variables to maintain upgrade compatibility:

- `_legacyDataAvailabilityProtocol`: From PolygonValidiumEtrog
- `_legacyIsSequenceWithDataAvailabilityAllowed`: From PolygonValidiumEtrog
- `_legacyvKeyManager`: From previous aggchainBase version
- `_legacypendingVKeyManager`: From previous aggchainBase version

### 10.7 Storage Gap

- `__gap[44]`: Reserved storage space for future upgrades

## 11. Custom Errors

The contract defines numerous custom errors for precise error handling:

**Initialization Errors**:

- `AggchainManagerAlreadyInitialized()`
- `AggchainManagerCannotBeZero()`
- `InvalidInitializeFunction()`
- `InvalidZeroAddress()`

**Access Control Errors**:

- `OnlyAggchainManager()`
- `OnlyAggchainMetadataManager()`
- `OnlyPendingAggchainManager()`

**Verification Key Errors**:

- `AggchainVKeyNotFound()`
- `ZeroValueAggchainVKey()`
- `OwnedAggchainVKeyAlreadyAdded()`
- `OwnedAggchainVKeyNotFound()`
- `UseDefaultVkeysAlreadyEnabled()`
- `UseDefaultVkeysAlreadyDisabled()`
- `InvalidInitAggchainVKey()`
- `InvalidAggchainType()`

**Signer Errors**:

- `SignerCannotBeZero()`
- `SignerURLCannotBeEmpty()`
- `SignerAlreadyExists()`
- `SignerDoesNotExist()`
- `AggchainSignersTooHigh()`
- `InvalidThreshold()`
- `IndicesNotInDescendingOrder()`
- `AggchainSignersHashNotInitialized()`
- `UseDefaultSignersAlreadyEnabled()`
- `UseDefaultSignersAlreadyDisabled()`

**Metadata Errors**:

- `MetadataArrayLengthMismatch()`

## 12. Events

**Manager Events**:

- `AcceptAggchainManagerRole(address indexed oldAggchainManager, address indexed newAggchainManager)`
- `TransferAggchainManagerRole(address indexed currentAggchainManager, address indexed pendingAggchainManager)`
- `SetAggchainMetadataManager(address indexed oldManager, address indexed newManager)`

**Verification Key Events**:

- `AddAggchainVKey(bytes4 indexed aggchainVKeySelector, bytes32 aggchainVKey)`
- `UpdateAggchainVKey(bytes4 indexed aggchainVKeySelector, bytes32 previousAggchainVKey, bytes32 newAggchainVKey)`
- `EnableUseDefaultVkeysFlag()`
- `DisableUseDefaultVkeysFlag()`

**Signer Events**:

- `SignersAndThresholdUpdated(address[] aggchainSigners, uint256 threshold, bytes32 aggchainSignersHash)`
- `EnableUseDefaultSignersFlag()`
- `DisableUseDefaultSignersFlag()`

**Metadata Events**:

- `AggchainMetadataSet(string key, string value)`
