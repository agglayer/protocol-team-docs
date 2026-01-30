# Sovereign Contracts Roles

Contracts used in sovereign chains: **AgglayerBridgeL2** & **AgglayerGERL2**

---

## 1. AgglayerBridgeL2

| Role | Description |
|------|-------------|
| `bridgeManager` | Manages custom tokens remapping and has the ability to clear/set claims |
| `emergencyBridgePauser` | Can pause the bridge in case of emergency |
| `emergencyBridgeUnpauser` | Can unpause the bridge |
| `proxiedTokensManager` | Admin of wrapped token proxies, can upgrade wrapped token implementations |

### bridgeManager

- **Functionality**: 
  - Set custom sovereign token addresses (`setMultipleSovereignTokenAddress`, `setSovereignWETHAddress`)
  - Remove legacy sovereign token addresses (`removeLegacySovereignTokenAddress`)
  - Deploy wrapped tokens and remap them (`deployWrappedTokenAndRemap`)
  - Transfer the bridgeManager role (`setBridgeManager`)
- **Security Assumptions**: Very high. Setting custom tokens mapping could redirect funds if misconfigured --> worst case scenario, steal all users funds of that network. Should be carefully managed.
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
- **Security Assumptions**: Very high. Can upgrade token logic which could affect user funds --> worst case scenario, steal all users funds of that network. Should be carefully managed.
- **Recommended Account Type**: Timelock (same as bridge proxy admin, typically PolygonTimelock)

---

## 2. AgglayerGERL2

| Role | Description |
|------|-------------|
| `globalExitRootUpdater` | Injects GER into the bridge SC |
| `globalExitRootRemover` | Removes GER from the Bridge SC and manages emergency operations on the bridge |

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
  - **On AgglayerBridgeL2**: 
    - Unset/set multiple claims (`unsetMultipleClaims`, `setMultipleClaims`)
    - Move LET backward/forward (`backwardLET`, `forwardLET`) - only during emergency state
    - Set local balance tree (`setLocalBalanceTree`) - only during emergency state
    - Force emit detailed claim events (`forceEmitDetailedClaimEvent`)
- **Security Assumptions**: Very high security risk. Controller could steal funds --> worst case scenario, steal all users funds of that network. Should be carefully managed. Has powerful emergency recovery capabilities.
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
