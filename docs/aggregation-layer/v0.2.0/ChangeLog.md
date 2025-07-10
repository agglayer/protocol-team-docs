# SC ChangeLog
This document summarizes most important changes on the SC side.
You can also check the [full git diff](https://github.com/0xPolygonHermez/zkevm-contracts/compare/v8.0.0-fork.12...v9.0.0-rc.3-pp)

[TOC]

## **TLDR**
### **Structs**
- Add new parameters in [RollupData struct](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/PolygonRollupManager.sol#L78)
- Add new parameters in [RollupType struct](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/PolygonRollupManager.sol#L45)
- Add helper struct [RollupDataReturn](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/PolygonRollupManager.sol#L119) to return data for StateTransistion chains to maintain backwards compatibility
- Add helper struct [RollupDataReturnV2](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/PolygonRollupManager.sol#L150) to return all rollup data

==`RollupDataReturnV2` --> any software should migrate to this struct to support all rollups with all its information==

### **VerifierTypes**
- Add verifiers types: [StateTransition](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/interfaces/IPolygonRollupManager.sol#L311) & [Pessimistic](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/interfaces/IPolygonRollupManager.sol#L312)

### **Events**
- Updated [`AddNewRollupType`](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/PolygonRollupManager.sol#L304)
- Updated [`AddExistingRollup`](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/PolygonRollupManager.sol#L334)
- Add [`UpdateRollupManagerVersion`](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/PolygonRollupManager.sol#L391)

### **Functions**
- Updated SC function [`addNewRollupType`](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/PolygonRollupManager.sol#L432)
- Updated SC function [`addExistingRollup`](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/PolygonRollupManager.sol#L596)
- Add SC function to verify pessimistoc proofs [`verifyPessimisticTrustedAggregator`](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/PolygonRollupManager.sol#L1046)
- Add SC function [`rollupIDToRollupData`](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/PolygonRollupManager.sol#L1484) to retrieve StateTransistion rollupData to maintain backwards compatibility
- Add SC function [`rollupIDToRollupDataV2`](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/PolygonRollupManager.sol#L1509) to retrieve full rollupData(link)

## **PolygonPessimisticConsensus.sol**
### **Description**
Consensus SC to be deployed every time a new sovereign chain [is created](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/PolygonRollupManager.sol#L507) by the rollup manager.
It inherits from [`PolygonConsensusBase`](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/lib/PolygonConsensusBase.sol) as the other consensus implemented: [`PolygonValidumEtrog`](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/consensus/validium/PolygonValidiumEtrog.sol) & [`PolygonZkEVMEtrog`](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/consensus/zkEVM/PolygonZkEVMEtrog.sol)

### **Changes**
It adds a new function: `getConsensusHash`
```solidity
/**
* Note Return the necessary consensus information for the proof hashed
*/
function getConsensusHash() public view returns (bytes32) {
    return keccak256(abi.encodePacked(CONSENSUS_TYPE, trustedSequencer));
}
```
Note that [`trustedSequencer`](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/lib/PolygonConsensusBase.sol#L48) address can be [modified](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/lib/PolygonConsensusBase.sol#L181) at any time by the [rollup admin](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/lib/PolygonConsensusBase.sol#L42)

## **PolygonRollupManager.sol**
### **Description**
Allow to create a new kind of rollupTypes based on the Verifier type.
Pending states has been removed (related to decentralize aggregator) in order to clean the SC and reduce the bytecode.

### **Changes**
#### VerifierType
Introduced [two types of Verifiers](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/interfaces/IPolygonRollupManager.sol#L310):
```solidity
enum VerifierType {
        StateTransition,
        Pessimistic
    }
```
- `StateTransition`: verifies state transition constraint function. Consensus to support this verifiers are `PolygonValidumEtrog` & `PolygonZkEVMEWtrog`
- `Pessimistic`: verifies the [pessimisitc circuit](https://github.com/agglayer/agglayer/tree/main/crates/pessimistic-proof-program) contraints. Consensus to support this verifiers are `PolygonPessimisticConsensus`

#### AddNewRollupType
[Function to add new rollups has been adapted](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/PolygonRollupManager.sol#L432) in order to support creation of new rollups with Pessimistic verifier.

Event has been changed in order to include data related to Pessimistic verifiers:
```solidity
/**
* @dev Emitted when a new rollup type is added
*/
event AddNewRollupType(
    uint32 indexed rollupTypeID,
    address consensusImplementation,
    address verifier,
    uint64 forkID,
    VerifierType rollupVerifierType,
    bytes32 genesis,
    string description,
    bytes32 programVKey
);
```
New parameter `programVKey`: identifier of the program that will be proven in SP1 Verifier

==Note: If any software rely on this event it should be changed==

#### verifyPessimisticTrustedAggregator
[Function](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/PolygonRollupManager.sol#L1046) to verify Pessimsitic verifiers types.
Important to notice that a chain using this verification will update its LER. Therefore, it will also update the RER and the GER.
Current bridge services rely on `VerifyBatchesTrustedAggregator` event to track RER tree.
Hence, same event signature has been maintained for Pessimistic verifiers
```solidity
// Same event as verifyBatches to support current bridge service to synchronize everything
emit VerifyBatchesTrustedAggregator(
    rollupID,
    0, // final batch: does not apply in pessimistic
    bytes32(0), // new state root: does not apply in pessimistic
    newLocalExitRoot,
    msg.sender
);
```

#### Versioning
[New constant](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v9.0.0-rc.3-pp/contracts/v2/PolygonRollupManager.sol#L235) has been added in order to check the PolygonRollupManager.sol version.
```solidity
// Current rollup manager version
    string public constant ROLLUP_MANAGER_VERSION = "pessimistic";
```
It will be updated on each upgrade.