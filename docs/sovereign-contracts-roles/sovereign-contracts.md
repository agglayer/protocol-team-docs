# Sovereign Chain Contract Roles

Roles in the L2 contracts deployed on sovereign chains.

Source: [agglayer-contracts v12.2.2](https://github.com/agglayer/agglayer-contracts/releases/tag/v12.2.2)

---

## 1. AgglayerBridgeL2

[Source](https://github.com/agglayer/agglayer-contracts/blob/v12.2.2/contracts/sovereignChains/AgglayerBridgeL2.sol)

Inherits from `AgglayerBridge`. Defines custom address-based roles with two-step transfer.

| Role | Description |
|------|-------------|
| `bridgeManager` | Manages custom token remapping and has the ability to clear/set claims |
| `emergencyBridgePauser` | Can pause the bridge in case of emergency |
| `emergencyBridgeUnpauser` | Can unpause the bridge |
| `proxiedTokensManager` | Admin of wrapped token proxies, can upgrade wrapped token implementations |
| `globalExitRootRemover` | (from AgglayerGERL2) Emergency operations on the bridge |

### bridgeManager

- **Functionality**:
    - Set custom sovereign token addresses (`setMultipleSovereignTokenAddress`, `setSovereignWETHAddress`)
    - Remove legacy sovereign token addresses (`removeLegacySovereignTokenAddress`)
    - Deploy wrapped tokens and remap them (`deployWrappedTokenAndRemap`)
    - Transfer the bridgeManager role (`setBridgeManager`)
- **Security Assumptions**: Very high. Setting custom token mappings could redirect funds if misconfigured — worst case scenario, steal all users funds of that network. Should be carefully managed.
- **Recommended Account Type**: Timelock (specified by the chain itself after bootstrapping phase)

### emergencyBridgePauser

- **Functionality**:
    - Activate emergency state on the bridge (`activateEmergencyState`)
    - Transfer the emergencyBridgePauser role (`transferEmergencyBridgePauserRole`)
- **Security Assumptions**: Medium-High. Can halt all bridge operations but cannot steal funds directly.
- **Recommended Account Type**: Multisig (needs to act fast in emergencies)

### emergencyBridgeUnpauser

- **Functionality**:
    - Deactivate emergency state on the bridge (`deactivateEmergencyState`)
    - Transfer the emergencyBridgeUnpauser role (`transferEmergencyBridgeUnpauserRole`)
- **Security Assumptions**: Medium. Can resume bridge operations after emergency.
- **Recommended Account Type**: Multisig or Timelock (depending on security requirements)

### proxiedTokensManager

- **Functionality**:
    - Admin of all `TokenWrappedTransparentProxy` contracts deployed by the bridge
    - Can upgrade wrapped token implementations (`upgradeTo`, `upgradeToAndCall`)
    - Can change admin of wrapped token proxies (`changeAdmin`)
    - Transfer the proxiedTokensManager role (`transferProxiedTokensManagerRole`)
- **Security Assumptions**: Very high. Can upgrade token logic which could affect user funds — worst case scenario, steal all users funds of that network. Should be carefully managed.
- **Recommended Account Type**: Timelock (same as bridge proxy admin, typically PolygonTimelock)

### globalExitRootRemover

Read from `AgglayerGERL2.globalExitRootRemover()`. On `AgglayerBridgeL2`:

- **Functionality**:
    - Unset/set multiple claims (`unsetMultipleClaims`, `setMultipleClaims`)
    - Move LET backward/forward (`backwardLET`, `forwardLET`) — only during emergency state
    - Set local balance tree (`setLocalBalanceTree`) — only during emergency state
    - Force emit detailed claim events (`forceEmitDetailedClaimEvent`)
- **Security Assumptions**: Very high security risk. Controller could steal funds — worst case scenario, steal all users funds of that network. Should be carefully managed. Has powerful emergency recovery capabilities.
- **Recommended Account Type**: Multisig (needs to act fast to unblock the chain in emergencies)

---

## 2. AgglayerGERL2

[Source](https://github.com/agglayer/agglayer-contracts/blob/v12.2.2/contracts/sovereignChains/AgglayerGERL2.sol)

| Role | Description |
|------|-------------|
| `globalExitRootUpdater` | Injects GER into the bridge SC |
| `globalExitRootRemover` | Removes GER from the Bridge SC and manages emergency operations on the bridge |
| `bridgeAddress` | (immutable) Can update exit root from bridge deposits |

### globalExitRootUpdater

- **Functionality**:
    - Insert new global exit roots (`insertGlobalExitRoot`)
    - Transfer the globalExitRootUpdater role (`transferGlobalExitRootUpdater`)
    - If set to zero address, `block.coinbase` (sequencer) can insert GERs
- **Security Assumptions**: Medium-High. This address has the ability to insert invalid GERs, unable to steal funds of the agglayer and halting the network but might be able to steal third-party bridges.
- **Recommended Account Type**: EOA carefully managed, since must send lots of transactions

### globalExitRootRemover

- **Functionality**:
    - Remove global exit roots (`removeGlobalExitRoots`)
    - Transfer the globalExitRootRemover role (`transferGlobalExitRootRemover`)
- **Security Assumptions**: Very high security risk. Also gates many emergency functions on `AgglayerBridgeL2` (see above). Setting to `address(0)` disables all emergency exit root removal and bridge manipulation — recommended for FEP chains.
- **Recommended Account Type**: Multisig (needs to act fast to unblock the chain in emergencies)

---

## Summary Table

| Contract | Role | Security Risk | Recommended Account Type |
|----------|------|---------------|-------------------------|
| AgglayerBridgeL2 | `bridgeManager` | Very High | Timelock |
| AgglayerBridgeL2 | `emergencyBridgePauser` | Medium | Multisig |
| AgglayerBridgeL2 | `emergencyBridgeUnpauser` | Medium | Multisig/Timelock |
| AgglayerBridgeL2 | `proxiedTokensManager` | Very High | Timelock |
| AgglayerGERL2 | `globalExitRootUpdater` | Medium-High | EOA (carefully managed) |
| AgglayerGERL2 | `globalExitRootRemover` | Very High | Multisig |
