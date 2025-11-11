## AgglayerManager `al-v0.3.1` → `v1.0.0`

## 1. Overview

The `AgglayerManager` contract is the renamed and refactored version of `PolygonRollupManager`.

## 2. Key Changes from PolygonRollupManager

### 2.1 Version Interface Implementation

**New Feature:**

The contract now implements `IVersion` interface, adding:

```solidity
contract AgglayerManager is
    PolygonAccessControlUpgradeable,
    EmergencyManager,
    LegacyZKEVMStateVariables,
    PolygonConstantsBase,
    IAgglayerManager,
    ReentrancyGuardTransient,
    IVersion  // New interface
{
    function version() external pure returns (string memory) {
        return ROLLUP_MANAGER_VERSION;
    }
}
```

### 2.2 Version String Update

**Version Constant:**
- **Before:** `"al-v0.3.1"`
- **After:** `"v1.0.0"`

### 2.3 New Aggchain-Specific Update Logic

**Major Enhancement:** The contract now has TWO separate update functions:

#### `updateRollupByRollupAdmin` - Admin/Aggchain Manager Updates

```solidity
function updateRollupByRollupAdmin(
    ITransparentUpgradeableProxy rollupContract,
    uint32 newRollupTypeID
) external
```

For ALGateway rollups, validates aggchain manager and `AGGCHAIN_TYPE` compatibility:

```solidity
if (rollup.rollupVerifierType == VerifierType.ALGateway) {
    // Check aggchain manager is msg.sender
    if (IAggchainBase(address(rollupContract)).aggchainManager() != msg.sender) {
        revert OnlyAggchainManager();
    }
    
    // Check AGGCHAIN_TYPE compatibility
    if (IAggchainBase(address(rollupContract)).AGGCHAIN_TYPE() !=
        IAggchainBase(rollupTypeMap[newRollupTypeID].consensusImplementation).AGGCHAIN_TYPE()) {
        revert UpdateNotCompatible();
    }
}
```

For other rollups, uses original admin checks.

#### `updateRollup` - Role-Based Updates

```solidity
function updateRollup(
    ITransparentUpgradeableProxy rollupContract,
    uint32 newRollupTypeID,
    bytes memory upgradeData
) external onlyRole(_UPDATE_ROLLUP_ROLE)
```

Allows changing `rollupVerifierType` only when upgrading to ALGateway.

### 2.4 New Access Control Logic

**Key Changes:**

1. **Aggchain Manager Check:** For ALGateway rollups, validates that `msg.sender` is the aggchain manager instead of the admin
2. **AGGCHAIN_TYPE Compatibility:** Ensures that rollup types are compatible by checking their `AGGCHAIN_TYPE`
3. **Conditional Logic:** Maintains backward compatibility for non-ALGateway rollups
4. **Verifier Type Enum:** Uses `VerifierType` enum (StateTransition, Pessimistic, ALGateway) instead of compatibility ID

### 2.5 New Error Types

**Added Errors:**

- `OnlyAggchainManager()` - Thrown when a non-aggchain-manager tries to update an ALGateway rollup
- `UpdateNotCompatible()` - Thrown when trying to update to an incompatible AGGCHAIN_TYPE
- `OnlyStateTransitionChains()` - Thrown when operation only allowed for State Transition chains
- `StateTransitionChainsNotAllowed()` - Thrown when operation not allowed for State Transition chains
