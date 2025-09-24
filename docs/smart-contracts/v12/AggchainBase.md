## AggchainBase

## 1. Core Initialization

### 1.1 `initAggchainManager`

**Purpose**: Sets the aggchain manager during rollup deployment.  
**Access Control**: Only callable by the rollup manager.  

```solidity
function initAggchainManager(address newAggchainManager) external onlyRollupManager
```

**Parameters**:

- `newAggchainManager`: Address of the aggchain manager (cannot be zero address)

**Event Emitted**:
```solidity
event AcceptAggchainManagerRole(address indexed oldAggchainManager, address indexed newAggchainManager);
```

## 2. Aggchain Hash Computation

### 2.1 `getAggchainHash`

**Purpose**: Computes the aggchain hash for pessimistic proof verification.  
**Access Control**: External view function (called by rollup manager).  

```solidity
function getAggchainHash(bytes memory aggchainData) external view returns (bytes32)
```

**Process**:
1. Retrieves signers hash (from gateway if `useDefaultSigners` is true, otherwise local)
2. Calls `getVKeyAndAggchainParams` to extract vkey and params
3. Computes hash as:
```
keccak256(
    CONSENSUS_TYPE ||      // 32 bits
    aggchainVKey ||        // 256 bits  
    aggchainParams ||      // 256 bits
    signersHash            // 256 bits
)
```

**Returns**: 
- Aggchain hash combining consensus type, verification key, parameters, and signers hash

### 2.2 `getVKeyAndAggchainParams` (Abstract)

**Purpose**: Extract verification key and parameters from aggchain data.  
**Implementation**: Must be implemented by inheriting contracts.  

```solidity
function getVKeyAndAggchainParams(bytes memory aggchainData) 
    public view virtual returns (bytes32 aggchainVKey, bytes32 aggchainParams)
```

## 3. Multisig Management

### 3.1 `updateSignersAndThreshold`

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

**Event Emitted**:
```solidity
event SignersAndThresholdUpdated(
    address[] aggchainSigners, 
    uint256 threshold, 
    bytes32 aggchainSignersHash
);
```

## 4. Getters and Setters

**Important Note**: All getter functions below will use **gateway values** if the corresponding `useDefault*` flag is enabled, otherwise they use **local storage values**.

### 4.1 Verification Key Functions

**`getAggchainVKey`**: Returns verification key
- If `useDefaultVkeys = true`: Returns from `aggLayerGateway.getDefaultAggchainVKey()`
- If `useDefaultVkeys = false`: Returns from local `ownedAggchainVKeys` mapping

**`addOwnedAggchainVKey` / `updateOwnedAggchainVKey`**: Manage local verification keys  
**Access Control**: Only callable by aggchain manager

**`enableUseDefaultVkeysFlag` / `disableUseDefaultVkeysFlag`**: Toggle gateway vkeys usage  
**Access Control**: Only callable by aggchain manager

### 4.2 Signer Functions

**`isSigner`**: Check if address is a signer
- If `useDefaultSigners = true`: Queries `aggLayerGateway.isSigner()`
- If `useDefaultSigners = false`: Checks local `signerToURLs` mapping

**`getAggchainSigners`**: Get all signer addresses
- If `useDefaultSigners = true`: Returns from `aggLayerGateway.getAggchainSigners()`
- If `useDefaultSigners = false`: Returns local `aggchainSigners` array

**`getAggchainSignersCount`**: Get number of signers
- If `useDefaultSigners = true`: Returns from `aggLayerGateway.getAggchainSignersCount()`
- If `useDefaultSigners = false`: Returns `aggchainSigners.length`

**`getAggchainSignersHash`**: Get signers configuration hash
- If `useDefaultSigners = true`: Returns from `aggLayerGateway.getAggchainSignersHash()`
- If `useDefaultSigners = false`: Returns local `aggchainSignersHash`

**`getAggchainSignerInfos`**: Get signers with URLs
- If `useDefaultSigners = true`: Returns from `aggLayerGateway.getAggchainSignerInfos()`
- If `useDefaultSigners = false`: Builds array from local storage

**`enableUseDefaultSignersFlag` / `disableUseDefaultSignersFlag`**: Toggle gateway signers usage  
**Access Control**: Only callable by aggchain manager

### 4.3 Aggchain Manager Functions

**`transferAggchainManagerRole`**: Initiate two-step role transfer  
**`acceptAggchainManagerRole`**: Complete role transfer  
**Access Control**: Transfer by current manager, accept by pending manager

### 4.4 Utility Functions

**`getAggchainVKeySelector`**: Combine vkey version and type into selector  
**`getAggchainTypeFromSelector`**: Extract type from selector  
**`getAggchainVKeyVersionFromSelector`**: Extract version from selector

## 5. Constants and Architecture

### 5.1 Key Constants
- `CONSENSUS_TYPE = 1`: Generic aggchain hash support identifier
- Maximum 255 signers supported

### 5.2 Abstract Contract Design
- **AggchainBase** is an abstract contract providing common functionality
- Inheriting contracts must implement `getVKeyAndAggchainParams`
- Each implementation defines its own `AGGCHAIN_TYPE` constant

### 5.3 Gateway Integration
- Verification keys and signers can be managed locally or via gateway
- Gateway functions don't check flags - flag validation happens in aggchain contracts
- Provides flexibility for chains to use shared or custom configurations