# 4.1.10 Migration Paths

## 1. Summary Table
This section outlines the migration paths between different smart contract implementations.

|                             |      New      | PolygonPessimisticConsensus | AggchainECDSAMultisig | AggchainFEP_OLD | AggchainFEP_New |
|:---------------------------:|:-------------:|:---------------------------:|:---------------------:|:---------------:|:---------------:|
| PolygonPessimisticConsensus | :red_circle:  |        :red_circle:         |     :white_check_mark:     |  :red_circle:   |  :red_circle:   |
|       AggchainFEP_OLD       | :red_circle:  |        :red_circle:         |     :red_circle:      |  :red_circle:   |  :white_check_mark:  |
|    AggchainECDSAMultisig    | :white_check_mark: |        :red_circle:         |     :red_circle:      |  :red_circle:   |  :white_check_mark:  |
|       AggchainFEP_New       | :white_check_mark: |        :red_circle:         |     :red_circle:      |  :red_circle:   |  :red_circle:   |
|       zkEVM/Validium        | :white_check_mark: |        :red_circle:         |     :white_check_mark:     |  :red_circle:   |  :white_check_mark:  |

## 2. Supported Migration Paths

### 2.1 PolygonPessimisticConsensus → AggchainECDSAMultisig

**Summary:**

This migration path involves obsoleting all PolygonPessimisticConsensus rollupTypes and upgrading existing PolygonPessimisticConsensus deployments to the new ECDSA multisig consensus type. The migration maintains the same configuration with a threshold of 1 and signers set to `[trustedSequencer]`, ensuring backwards compatibility with the aggsender component.

**Key Points:**

- **Automatic Process:** Automatically handled by Polygon - chains remain agnostic to the upgrade
- **Configuration Preservation:** Keeps the same configuration during migration
- **Future Compatibility:** Any future changes will require aggsender component upgrades
- **Backwards Compatibility:** Maintains compatibility with existing aggsender infrastructure

**Migration Process:**

1. **Create New Rollup Type:** 
   - Creates new rollupTypeID with `VerifierType: ALGateway` + `AggchainECDSAMultisig`

2. **Execute Migration:**
   - Uses `AgglayerManager.updateRollup.migrateFromLegacyConsensus` function
   - Converts existing PolygonPessimisticConsensus to AggchainECDSAMultisig
   - Preserves all existing state and configuration

**Default Configuration:**

- **Threshold:** `1` (single signature required)
- **Signers:** `[trustedSequencer]` (existing trusted sequencer becomes the signer)
- **Verification Type:** `ALGateway` (new verification framework)

**Technical Requirements:**

- `_initializerVersion = 1` (initialized as PessimisticConsensus)
- Admin permissions for migration execution
- Existing PolygonPessimisticConsensus deployment must be active

**Impact:**

- **For Chains:** Transparent upgrade with no operational changes required
- **For Operators:** Maintains existing operational procedures
- **For Developers:** Enhanced multisig capabilities become available
- **For Aggsender:** Continues to work with existing interface

### 2.2 AggchainFEP → AggchainFEP (V2 → V3 Upgrade)

**Summary:**

This migration path upgrades existing AggchainFEP deployments to the new consensus type, adding ECDSA signature capabilities at the PP (Pessimistic Proof) level. The upgrade represents a transition from V2 to V3 of the OP stack and OP smart contracts, introducing breaking changes that require coordinated component upgrades.

**Key Points:**

- **Version Upgrade:** OP stack and OP SC upgrade from V2 to V3
- **Signature Enhancement:** Adds ECDSA signature validation at PP level
- **Breaking Changes:** Requires coordinated upgrades across all components

**Migration Process:**

1. **Create New Rollup Type:**
   - Creates new rollupTypeID with `VerifierType: ALGateway` + `AggchainFEP`
   - Configures enhanced FEP capabilities with PP-level ECDSA support

2. **Execute Migration:**
   - Uses `AgglayerManager.updateRollup.upgradeFromPreviousFEP` function
   - Upgrades existing AggchainFEP to new consensus type
   - Maintains existing proving configuration while adding signature capabilities

**Default Configuration:**

- **Threshold:** `1` (single signature required)
- **Signers:** `[trustedSequencer]` (existing trusted sequencer becomes the signer)
- **Verification Type:** `ALGateway` with enhanced FEP capabilities
- **OP Stack Version:** V2 → V3 upgrade

**Technical Requirements:**

- `_initializerVersion = 2` (previous FEP version)
- `aggchainSignersHash = bytes32(0)` (no signers hash set)
- Existing AggchainFEP deployment must be active
- Coordinated upgrade planning with all ecosystem components

**Impact:**

- **For Chains:** Breaking changes require careful coordination and planning
- **For Operators:** Enhanced security through PP-level ECDSA validation
- **For Developers:** Access to new FEP features and OP stack V3 capabilities

**Coordination Notes:**

- **Breaking Changes:** This upgrade introduces breaking changes requiring ecosystem-wide coordination
- **Component Dependencies:** All related components must be upgraded in coordination
- **Timeline Coordination:** Requires careful planning to minimize disruption

### 2.3 New AggchainECDSAMultisig (Fresh Deployment)

**Summary:**

This path creates a new deployment path for chains that exclusively use PP (Pessimistic Proof) without any ZK proving components. This approach provides a simpler, more efficient solution for chains that don't require the complexity of ZK proofs and prefer pure ECDSA multisig validation.

**Key Points:**

- **PP-Only Approach:** New path specifically designed for chains using only Pessimistic Proof
- **Simplified Architecture:** Eliminates ZK proving complexity for chains that don't need it
- **ECDSA Focus:** Pure ECDSA multisig validation without hybrid approaches
- **Fresh Deployment:** Clean initialization path for new aggchain deployments

**Process (requires two L1 transactions):**

1. **Create New Rollup Type:**
  - Creates new rollupTypeID with `VerifierType: ALGateway` + `AggchainECDSAMultisig`
  - Configures PP-only verification without ZK components

2. **Create New Aggchain:**
  - Uses `AgglayerManager.attachAggchainToAL.initAggchainManager` function
  - Establishes new aggchain with ECDSA multisig consensus

3. **Initialize Chain:**
  - Uses `AggchainECDSAMultisig.initialize` function
  - Sets up pure ECDSA multisig configuration

### 2.4 New AggchainFEP (Fresh Deployment)

**Summary:**

This path creates a new deployment path for chains that use aggchain-proof (OP-FEP + bridge-constraints) + PP hybrid consensus.

**Key Points:**

- **Hybrid Approach:** Combines aggchain proof with PP (Pessimistic Proof)
- **Dual Validation:** Supports both ZK proving and ECDSA signature validation
- **Advanced Architecture:** Full-featured aggchain with comprehensive proving capabilities
- **Fresh Deployment:** Clean initialization path for new FEP aggchain deployments

**Process (requires two L1 transactions):**

1. **Create New Rollup Type:**
   - Creates new rollupTypeID with `VerifierType: ALGateway` + `AggchainFEP`
   - Configures hybrid OP aggchain proof + PP verification capabilities

2. **Create New Aggchain:**
   - Uses `AgglayerManager.attachAggchainToAL.initAggchainManager` function
   - Establishes new aggchain with FEP consensus and proving capabilities

3. **Initialize Chain:**
   - Uses `AggchainFEP.initialize` function
   - Sets up OP-V3 configuration and ECDSA parameters