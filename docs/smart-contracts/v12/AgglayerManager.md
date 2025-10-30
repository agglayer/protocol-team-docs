## AgglayerManager `al-v0.3.1` → `v1.0.0`

## 1. Overview

The `AgglayerManager` contract is the renamed and refactored version of `PolygonRollupManager`.

## 2. Key Changes from PolygonRollupManager

### 2.1 Version Interface Implementation

**New Feature:**

The contract now implements `IVersion` interface, adding:

```solidity
contract AgglayerManager is
    // ... existing inheritance
    IVersion  // New interface
{
    // New version function
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

**Major Enhancement:** The `updateRollup` function now includes specialized logic for ALGateway rollup types:

**Previous Logic:**
```solidity
function updateRollup(
    ITransparentUpgradeableProxy rollupContract,
    uint32 newRollupTypeID
) external {
    // Check admin of the network is msg.sender
    if (IPolygonRollupBase(address(rollupContract)).admin() != msg.sender) {
        revert OnlyRollupAdmin();
    }

    // Check all sequenced batches are verified
    if (rollup.lastBatchSequenced != rollup.lastVerifiedBatch) {
        revert AllSequencedMustBeVerified();
    }
}
```

**New Enhanced Logic:**
```solidity
function updateRollup(
    ITransparentUpgradeableProxy rollupContract,
    uint32 newRollupTypeID
) external {
    RollupData storage rollup = _rollupIDToRollupData[
        rollupAddressToID[address(rollupContract)]
    ];

    if (rollup.rollupVerifierType == VerifierType.ALGateway) {
        // NEW: Aggchain-specific validation
        
        // Check aggchain manager is msg.sender
        if (
            IAggchainBase(address(rollupContract)).aggchainManager() !=
            msg.sender
        ) {
            revert OnlyAggchainManager();
        }

        // Check AGGCHAIN_TYPE compatibility
        if (
            IAggchainBase(address(rollupContract)).AGGCHAIN_TYPE() !=
            IAggchainBase(
                rollupTypeMap[newRollupTypeID].consensusImplementation
            ).AGGCHAIN_TYPE()
        ) {
            revert UpdateNotCompatible();
        }
    } else {
        // Original logic for non-ALGateway rollups
        if (
            IPolygonRollupBase(address(rollupContract)).admin() !=
            msg.sender
        ) {
            revert OnlyRollupAdmin();
        }

        if (rollup.lastBatchSequenced != rollup.lastVerifiedBatch) {
            revert AllSequencedMustBeVerified();
        }
    }
}
```

### 2.4 New Access Control Logic

**Key Changes:**

1. **Aggchain Manager Check:** For ALGateway rollups, validates that `msg.sender` is the aggchain manager instead of the admin
2. **AGGCHAIN_TYPE Compatibility:** Ensures that rollup types are compatible by checking their `AGGCHAIN_TYPE`
3. **Conditional Logic:** Maintains backward compatibility for non-ALGateway rollups

### 2.5. New Error Types

**Added Error:**

- `OnlyAggchainManager()` - Thrown when a non-aggchain-manager tries to update an ALGateway rollup
- `UpdateNotCompatible()` - Thrown when trying to update to an incompatible AGGCHAIN_TYPE
