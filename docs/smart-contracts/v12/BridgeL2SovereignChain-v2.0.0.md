
## BridgeL2SovereignChain `v1.0.0` → `v2.0.0`

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

- leafIndex: Index of the unclaimed leaf that is set to be claimed
- sourceNetwork: Rollup id of the claimed index

---

### 1.2 `backwardLET`

**Purpose**: Administrative function to move the Local Exit Tree backward to a previous state with fewer deposits.  
**Access Control**: Only callable by accounts with `GlobalExitRootRemover` role.  
**Use Cases**: Rollback LET due to reorgs, invalid states, or administrative corrections.

```solidity
function backwardLET(
    uint256 newDepositCount,
    bytes32[32] calldata newFrontier,
    bytes32 nextLeaf,
    bytes32[32] calldata proof
) external onlyGlobalExitRootRemover
```

**Parameters**:

- `newDepositCount`: Target deposit count (must be < current depositCount)
- `newFrontier`: Merkle tree frontier array for the target state (32 elements)
- `nextLeaf`: The leaf at position `newDepositCount` in current tree
- `proof`: Merkle proof showing `nextLeaf` exists at `newDepositCount` position

**Event Emitted**:

```solidity
event BackwardLET(uint256 newDepositCount, bytes32 newRoot);
```

- newDepositCount: new last leaf index of the tree after backward LET
- newRoot: new root of the tree after backward LET

---

### 1.3 `forwardLET`

**Purpose**: Administrative function to add multiple leaves to the Local Exit Tree in a single transaction.  
**Access Control**: Only callable by accounts with `GlobalExitRootRemover` role.  
**Use Cases**: Batch processing of deposits, state recovery, or administrative corrections.

```solidity
struct LeafData {
    uint8 leafType;
    uint32 originNetwork;
    address originAddress;
    uint32 destinationNetwork;
    address destinationAddress;
    uint256 amount;
    bytes32 metadataHash;
}

function forwardLET(
    LeafData[] calldata newLeaves,
    bytes32 expectedStateRoot
) external onlyGlobalExitRootRemover
```

**Parameters**:

- `newLeaves`: Array of leaf data added to the tree
    - `leafType`: Type of bridge operation (0 = transfer, 1 = message)
    - `originNetwork`: Source network ID
    - `originAddress`: Source token/contract address
    - `destinationNetwork`: Target network ID
    - `destinationAddress`: Target token/contract address
    - `amount`: Amount being bridged
    - `metadataHash`: Hash of additional metadata
- `expectedStateRoot`: Expected tree root after adding all leaves

**Event Emitted**:

```solidity
event ForwardLET(uint256 newDepositCount, bytes32 newRoot);
```

- newDepositCount: new last leaf index of the tree after forward LET
- newRoot: new root of the tree after forward LET
- To synch, data of all the inserted leafs must be extracted from the calldata of calling `forwardLET` function

---

### 1.4 `setLocalBalanceTree`

**Purpose**: Administrative function to set local balance tree leaves to specific amounts for cross-network token tracking.  
**Access Control**: Only callable by accounts with `GlobalExitRootRemover` role.  
**Use Cases**: Update cross-network token balances, balance corrections, or state recovery.

```solidity
function setLocalBalanceTree(
    uint32[] memory originNetwork,
    address[] memory originTokenAddress,
    uint256[] memory amount
) external onlyGlobalExitRootRemover
```

**Parameters**:

- `originNetwork`: Array of origin network IDs
- `originTokenAddress`: Array of origin token addresses
- `amount`: Array of amounts to set for each token

**Event Emitted**:

```solidity
event SetLocalBalanceTree(
    uint32 indexed originNetwork,
    address indexed originTokenAddress,
    uint256 newAmount
);
```

- Event to update all the new values for the local Balance Tree, the entries not included will remain the same

## 2. Error Handling

### 2.1 New Error Types to Monitor

- `InvalidDepositCount()`: Invalid deposit count for LET operations
- `InvalidLeavesLength()`: Empty leaves array in forwardLET
- `InvalidExpectedRoot()`: Computed root doesn't match expected
- `InvalidSubtreeFrontier()`: Invalid subtree frontier in backwardLET
- `InvalidLBTLeaf()`: Trying to set LBT leaf for same network
- `InputArraysLengthMismatch()`: Array parameters have different lengths
- `OnlyDeployer()`: Function restricted to contract deployer