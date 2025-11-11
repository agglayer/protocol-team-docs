
## AgglayerBridgeL2 `v1.0.0` → `v1.1.0`

## 1. New Administrative Functions

### 1.1 `setMultipleClaims`

**Purpose**: Administrative function to batch set multiple claims as processed in the claimedBitmap.  

**Access Control**: Only callable by accounts with `GlobalExitRootRemover` role.

```solidity
function setMultipleClaims(uint256[] memory globalIndexes) external onlyGlobalExitRootRemover
```

**Parameters**:

- `globalIndexes`: Array of global indexes to mark as claimed
    - **Format**: `| 191 bits (0) | 1 bit (mainnetFlag) | 32 bits (rollupIndex) | 32 bits (leafIndex) |`
    - **Mainnet**: `mainnetFlag = 1`, `rollupIndex` ignored
    - **Rollup**: `mainnetFlag = 0`, `rollupIndex = networkID - 1`

**Event Emitted**:

```solidity
event SetClaim(uint32 leafIndex, uint32 sourceNetwork);
```

- `leafIndex`: Index of the unclaimed leaf that is set to be claimed
- `sourceNetwork`: Rollup id of the claimed index

---

### 1.2 `unsetMultipleClaims`

**Purpose**: Administrative function to batch unset multiple claims from the claimedBitmap.

**Access Control**: Only callable by accounts with `GlobalExitRootRemover` role.

**Use Cases**: Emergency rollback of incorrectly processed claims or state corrections.

```solidity
function unsetMultipleClaims(uint256[] memory globalIndexes) external onlyGlobalExitRootRemover
```

**Parameters**:

- `globalIndexes`: Array of global indexes to mark as unclaimed
    - **Format**: `| 191 bits (0) | 1 bit (mainnetFlag) | 32 bits (rollupIndex) | 32 bits (leafIndex) |`
    - **Mainnet**: `mainnetFlag = 1`, `rollupIndex` ignored
    - **Rollup**: `mainnetFlag = 0`, `rollupIndex = networkID - 1`

**Events Emitted**:

```solidity
event UpdatedUnsetGlobalIndexHashChain(
    bytes32 unsetGlobalIndex,
    bytes32 newUnsetGlobalIndexHashChain
);
```

- `unsetGlobalIndex`: Global index that was unset
- `newUnsetGlobalIndexHashHashChain`: New value of the unset global index hash chain after this operation

**State Updates**:

- Updates `unsetGlobalIndexHashChain` as: `newUnsetGlobalIndexHashChain = Keccak256(oldUnsetGlobalIndexHashChain, bytes32(globalIndex))`

---

### 1.3 `backwardLET`

**Purpose**: Administrative function to move the Local Exit Tree backward to a previous state with fewer deposits.  

**Access Control**: Only callable by accounts with `GlobalExitRootRemover` role.  

**Emergency State**: Only callable during emergency state (`ifEmergencyState` modifier).

**Use Cases**: Rollback LET due to reorgs, invalid states, or administrative corrections.

```solidity
function backwardLET(
    uint256 newDepositCount,
    bytes32[32] calldata newFrontier,
    bytes32 nextLeaf,
    bytes32[32] calldata proof
) external onlyGlobalExitRootRemover ifEmergencyState
```

**Parameters**:

- `newDepositCount`: Target deposit count (must be < current depositCount)
- `newFrontier`: Merkle tree frontier array for the target state (32 elements)
- `nextLeaf`: The leaf at position `newDepositCount` in current tree
    - For example: if the subset has 5 leaves (positions 0,1,2,3,4), then `nextLeaf` is the actual leaf stored at position 5 in the current (larger) tree
    - This leaf must exist in the current tree and serves as proof that the subset is indeed contained within the current tree structure
- `proof`: Merkle proof showing `nextLeaf` exists at `newDepositCount` position

**Security Note**: The `newFrontier` parameter is technically derivable from `newDepositCount` and `proof`, but is intentionally required as a dual verification mechanism. This forces callers to demonstrate complete understanding of the Merkle tree structure and acts as a safeguard against incorrect proof construction.

**Event Emitted**:

```solidity
event BackwardLET(
    uint256 previousDepositCount,
    bytes32 previousRoot,
    uint256 newDepositCount,
    bytes32 newRoot
);
```

- `previousDepositCount`: The deposit count before moving backward
- `previousRoot`: The root of the local exit tree before moving backward
- `newDepositCount`: The resulting deposit count after moving backward
- `newRoot`: The resulting root of the local exit tree after moving backward

---

### 1.4 `forwardLET`

**Purpose**: Administrative function to add multiple leaves to the Local Exit Tree in a single transaction.  

**Access Control**: Only callable by accounts with `GlobalExitRootRemover` role.  

**Emergency State**: Only callable during emergency state (`ifEmergencyState` modifier).

**Use Cases**: Batch processing of deposits, state recovery, or administrative corrections.

```solidity
struct LeafData {
    uint8 leafType;
    uint32 originNetwork;
    address originAddress;
    uint32 destinationNetwork;
    address destinationAddress;
    uint256 amount;
    bytes metadata;
}

function forwardLET(
    LeafData[] calldata newLeaves,
    bytes32 expectedLER
) external onlyGlobalExitRootRemover ifEmergencyState
```

**Parameters**:

- `newLeaves`: Array of leaf data added to the tree
    - `leafType`: Type of bridge operation (0 = transfer, 1 = message)
    - `originNetwork`: Source network ID
    - `originAddress`: Source token/contract address
    - `destinationNetwork`: Target network ID
    - `destinationAddress`: Target token/contract address
    - `amount`: Amount being bridged
    - `metadata`: Additional metadata (raw bytes, not hash)
- `expectedLER`: Expected tree root after adding all leaves (health check)

**Event Emitted**:

```solidity
event ForwardLET(
    uint256 previousDepositCount,
    bytes32 previousRoot,
    uint256 newDepositCount,
    bytes32 newRoot,
    bytes newLeaves
);
```

- `previousDepositCount`: The deposit count before moving forward
- `previousRoot`: The root of the local exit tree before moving forward
- `newDepositCount`: The resulting deposit count after moving forward
- `newRoot`: The resulting root of the local exit tree after moving forward
- `newLeaves`: The raw bytes of all new leaves added (abi.encode of `LeafData[]`)

**Important**: To synchronize, data of all the inserted leaves must be extracted from the calldata of calling `forwardLET` function or from the `newLeaves` bytes in the event.

---

### 1.5 `setLocalBalanceTree`

**Purpose**: Administrative function to set local balance tree leaves to specific amounts for cross-network token tracking.  

**Access Control**: Only callable by accounts with `GlobalExitRootRemover` role.  

**Emergency State**: Only callable during emergency state (`ifEmergencyState` modifier).

**Use Cases**: Update cross-network token balances, balance corrections, or state recovery.

```solidity
function setLocalBalanceTree(
    uint32[] memory originNetwork,
    address[] memory originTokenAddress,
    uint256[] memory amount
) external onlyGlobalExitRootRemover ifEmergencyState
```

**Parameters**:

- `originNetwork`: Array of origin network IDs
- `originTokenAddress`: Array of origin token addresses
- `amount`: Array of amounts to set for each token

**Key Generation**: The local balance tree key is generated as `keccak256(abi.encodePacked(originNetwork, originTokenAddress))`

**Validation**: The function ensures that only tokens from other networks are updated (revert if `originNetwork == networkID`)

**Event Emitted**:

```solidity
event SetLocalBalanceTree(
    uint32 indexed originNetwork,
    address indexed originTokenAddress,
    uint256 newAmount
);
```

- `originNetwork`: The origin network of the set leaf
- `originTokenAddress`: The origin token address of the set leaf
- `newAmount`: The new amount set for this token

**Note**: Event emitted to update all the new values for the local Balance Tree. Entries not included will remain the same.

---
