## AggLayerGateway Multisig Functions `v1.1.0`

## 1. Multisig Signer Management

### 1.1 `updateSignersAndThreshold`

**Purpose**: Batch update signers and threshold in a single atomic transaction.  
**Access Control**: Only callable by accounts with `AL_MULTISIG_ROLE`.  
**Use Cases**: Manage the default signers that aggchains can use when `useDefaultSigners` flag is enabled.

```solidity
function updateSignersAndThreshold(
    RemoveSignerInfo[] memory _signersToRemove,
    SignerInfo[] memory _signersToAdd,
    uint256 _newThreshold
) external onlyRole(AL_MULTISIG_ROLE)
```

**Parameters**:

- `_signersToRemove`: Array of signers to remove with their indices (MUST be in descending index order)
  - `addr`: Address of the signer to remove
  - `index`: Current index of the signer in the aggchainSigners array
- `_signersToAdd`: Array of new signers to add with their URLs
  - `addr`: Address of the new signer
  - `url`: URL associated with the signer
- `_newThreshold`: New threshold value for multisig operations

**Event Emitted**:

```solidity
event SignersAndThresholdUpdated(
    address[] aggchainSigners,
    uint256 threshold,
    bytes32 aggchainSignersHash
);
```

**Important Notes**:
- Removal indices MUST be provided in descending order to avoid index shifting issues
- The function will revert if indices are not in descending order
- Maximum of 255 signers supported
- Threshold must not exceed the total number of signers after modifications

## 2. View Functions for Multisig State

### 2.1 `isSigner`

**Purpose**: Check if an address is registered as a signer in the gateway.  
**Access Control**: Public view function.  
**Use Cases**: Verify signer status for aggchains using default signers.

```solidity
function isSigner(address _signer) public view returns (bool)
```

**Parameters**:

- `_signer`: Address to check

**Returns**:

- `bool`: True if the address is a registered signer

---

### 2.2 `getAggchainSignersCount`

**Purpose**: Get the total number of registered signers.  
**Access Control**: External view function.  

```solidity
function getAggchainSignersCount() external view returns (uint256)
```

**Returns**:

- Number of signers in the multisig

---

### 2.3 `getAggchainSigners`

**Purpose**: Retrieve all registered signer addresses.  
**Access Control**: External view function.  

```solidity
function getAggchainSigners() external view returns (address[] memory)
```

**Returns**:

- Array of all signer addresses

---

### 2.4 `getAggchainSignersHash`

**Purpose**: Get the hash of the current signers configuration.  
**Access Control**: External view function.  
**Use Cases**: Used by aggchain contracts to include in their aggchain hash computation when using default signers.

```solidity
function getAggchainSignersHash() external view returns (bytes32)
```

**Returns**:

- Hash computed as `keccak256(abi.encodePacked(threshold, aggchainSigners))`

**Note**: Will revert with `AggchainSignersHashNotInitialized()` if the hash has not been initialized.

---

### 2.5 `getAggchainSignerInfos`

**Purpose**: Get all signers with their associated URLs.  
**Access Control**: External view function.  
**Use Cases**: Retrieve complete signer information including contact URLs.

```solidity
function getAggchainSignerInfos() external view returns (SignerInfo[] memory)
```

**Returns**:

- Array of `SignerInfo` structs, each containing:
  - `addr`: Signer address
  - `url`: Associated URL for the signer

## 3. Internal Helper Functions

### 3.1 `_updateSignersAndThreshold` (Internal)

**Purpose**: Internal function that handles the actual logic for updating signers and threshold.  
**Access Control**: Internal function called by `updateSignersAndThreshold`.  

**Process Flow**:
1. Validates that removal indices are in descending order
2. Removes signers in descending index order
3. Adds new signers with validation
4. Updates threshold
5. Recomputes and stores the signers hash

---

### 3.2 `_addSignerInternal` (Internal)

**Purpose**: Add a signer with validation checks.  
**Access Control**: Internal function.  

**Validation**:
- Signer address cannot be zero
- URL cannot be empty
- Signer must not already exist

---

### 3.3 `_removeSignerInternal` (Internal)

**Purpose**: Remove a signer with validation checks.  
**Access Control**: Internal function.  

**Validation**:
- Index must be within bounds
- Address at index must match provided address

---

### 3.4 `_updateAggchainSignersHash` (Internal)

**Purpose**: Recompute and update the signers hash after modifications.  
**Access Control**: Internal function.  

**Computation**:
```solidity
aggchainSignersHash = keccak256(abi.encodePacked(threshold, aggchainSigners))
```

## 4. Error Handling

### 4.1 Multisig-Related Errors

- `IndicesNotInDescendingOrder()`: Removal indices must be in descending order
- `SignerCannotBeZero()`: Signer address cannot be zero address
- `SignerURLCannotBeEmpty()`: Signer URL must be provided
- `SignerAlreadyExists()`: Attempting to add a duplicate signer
- `SignerDoesNotExist()`: Signer not found at specified index
- `AggchainSignersTooHigh()`: Exceeds maximum of 255 signers
- `InvalidThreshold()`: Threshold exceeds number of signers
- `AggchainSignersHashNotInitialized()`: Signers hash not yet initialized

## 5. Storage Variables

### 5.1 Multisig Storage

- `address[] aggchainSigners`: Array of registered signer addresses
- `mapping(address => string) signerToURLs`: Maps signer addresses to their URLs
- `uint256 threshold`: Required number of signatures for multisig operations
- `bytes32 aggchainSignersHash`: Cached hash of threshold and signers array

## 6. Integration with Aggchains

### 6.1 How Aggchains Use Gateway Signers

1. **Enable Default Signers**: Aggchains set `useDefaultSigners = true` to use gateway signers
2. **Query Signer Data**: Aggchains call gateway view functions to retrieve signer information
3. **Include in Hash**: The `aggchainSignersHash` is included in the aggchain hash computation
4. **Verification**: State transitions are verified using the gateway's signer configuration

**Important**: Gateway functions don't check the `useDefaultSigners` flag - that validation happens in the aggchain contracts themselves.

### 6.2 Benefits of Centralized Signer Management

- **Consistency**: All aggchains using default signers share the same configuration
- **Efficiency**: Single point of management for signer updates
- **Flexibility**: Aggchains can opt-in or opt-out of default signers
- **Security**: Role-based access control for signer management

## 7. Usage Examples

### 7.1 Adding New Signers

```solidity
SignerInfo[] memory newSigners = new SignerInfo[](2);
newSigners[0] = SignerInfo({
    addr: 0x123...,
    url: "https://signer1.example.com"
});
newSigners[1] = SignerInfo({
    addr: 0x456...,
    url: "https://signer2.example.com"
});

gateway.updateSignersAndThreshold(
    new RemoveSignerInfo[](0), // No removals
    newSigners,
    3 // New threshold
);
```

### 7.2 Removing and Adding Signers

```solidity
RemoveSignerInfo[] memory toRemove = new RemoveSignerInfo[](2);
toRemove[0] = RemoveSignerInfo({addr: 0xOldSigner1, index: 5}); // Higher index first
toRemove[1] = RemoveSignerInfo({addr: 0xOldSigner2, index: 2}); // Lower index second

SignerInfo[] memory toAdd = new SignerInfo[](1);
toAdd[0] = SignerInfo({addr: 0xNewSigner, url: "https://newsigner.com"});

gateway.updateSignersAndThreshold(toRemove, toAdd, 2);
```