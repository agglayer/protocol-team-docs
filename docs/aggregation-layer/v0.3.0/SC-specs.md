# SC Specifications
[TOC]
## 1. Overview
[AggLayer v0.3.0](https://github.com/agglayer/protocol-research/blob/main/docs/ADRs/v0.3.0.md) adds the support for any chain to specify its own requirements. It is up to chain to specify what it does as long as it follows a generic interface provided by the agglayer.
Therefore, the agglayer will become agnostic to the chain requirements (EVM, non-EVM, DA source, consensus, ...). That means that any chain can be connected to the aggLayer regardless its execution and consensus layer. Current version only supports EVM chains though.
Smart contracts will be adapted to support generic chains that will be attached to the aggLayer.
A generic interface will be provided so any chain can do its own logic that could be attached to the aggLayer.

In this first phase, aggLayer will provide two default chain types to be selected: ECDSA signature & FEP (full execution proof).
Smart contract will let choose between one of those.
Long term goal is to fully open chain registration as lomng as the chain fulfills folows a generic interface.

### 1.1. Glossary
- `aggchain`: chain connected to the agglayer
    - all definition related to aggchains can be found on [this specification](https://github.com/agglayer/protocol-research/blob/main/docs/ADRs/v0.3.0.md#generic-aggchains)

### 1.2. Resources
- [Contracts Specification](https://github.com/agglayer/specs/blob/spec-contracts/specs/contracts.md)
- [Specification Pessimistic circuit v0.3.0](https://github.com/agglayer/protocol-research/blob/main/docs/ADRs/v0.3.0.md#handling-generic-aggchains0e4e2ec8eab179621f62ff54c7baa36081cbdbb9b768b0336db1e3dda21e6a5aR3)
- [Specification aggchain ECDSA](https://github.com/agglayer/protocol-research/blob/main/docs/ADRs/v0.3.0.md#ecdsa)
- [Specification aggchain FEP](https://github.com/agglayer/protocol-research/blob/main/docs/ADRs/v0.3.0.md#fep)
- [Implementation decisions and iterations on the SC specifications](https://hackmd.io/L7iY0M5bR_C4YWRqlCjsVg)
- [SC implementations](https://github.com/0xPolygonHermez/zkevm-contracts/tree/feature/ongoing-v0.3.0)
- [Test-vectors](https://github.com/0xPolygonHermez/zkevm-contracts/tree/feature/ongoing-v0.3.0/test/test-vectors)

### 1.3. Requirements
- [PolygonRollupManager](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.5-pp/contracts/v2/PolygonRollupManager.sol) to support generic chains
- Pessimistic program will only have one version running
- Pessimistic program updates to be released on all chains at the same time
- Pessimistic program updates managed by aggLayer
- Each chain to freely choose its program management. Two options are given:
    - `default`: management provided by the aggLayer
    - `custom`: own management
- Generic interface to allow any chain to specify its own logic

### 1.4. ChangeLog
https://github.com/agglayer/agglayer-contracts/compare/v9.0.0...v10.0.0-rc.8

### 1.5. Breaking changes
- Function to create new rollups has been renamed to [attachChainToAL](#64-create-new-chain)
    - old chains (zkEVM/Validiums/pp-v0.2.0) will need to [encode its initialize data](https://github.com/agglayer/agg-contracts-internal/blob/v10.0.0-rc.3/contracts/v2/PolygonRollupManager.sol#L577-L578). Util function available [here](https://github.com/agglayer/agg-contracts-internal/blob/v10.0.0-rc.3/src/utils-common-aggchain.js#L80)
- Event [addExistingRollup](https://github.com/agglayer/agg-contracts-internal/blob/v10.0.0-rc.3/contracts/v2/PolygonRollupManager.sol#L350) signature has been changed since a new parameter `initPessimisticRoot` ha sbeen added
- [New functions](#66-pretty-rollupdata) to properly see therscan rollup data has been added
- Function [verifyPessimisticProof](#65-verify-pessimitic-proof) signature has been changed. Added `customChainData` for aggchains v0.3.0

### 1.6. Table agglayer chains supported
|    Chain     |  verifierType   |        SC consensus         |  Proofs/Prover   |              Client              |
|:------------:|:---------------:|:---------------------------:|:----------------:|:--------------------------------:|
|    zkEVM     | StateTransition |      PolygonZkEVMEtrog      |   FEP # Hermez   |            cdk-erigon            |
|  Valididum   | StateTransition |    PolygonValidiumEtrog     |   FEP # Hermez   |            cdk-erigon            |
| v0.2.0-ECDSA |   Pessimistic   | PolygonPessimisticConsensus |     PP # SP1     |      cdk-erigon OR op-stack      |
| v0.3.0-ECDSA |    ALGateway    |        AggchainECDSA        |     PP # SP1     | not supported (aggkit not built) |
|  v0.3.0-FEP  |    ALGateway    |         AggchainFEP         | (PP + FEP) # SP1 |             op-stack             |

#### Migration paths supported
- From `v0.2.0-ECDSA` to `v0.3.0-FEP`

## 7. Sovereign SCs updates  
This section introduces new features and functionalities in the [Sovereign SC](../v0.2.0/SovereignChains/Intro.md). Most are designed to support the [FEP program](https://github.com/agglayer/protocol-research/blob/main/docs/ADRs/v0.3.0.md#fep).

### 7.1 GlobalExitRootManagerL2SovereignChain
#### 7.1.1 `insertedGERHashChain` & `removedGERHashChain`  
All GERs (Global Exit Roots) inserted on L2 must be verifiable against a valid `L1InfoTreeRoot`. This ensures the validity of every GER injected into the chain.  
However, an invalid GER may still be injected due to:

- malicious behavior by the `globalExitRootUpdater`, or  
- a bug in the GER injection process (e.g., in the `aggOracle` component).

An invalid GER cannot be proven against any valid `L1InfoTreeRoot`, which will cause the chain to stall until that GER is removed.

A naïve approach would be to trigger a reorg on L2 to remove the offending GER transaction and reprocess subsequent transactions. But L2 reorgs are undesirable because they:

- severely damage chain and product reputation, and  
- could enable double-spending in third-party bridges.

To avoid a reorg, the `removedGERHashChain` feature was introduced. Removing a GER in this context must be treated as an *emergency action* to restore progress without triggering a full reorg.

### 7.2 BridgeL2SovereignChain

### 7.2.1 Unused bits on `globalIndex` are set to 0
Forces all unused bits on the `globalIndex` to be set to 0. This has no implication on `hermez-prover` chains, but it does affect `PP` and `FEP` chains, since `globalIndex` is used in both the pessimistic and FEP programs.

Both programs assume that the unused bits are 0. Therefore, if any user makes a claim where those bits are set to a non-zero value, it could potentially trigger an error in the program, making it impossible to generate a proof.

To resolve this, a change was introduced directly in the smart contract to prevent the propagation of unused bits to other components. 

> Note: An alternative solution could have been modifying the components to allow arbitrary values for the unused bits.

#### 7.2.2 LocalBalanceTree

Specification [LocalBalanceTree](https://github.com/agglayer/specs/blob/spec-contracts/specs/contracts.md).

#### 7.2.3 `activateEmergencyState` & `deactivateEmergencyState`
Adds the ability to pause and unpause the bridge. Each action is controlled by its own dedicated address:

- `activateEmergencyState` → `emergencyBridgePauser`
- `deactivateEmergencyState` → `emergencyBridgeUnpauser`

This functionality should be treated as an emergency mechanism. Entering into an emergency state should be executed by a `security council` address to act swiftly while requiring external consensus to trigger the action.

Re-enabling the bridge (i.e., deactivating the emergency state) does not introduce any security concerns, so it can be safely managed by a multisig controlled by the chain itself.

#### 7.2.4 `claimedGlobalIndexHashChain` & `unsetGlobalIndexHashChain`  
Every claim made on L2 must correspond to a claim processed by the pessimistic program. To enforce this, the contract tracks a hash chain of all claims, which the program must reconstruct.

If an invalid GER was used (as noted in section 7.2), it can lead to invalid claims on L2. In this situation:

1. A reorg has **not** occurred, but  
2. Invalid claims exist due to the bad GER.

These invalid claims can leave the pessimistic program in a state where some claims cannot be proven. To rectify this, the `unsetMultipleClaims` function was added, allowing invalid claims to be rolled back. Like GER removal, this must be treated as an *emergency action* and triggered before any investigation.

**Important note:** When a claim is unset, the user still receives their funds from the Bridge, meaning the Bridge’s balance becomes incorrect. It’s up to the chain itself to rebalance the Bridge (e.g., by bridging tokens and sending them to `0x00...00`).

# Smart contracts version updates
## Open zeppelin
### Updated `openzeppelin/contracts@5.0.0` to `openzeppelin/contracts@5.2.0`
- **Rationale**: When implementing `ReentrancyGuard` at `PolygonRollupManager`, it's very suitable to use the `ReentrancyGuardTransient.sol` that is only available at `openzeppelin/contracts@5.2.0` because it doesn't modify the storage layer as is using the reentrancy variable as transient.
- **Changes**:
    - `openzeppelin/contracts@5.0.0` is used in the following contracts `TransparentUpgradeableProxy`, `ERC1967Proxy`, `IERC1967` and `ProxyAdmin` which **remain unchanged** bumping the version.
    - `ERC1967Utils` is also used but it has "breaking changes": https://github.com/OpenZeppelin/openzeppelin-contracts/releases/tag/v5.1.0-rc.0 : Removed duplicate declaration of the Upgraded, AdminChanged and BeaconUpgraded events. These events are still available through the IERC1967 interface located under the contracts/interfaces/ directory. Minimum pragma version is now 0.8.21. This change doesn't break anything because the events are still visible exactly the same way from the aforementioned interface.
### Update pragma version `0.8.20` to `0.8.28`
- **Rationale**: Bumping to `0.8.28` has many features
    - Stack-to-memory mover always enabled via-IR: [link](https://soliditylang.org/blog/2023/07/19/solidity-0.8.21-release-announcement/)
    - Support transient storage [link](https://soliditylang.org/blog/2024/01/26/solidity-0.8.24-release-announcement/)
    - MCOPY opcode (gas optimizations) [link](https://soliditylang.org/blog/2024/03/14/solidity-0.8.25-release-announcement/)
    - Custom errors support require [link](http://soliditylang.org/blog/2024/05/21/solidity-0.8.26-release-announcement/)
    - Full support for transient state variables [link](https://soliditylang.org/blog/2024/10/09/solidity-0.8.28-release-announcement/)
- **Changes**:
    - The bytecode of the compiled contracts has changed -> A new folder with all the contracts with the previous version has been created for upgrading testing purposes
    - The TransparentProxys created by rollup manager when a rollup is created now they will have a different bytecode