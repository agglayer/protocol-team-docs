# Smart Contract Reorganization Summary

## 1. Overview

This document summarizes the smart contract reorganization changes.

## 2. Goals

- **Reorganizaton**: Clear separation of current vs. legacy contracts
- **Function signatures**: Identical across all contracts
- **Contract logic**: Unchanged - no business logic modifications  
- **State variables**: Same structure and types maintained
- **Import paths**: Updated to reflect new directory structure
- **Interface references**: Some reverted to maintain compatibility

## 3. Major Reorganization Changes

### 3.1 Elimination of v2/ Directory Structure

The main reorganization involved **flattening the directory structure** by moving contracts from `contracts/v2/` to `contracts/` root level.

#### Before:
```
contracts/
├── v2/
│   ├── AgglayerManager.sol
│   ├── AgglayerBridge.sol  
│   ├── AgglayerGER.sol
│   ├── AgglayerGateway.sol
│   ├── aggchains/
│   ├── consensus/
│   ├── interfaces/
│   ├── lib/
│   ├── mocks/
│   ├── sovereignChains/
│   └── ...
├── PolygonZkEVM.sol
├── PolygonZkEVMBridge.sol
└── ...
```

#### After:
```
contracts/
├── AgglayerManager.sol
├── AgglayerBridge.sol
├── AgglayerGER.sol  
├── AgglayerGateway.sol
├── aggchains/
├── consensus/
├── interfaces/
├── lib/
├── mocks/
├── sovereignChains/
├── previousVersions/
└── ...
```

### 3.2 Contracts Moved to Root Level

The following main contracts were moved from `contracts/v2/` to `contracts/`:

| Contract | Old Path | New Path |
|----------|----------|----------|
| `AgglayerManager.sol` | `contracts/v2/AgglayerManager.sol` | `contracts/AgglayerManager.sol` |
| `AgglayerBridge.sol` | `contracts/v2/AgglayerBridge.sol` | `contracts/AgglayerBridge.sol` |
| `AgglayerGER.sol` | `contracts/v2/AgglayerGER.sol` | `contracts/AgglayerGER.sol` |
| `AgglayerGateway.sol` | `contracts/v2/AgglayerGateway.sol` | `contracts/AgglayerGateway.sol` |

### 3.3 Directory Structure Reorganization

The following directories were moved from `contracts/v2/` to `contracts/`:

| Directory | Old Path | New Path |
|-----------|----------|----------|
| `aggchains/` | `contracts/v2/aggchains/` | `contracts/aggchains/` |
| `consensus/` | `contracts/v2/consensus/` | `contracts/consensus/` |
| `interfaces/` | `contracts/v2/interfaces/` | `contracts/interfaces/` |
| `lib/` | `contracts/v2/lib/` | `contracts/lib/` |
| `mocks/` | `contracts/v2/mocks/` | `contracts/mocks/` |
| `newDeployments/` | `contracts/v2/newDeployments/` | `contracts/newDeployments/` |
| `periphery/` | `contracts/v2/periphery/` | `contracts/periphery/` |
| `previousVersions/` | `contracts/v2/previousVersions/` | `contracts/previousVersions/` |
| `sovereignChains/` | `contracts/v2/sovereignChains/` | `contracts/sovereignChains/` |

### 3.4 Legacy Contracts Moved to previousVersions/

Several legacy contracts were moved from the root `contracts/` directory to `contracts/previousVersions/`:

| Contract | Old Path | New Path |
|----------|----------|----------|
| `PolygonZkEVM.sol` | `contracts/PolygonZkEVM.sol` | `contracts/previousVersions/PolygonZkEVM.sol` |
| `PolygonZkEVMBridge.sol` | `contracts/PolygonZkEVMBridge.sol` | `contracts/previousVersions/PolygonZkEVMBridge.sol` |
| `PolygonZkEVMGlobalExitRoot.sol` | `contracts/PolygonZkEVMGlobalExitRoot.sol` | `contracts/previousVersions/PolygonZkEVMGlobalExitRoot.sol` |

### 3.5 Import Path Updates

All import statements were systematically updated to reflect the new flat structure:

#### Example in AgglayerManager.sol:
**Before:**
```solidity
import "./interfaces/IAgglayerGER.sol";
import "../interfaces/IPolygonZkEVMBridge.sol";
import "../lib/EmergencyManager.sol";
```

**After:**
```solidity
import "./interfaces/IAgglayerGER.sol";
import "./interfaces/IPolygonZkEVMBridge.sol";
import "./lib/EmergencyManager.sol";
```

### 3.6 Interface Name Reversions

Some interface names were reverted back to maintain compatibility:

| Contract | Interface Used Before | Interface Used After |
|----------|----------------------|---------------------|
| `AgglayerManager.sol` | `IAgglayerManager` | `IPolygonRollupManager` |

## 4. Detailed Directory Analysis

### 4.1 Consensus Directory Structure
```
contracts/consensus/
├── pessimistic/
│   └── PolygonPessimisticConsensus.sol
├── validium/
│   ├── PolygonDataCommittee.sol
│   └── PolygonValidiumEtrog.sol
└── zkEVM/
    ├── PolygonZkEVMEtrog.sol
    └── PolygonZkEVMExistentEtrog.sol
```

### 4.2 Aggchains Directory Structure
```
contracts/aggchains/
├── AggchainECDSAMultisig.sol
└── AggchainFEP.sol
```

### 4.3 Sovereign Chains Directory Structure
```
contracts/sovereignChains/
├── AggOracleCommittee.sol
├── AgglayerBridgeL2.sol
└── AgglayerGERL2.sol
```


