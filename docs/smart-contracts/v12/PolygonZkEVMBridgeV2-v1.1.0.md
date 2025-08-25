## PolygonZkEVMBridgeV2 `v1.0.0` → `v1.1.0`
[TOC]

## 1. BridgeLib Contract - Bytecode Optimization

### 1.1 Rationale for Bytecode Abstraction

The main motivation for creating the BridgeLib contract is **Ethereum's bytecode size limit**. Ethereum has a maximum contract bytecode size limit of **24,576 bytes (24KB)** established by EIP-170. As the bridge contract grows with new functionality, it approaches this limit, making deployment on Ethereum impossible.

**Key Benefits**:

- **Ethereum Compatibility**: Ensures the bridge contract can be deployed on Ethereum mainnet
- **Code Reusability**: Utility functions can be shared across multiple contracts
- **Maintainability**: Separates utility logic from core bridge functionality
- **Gas Optimization**: External library calls can be more gas-efficient for complex operations

### 1.2 Functions Moved to BridgeLib

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

### 1.3 Integration Changes in Main Bridge Contract

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

### 1.4 Bytecode Size Impact

**Before BridgeLib abstraction**:

- All utility functions were inline in the main bridge contract
- Contract approaching the 24KB bytecode limit
- Risk of deployment failure on Ethereum

**After BridgeLib abstraction**:

- Core bridge functionality remains in main contract
- Utility functions moved to separate BridgeLib contract
- Significant bytecode reduction in main contract
- Ethereum deployment compatibility ensured

### 1.5 Version Updates Related to BridgeLib

The bytecode abstraction is reflected in the version updates:

- **PolygonZkEVMBridgeV2**: `v1.0.0` → `v1.1.0`
    - Indicates the integration of BridgeLib for bytecode optimization
    - Maintains backward compatibility in the public interface
    - Internal implementation changes for permit and metadata handling