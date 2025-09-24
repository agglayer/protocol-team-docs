# Agglayer Contracts Renaming Summary

## 1. Overview

This document summarizes the smart contract renaming changes.

## 2. Goals

- **Renaming**: Reflects the evolution toward aggregation layer architecture
- **Function signatures**: Identical across all contracts
- **Contract logic**: Unchanged - no business logic modifications
- **State variables**: Same structure and types maintained
- **Import dependencies**: Properly updated to reflect new names

## 3. Complete List of Renamed Smart Contracts

### 3.1 Main Contracts (contracts/)

| Old Name | New Name |
|------------------------|---------------------------------------|
| `PolygonRollupManager.sol` | `AgglayerManager.sol` |
| `PolygonZkEVMBridgeV2.sol` | `AgglayerBridge.sol` |
| `PolygonZkEVMGlobalExitRootV2.sol` | `AgglayerGER.sol` |
| `AggLayerGateway.sol` | `AgglayerGateway.sol` *(capitalization fix)* |

### 3.2 Root Directory Contracts (contracts/)

| Old Name | New Name |
|------------------------|---------------------------------------|
| `PolygonZkEVMGlobalExitRootL2.sol` | `LegacyAgglayerGERL2.sol` |

### 3.3 Sovereign Chains Contracts (contracts/sovereignChains/)

| Old Name | New Name |
|------------------------|---------------------------------------|
| `BridgeL2SovereignChain.sol` | `AgglayerBridgeL2.sol` |
| `GlobalExitRootManagerL2SovereignChain.sol` | `AgglayerGERL2.sol` |

### 3.4 Interface Files (contracts/interfaces/)

| Old Name | New Name |
|------------------------|---------------------------------------|
| `IPolygonRollupManager.sol` | `IAgglayerManager.sol` |
| `IPolygonZkEVMBridgeV2.sol` | `IAgglayerBridge.sol` |
| `IPolygonZkEVMGlobalExitRootV2.sol` | `IAgglayerGER.sol` |
| `IAggLayerGateway.sol` | `IAgglayerGateway.sol` *(capitalization fix)* |
| `IBridgeL2SovereignChains.sol` | `IAgglayerBridgeL2.sol` |
| `IGlobalExitRootManagerL2SovereignChain.sol` | `IAgglayerGERL2.sol` |
| `IBasePolygonZkEVMGlobalExitRoot.sol` | `IBaseLegacyAgglayerGER.sol` |

### 3.5 Library Files (contracts/lib/)

| Old Name | New Name |
|------------------------|---------------------------------------|
| `PolygonZkEVMGlobalExitRootBaseStorage.sol` | `LegacyAgglayerGERBaseStorage.sol` |