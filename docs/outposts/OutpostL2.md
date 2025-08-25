# Outpost L2 contracts
[TOC]

!!! danger "Warning"
    The code is not audited yet and it is not meant to use in production. Current status: release-candidate

## Motivation
This document outlines the smart contract changes introduced in the `feature/outposts` branch. These changes introduce new administrative functions for managing the Local Exit Tree (LET), claims, and local balance trees. The aggkit must **listen to the events** emitted by these functions to keep its database synchronized with the contract state.
The second big change is the abstraction of some bridge logic to a separate contract called `BridgeLib` with the main purpose of improving bridge's bytecode size.

## Overview

The main changes include:

- **New administrative functions** for LET manipulation and claims management
- **New events** that aggkit must monitor to maintain database synchronization
- **BridgeLib contract** for bytecode optimization and utility functions
- **Enhanced error handling** with specific error types
- **Version updates** across bridge contracts

---

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

---

## 2. BridgeLib Contract - Bytecode Optimization

### 2.1 Rationale for Bytecode Abstraction

The main motivation for creating the BridgeLib contract is **Ethereum's bytecode size limit**. Ethereum has a maximum contract bytecode size limit of **24,576 bytes (24KB)** established by EIP-170. As the bridge contract grows with new functionality, it approaches this limit, making deployment on Ethereum impossible.

**Key Benefits**:

- **Ethereum Compatibility**: Ensures the bridge contract can be deployed on Ethereum mainnet
- **Code Reusability**: Utility functions can be shared across multiple contracts
- **Maintainability**: Separates utility logic from core bridge functionality
- **Gas Optimization**: External library calls can be more gas-efficient for complex operations

### 2.2 Functions Moved to BridgeLib

The following functions were extracted from the main bridge contract to reduce bytecode size:

#### Token Metadata Functions

```solidity
// Previously inline in PolygonZkEVMBridgeV2, now in BridgeLib
function safeName(address token) public view returns (string memory)
function safeSymbol(address token) public view returns (string memory)
function safeDecimals(address token) public view returns (uint8)
function getTokenMetadata(address token) external view returns (bytes memory)
function returnDataToString(bytes memory data) internal pure returns (string memory)
```

#### Permit Validation Functions

```solidity
// Previously inline in PolygonZkEVMBridgeV2, now in BridgeLib
function validateAndProcessPermit(
    address token,
    bytes calldata permitData,
    address expectedOwner,
    address expectedSpender
) external returns (bool success)
```

#### Constants and Signatures Moved

```solidity
// Permit signatures moved from main contract to BridgeLib
bytes4 internal constant _PERMIT_SIGNATURE = 0xd505accf;
bytes4 internal constant _PERMIT_SIGNATURE_DAI = 0x8fcbaf0c;

// Error definitions moved to BridgeLib
error NotValidOwner();
error NotValidSpender();
error NotValidSignature();
```

### 2.3 Integration Changes in Main Bridge Contract

The main bridge contract now uses the BridgeLib instance:

```solidity
// New immutable reference to BridgeLib
BridgeLib public immutable bridgeLib;

// Constructor deploys BridgeLib
constructor() {
    // ... existing code ...
    bridgeLib = new BridgeLib();
}

// Token metadata now delegated to BridgeLib
function getTokenMetadata(address token) external view returns (bytes memory) {
    return bridgeLib.getTokenMetadata(token);
}

// Permit processing now delegated to BridgeLib
function _permit(address token, bytes calldata permitData) internal {
    bridgeLib.validateAndProcessPermit(
        token,
        permitData,
        msg.sender,
        address(this)
    );
}
```

### 2.4 Bytecode Size Impact

**Before BridgeLib abstraction**:

- All utility functions were inline in the main bridge contract
- Contract approaching the 24KB bytecode limit
- Risk of deployment failure on Ethereum

**After BridgeLib abstraction**:

- Core bridge functionality remains in main contract
- Utility functions moved to separate BridgeLib contract
- Significant bytecode reduction in main contract
- Ethereum deployment compatibility ensured

### 2.5 Version Updates Related to BridgeLib

The bytecode abstraction is reflected in the version updates:

- **PolygonZkEVMBridgeV2**: `v1.0.0` → `v1.1.0`
    - Indicates the integration of BridgeLib for bytecode optimization
    - Maintains backward compatibility in the public interface
    - Internal implementation changes for permit and metadata handling


## 3. Error Handling

### 3.1 New Error Types to Monitor

- `InvalidDepositCount()`: Invalid deposit count for LET operations
- `InvalidLeavesLength()`: Empty leaves array in forwardLET
- `InvalidExpectedRoot()`: Computed root doesn't match expected
- `InvalidSubtreeFrontier()`: Invalid subtree frontier in backwardLET
- `InvalidLBTLeaf()`: Trying to set LBT leaf for same network
- `InputArraysLengthMismatch()`: Array parameters have different lengths
- `OnlyDeployer()`: Function restricted to contract deployer

---

## 4. Version Updates

- **PolygonZkEVMBridgeV2**: `v1.0.0` → `v1.1.0`
- **BridgeL2SovereignChain**: `v1.0.0` → `v2.0.0`
