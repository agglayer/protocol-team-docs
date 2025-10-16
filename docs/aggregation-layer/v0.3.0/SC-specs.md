# SC Specifications

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

## 2. AggLayer Gateway Specifications
### 2.1. Description
This smart contract aims to route all proofs posted by the aggLayer (from chains that uses the pessimistic program).
Since the `AggLayer Gateway` contains the pessimistic program verificaton key, all chains that uses the `AggLayer Gateway` will be upgraded to use its latest version at the same time. This effectively means that a new version on the pessimistic program will **NOT** require a new rollupType.

It will also provide the management of:

- pessimistic proof routing (pessimistic program vKeys)
- default aggchain vkeys

### 2.2. Pessimistic proof routes
The pessimistic proof route is defined as follows:
```solidity
struct AggLayerVerifierRoute {
    address verifier;
    bytes32 pessimisticVKey;
    bool frozen;
}
```

where:

- `verifier`: SP1 verifier address
- `pessimisticVKey`: pessimistic program verification key
- `frozen`: a route cannot be longer used

The aggLayer will have 4 bytes embedded in the proof to select the route.

```solidity
mapping(bytes4 pessimisticVKeySelector => AggLayerVerifierRoute) public pessimisticVKeyRoutes;
```

The proof will look like:
```
[  ppSelector  |  SP1 proof ]
[ 4 bytes      |  X bytes   ]
```

where `SP1 proof` is:
```
[           SP1 proof          ]
[  SP1Selector  |  PLONK proof ]
[   4 bytes     |    Y bytes   ]
```

This approach allows to:

- aggLayer to select which route to use via the `ppSelector`
- have multiple version of the pessimistic program or just have one single valid route
- smooth routing upgrade by not forcing the SC upgrade to be synched with the component upgrade (aggLayer-node)
    - the new route version could be settled in advance
- quickly freeze a route if any critical issue is found on the pessimistic program or the SP1 Verifier

### 2.3. Defaut aggchain verification key
The default `aggchain_vkey` is defined as follows:
```solidity
mapping(bytes4 defaultAggchainSelector => bytes32 defaultAggchainVKey) public defaultAggchainVKeys;
```

The aggLayer will just add new default `aggchain_vkey` routed by a 4 bytes selector, the `defaultAggchainSelector`.
The aggLayer can add new versions of a default `aggchain_vkey` or update them.

This approach allows to:

- have multiple versions of the default `aggchain_vkey` or just have one (only updates)
- single SC transaction to upgrade all the chains that uses the default `aggchain_vkey`
- no action needed from chains on L1 to use a new default `aggchain_vkey`
    - probably run the proper component version
- if any issue is found on the default `aggchain_vkey`, it can be overwritten with the right one

### 2.4. AggLayerGateway Access control (roles)

|            Role            |      Description       |
|:--------------------------:|:----------------------:|
|     DEFAULT_ADMIN_ROLE     |   Grant/Revoke roles   |
|  AGGLAYER_ADD_ROUTE_ROLE   |       Add PP key       |
| AGGLAYER_FREEZE_ROUTE_ROLE |     Freeze PP key      |
| AGGCHAIN_DEFAULT_VKEY_ROLE | Add/Update default key |

#### DEFAULT_ADMIN_ROLE
- **Functionality**: Grants and revokes all roles in the contract.
- **Security Assumptions**: This role has complete control over the contract’s permissions, making it the most privileged and critical role.
- **Recommended Account Type**: Should be a timelock

#### AL_ADD_PP_ROUTE_ROLE
- **Functionality**: Allows adding new pessimistic proof verification key.
- **Security Assumptions**: Incorrect key additions can enable invalid proofs, leading to security risks. A malicious pessimistic key can compromise the bridge funds
- **Recommended Account Type**: Timelock

#### AL_FREEZE_PP_ROUTE_ROLE
- **Functionality**: Freezes existing PP keys, preventing further usage.
- **Security Assumptions**: On one hand, if a PP key is behaving wrongly, this role is critical for freezing it quickly to mitigate risks. On the other hand, it can perform a DDOS freezing all keys.
- **Recommended Account Type**: Externally Owned Account (EOA) or Multisig. A Multisig is preferred for security, but an EOA with high availability (i.e., always online) might be necessary for quick emergency response.

#### AGGCHAIN_DEFAULT_VKEY_ROLE
- **Functionality**: Manages default aggregation keys, allowing updates to default verification keys.
- **Security Assumptions**: Incorrect key additions can enable invalid proofs, leading to security risks. A malicious verification key can compromise the funds of a chain.
- **Recommended Account Type**: Timelock or multisig, a chain can choose to handle their own keys at any time. Security assumptions for aggchainDefaultVKeyRoleAddress are the same as for updating a rollup which currently is brought by a multisig.

## 3. Generic aggchains specification
### 3.1. Description
The following specification aims to provide a generic interface that any aggchain must follow in order to be attached to the aggLayer.
Each aggchain would need to interact with the RollupManager smart contract on different stages. Those interactions are needed to accomplish an specific interface.
Besides the interface, a base implementation will be provided to aggchains in order to have a base code to build from. Note that this base code is recommended to be followed by aggchains but not mandatory.

### 3.2. Aggchain interface
An aggchain smart contract must interact with the rollup manager in the following manner:


- Initialization:
      - interface
      ```solidity
      function initAggchainManager(address newAggchainManager) external;;
      ```
      - when the aggchain is created, the aggchain must provide its own initialization bytes.
- Proof is being verified and RollupManager contract calls aggchain contract to get its `aggchain_hash`:
```solidity
  /**
   * @notice Gets aggchain hash.
   * @dev Each chain should properly manage its own aggchain hash.
   * @param aggchainData agg chain data to build the consensus hash.
   */
  function getAggchainHash(bytes calldata aggchainData) external view returns (bytes32);
```
- Proof is verified and there is callback to the aggchain contract to handle the final chain settlement:
  ```solidity
  /**
   * @notice Callback from the PolygonRollupManager to update the chain's state.
   * @dev Each chain should properly manage its own state.
   * @param data Custom chain data to update chain's state
   */
  function onVerifyPessimistic(bytes calldata aggchainData) external;
  ```
## 4. Aggchain Base implementation
It is provided a base implementation of the aggchain in order to serve as a template for any aggchains that want to build its own implementation.
In order to maintain storage layout compatibility with previous `verifierType version: Pessimistic`, the old `PolygonConsensusBase` is inherited.
This design will allow previous chains (v0.2.0) to be upgraded to a new version (v0.3.0) mainting the storage layout and avoiding any error overwriting storage slots.
There are two key features on top of the `PolygonConsensusBase`:

- Flag to determine if the default vkeys are used (provided by the `ALGateway` smart contract)
- aggchain vkey management functionalities

### 4.1. Flag default vKey
```solidity
// Flag to enable/disable the use of the custom chain gateway to handle the aggchain keys. In case  of true (default), the keys are managed by the aggregation layer gateway
bool public useDefaultGateway;
```

### 4.2. Managing aggchain verification keys
The chain will be able to select its verification key through a selector, the `aggchainVKeySelector`.
It works very similar as the `ppSelector`, but instead of selecting the pessimistic verification key, it selects the aggchain verification key

The aggchain base code will store all the routed into a mapping:
```solidity
// AggchainVKeyRoutes mapping
mapping(bytes4 aggchainVKeySelector => bytes32 ownedAggchainVKey) public ownedAggchainVKeys;
```

This approach allows to:

- have multiple versions of the `aggchain_vkey` or just have one
- smooth routing upgrade by not forcing the SC action to be synched with the component upgrade
    - the new route version could be settled in advance
    - componenet will select which one to use
- if any issue is found on the `aggchain_vkey`, it can be overwritten with the right one

### 4.3. Roles
#### vKeyManager
- **Functionality**: Manages aggchain verification keys, insertions and updates. It can also enable/disable the usage of the default aggchain vkeys (managed by the ALGateway contract)
- **Security Assumptions**: A malicious verification key can compromise the funds of a chain (not the entire agglayer)
- **Recommended Account Type**: Timelock (specified by the chain itself)

#### admin
- **Functionality**: Allow to set the `trustedSequencer` and can manage aggchain upgrades with certain limitations:
    - cannot update to old `rollupTypeID`
    - cannot update to a different `rollupVerifierType`
- **Security Assumptions**: `trustedSequencer` usage depends on aggchaintype. Please refer to each aggchain for more details. Upgrades does not imply high security assumptions since it is capped to existing `rollupTypes`
- **Recommended Account Type**: Multisig

## 5. AggChain Types provided
Two default aggchain types will be provided to choose from:

- ECDSA
- FEP

Each aggchain provided is identified by 2 bytes:
```solidity
// ECDSA
bytes2 constant AGGCHAIN_TYPE = 0
// FEP
bytes2 constant AGGCHAIN_TYPE = 1
```

These 2 bytes are used to build the `aggchainVKeySelector` in case the chain opts for using the `defaultAggchainVKey`.
This has been done to enforce chains to not being able to select which type of aggchain they are. Smart contrct will force those 2 bytes so the default `defaultAggchainSelector` could be specified as:

```
[         aggchainVKeySelector          ]
[ aggchainVKeyVersion  |  AGGCHAIN_TYPE ]
[       2 bytes        |    2 bytes     ]
```

### 5.1. ECDSA
- **NEW AGGCHAIN**: custom initialization bytes
```solidity
// custom parsing of the initializeBytesAggchain
(
    // aggchainBase params
    bool _useDefaultGateway,
    bytes32 _initOwnedAggchainVKey,
    bytes4 _initAggchainVKeySelector,
    address _vKeyManager,
    // PolygonConsensusBase params
    address _admin,
    address _trustedSequencer,
    address _gasTokenAddress,
    string memory _trustedSequencerURL,
    string memory _networkName
) = abi.decode(
        initializeBytesAggchain,
        (
            bool,
            bytes32,
            bytes4,
            address,
            address,
            address,
            address,
            string,
            string
        )
    );
```

- **EXISTING** v0.2.0 AGGCHAIN: custom initialization bytes
```solidity
// Only need to initialize values that are specific for ECDSA because we are performing an upgrade from a Pessimistic chain
// aggchainBase params
(
    bool _useDefaultGateway,
    bytes32 _initOwnedAggchainVKey,
    bytes2 _initAggchainVKeySelector,
    address _vKeyManager
) = abi.decode(
    initializeBytesAggchain,
    (bool, bytes32, bytes4, address)
);
```

- bytes when calling `getAggchainHash` & `onVerifyPessimistic`:
```solidity
(
    bytes2 aggchainVKeySelector,
    bytes newstateRoot ) = abi.decode(
        aggchainData,
        (bytes4, bytes32)
);
```

#### 5.1.1 Roles

|       Role       |                Description                 |
|:----------------:|:------------------------------------------:|
|   vKeyManager    |           manages aggchain vkeys           |
|      admin       | upgrade rollupTypes & set trsutedSequencer |
| trustedSequencer |         signs PP state transition          |

##### vKeyManager
- **Functionality**: Manages aggchain verification keys, insertions and updates. It can also enable/disable the usage of the default aggchain vkeys (managed by the ALGateway contract)
- **Security Assumptions**: A malicious verification key can compromise the funds of a chain (not the entire agglayer)
- **Recommended Account Type**: Timelock (specified by the chain itself)

##### admin
- **Functionality**: Allow to set the `trustedSequencer` and can manage aggchain upgrades with certain limitations:
    - cannot update to old `rollupTypeID`
    - cannot update to a different `rollupVerifierType`
- **Security Assumptions**: `trustedSequencer` sign the chain pp-state-stransistion. It imply high security risk
- **Recommended Account Type**: Timelock

##### trustedSequencer
- **Functionality**: Signs chain pp-state-transistion
- **Security Assumptions**: Incorrect state-stransistion can lead to steal funds in the chain.
- **Recommended Account Type**: EOA or internal multisig

#### 5.1.2 Test-vectors
- [aggchain-data](https://github.com/0xPolygonHermez/zkevm-contracts/blob/feature/ongoing-v0.3.0/test/test-vectors/aggchainECDSA/aggchain-data.json)
- [aggchain-init-bytes-v0](https://github.com/0xPolygonHermez/zkevm-contracts/blob/feature/ongoing-v0.3.0/test/test-vectors/aggchainECDSA/aggchain-initBytesv0.json)
- [aggchain-init-bytes-v1](https://github.com/0xPolygonHermez/zkevm-contracts/blob/feature/ongoing-v0.3.0/test/test-vectors/aggchainECDSA/aggchain-initBytesv1.json)
- [hash-aggchain-params](https://github.com/0xPolygonHermez/zkevm-contracts/blob/feature/ongoing-v0.3.0/test/test-vectors/aggchainECDSA/hash-aggchain-params.json)

### 5.2. FEP
There are two scenarios to be considered in the `FEP`: new one and one that comes from `v0.2.0`.
The only difference is that all chains coming from `v0.2.0` that are going to move to a `FEP-v0.3.0` doe snot need to initialize all their parameters since some of them were initialized before.

- **NEW AGGCHAIN**: custom initialization bytes
```solidity
/// @notice Parameters to initialize the AggchainFEP contract.
struct InitParams {
    uint256 l2BlockTime;
    bytes32 rollupConfigHash;
    bytes32 startingOutputRoot;
    uint256 startingBlockNumber;
    uint256 startingTimestamp;
    uint256 submissionInterval;
    address optimisticModeManager;
    bytes32 aggregationVkey;
    bytes32 rangeVkeyCommitment;
}

// Decode the struct
(
    // chain custom params
    InitParams memory _initParams,
    // aggchainBase params
    bool _useDefaultGateway,
    bytes32 _initOwnedAggchainVKey,
    bytes4 _initAggchainVKeySelector,
    address _vKeyManager,
    // PolygonConsensusBase params
    address _admin,
    address _trustedSequencer,
    address _gasTokenAddress,
    string memory _trustedSequencerURL,
    string memory _networkName
) = abi.decode(
        initializeBytesAggchain,
        (
            InitParams,
            bool,
            bytes32,
            bytes4,
            address,
            address,
            address,
            address,
            string,
            string
        )
    );

// init FEP params
_initializeAggchain(_initParams);

// Set aggchainBase variables
_initializeAggchainBaseAndConsensusBase(
    _admin,
    _trustedSequencer,
    _gasTokenAddress,
    _trustedSequencerURL,
    _networkName,
    _useDefaultGateway,
    _initOwnedAggchainVKey,
    _initAggchainVKeyVersion,
    _vKeyManager
);
```

- **EXISTING** v0.2.0 AGGCHAIN: custom initialization bytes
```solidity
// contract has been previously initialized with all parameters in the PolygonConsensusBase.sol
// Only initialize the FEP and AggchainBase params
(
    // chain custom params
    InitParams memory _initParams,
    // aggchainBase params
    bool _useDefaultGateway,
    bytes32 _initOwnedAggchainVKey,
    bytes4 _initAggchainVKeySelector,
    address _vKeyManager
) = abi.decode(
        initializeBytesAggchain,
        (InitParams, bool, bytes32, bytes4, address)
    );
```

- custom bytes when calling `getAggchainHash` & `onVerifyPessimistic`:
```solidity
 // decode the aggchainData
(
    bytes4 _aggchainVKeySelector,
    bytes32 _outputRoot,
    uint256 _l2BlockNumber
) = abi.decode(aggchainData, (bytes4, bytes32, uint256));
```

#### 5.2.1 Roles

|         Role          |                              Description                                            |
|:---------------------:|:-----------------------------------------------------------------------------------:|
|      vKeyManager      |                        manages aggchain vkeys                                       |
|         admin         |              upgrade rollupTypes & set trustedSequencer                             |
|   trustedSequencer    |               if `optimisticMode`: signs state transition                           |
|    aggchainManager    | manages updates `submissionInterval` & `rollupConfigHash`. Initialize the aggchain. |
| optimisticModeManager |                       enable/disable `optimisticMode`                               |

##### vKeyManager
- **Functionality**: Manages aggchain verification keys, insertions and updates. It can also enable/disable the usage of the default aggchain vkeys (managed by the ALGateway contract)
- **Security Assumptions**: A malicious verification key can compromise the funds of a chain (not the entire agglayer)
- **Recommended Account Type**: Timelock (specified by the chain itself)

##### admin
- **Functionality**: Allow to set the `trustedSequencer` and can manage aggchain upgrades with certain limitations:
    - cannot update to old `rollupTypeID`
    - cannot update to a different `rollupVerifierType`
- **Security Assumptions**: `trustedSequencer` signs the state-stransistion when the FEP is on `optimisticMode` (note that `optimisticMoode` has a higher level of security)
- **Recommended Account Type**: Multisig

##### trustedSequencer
- **Functionality**: Signs chain state-transistion in case the chain is on `optimisticMode`
- **Security Assumptions**: Incorrect state-stransistion can lead to steal funds in the chain. Orotected by the security-council since it has no effect if the `optimisticMode` is not enabled
- **Recommended Account Type**: EOA or internal multisig

##### aggchainManager
- **Functionality**: Manages the update of the `submissionInterval` and the `rollupConfigHash` parameters
- **Security Assumptions**:
    - `submissionInterval` is the minimum interval at which checkpoints must be submitted. No high security assumptions.
    - `rollupConfigHash` contains sensistive data that could potentially affect the aggchain state transistion. High security assumptions.
- **Recommended Account Type**: Timelock (specified by the chain itself)

##### optimisticModeManager
- **Functionality**: Manages the enbale/disable of the `optimisticMode`
- **Security Assumptions**: When true, the chain can bypass the state transition verification
- **Recommended Account Type**: Multisig security council. Act fast while and not fully controlled by internal people

#### 5.2.2 Test-vectors
- [aggchain-data](https://github.com/0xPolygonHermez/zkevm-contracts/blob/feature/fix-small-inconsistencies/test/test-vectors/aggchainFEP/aggchain-data.json)
- [aggchain-init-bytes-v0](https://github.com/0xPolygonHermez/zkevm-contracts/blob/feature/fix-small-inconsistencies/test/test-vectors/aggchainFEP/aggchain-initBytesv0.json)
- [aggchain-init-bytes-v1](https://github.com/0xPolygonHermez/zkevm-contracts/blob/feature/fix-small-inconsistencies/test/test-vectors/aggchainFEP/aggchain-initBytesv1.json)
- [hash-aggchain-params](https://github.com/0xPolygonHermez/zkevm-contracts/blob/feature/fix-small-inconsistencies/test/test-vectors/aggchainFEP/hash-aggchain-params.json)

## 6. Rollup Manager Specification
### 6.1. Versioning
New string to indicate Rollup Manager version: `al-v0.3.1`:
```solidity
string public constant ROLLUP_MANAGER_VERSION = "al-v0.3.1";
```

### 6.2. AggLayerGateway contract
An address that identifies the `aggLayerGateway` contract. This will be set as an immutable:
```solidity
IAggLayerGateway public immutable aggLayerGateway;
```

### 6.3. New VerifierType
A new `VerifierType` has been added: `ALGateway`
```solidity
enum VerifierType {
    StateTransition, // zkEVM & Validium
    Pessimistic, // PP v0.2.0
    ALGateway // PP v0.3.0
}
```

`RollupTypes` created based on `VerifierType: ALGateway` will have the following properties:

- its verifier will be the `ALGateway` smart contract
    - the following rollup parameters will be 0:
        - `rollup.forkID = 0;`
        - `rollup.verifier = address(0);`
        - `rollup.batchNumToStateRoot[0] = bytes32(0);`
        - `rollup.programVKey = bytes32(0);`
- a consensus will be predetermined (ECDSA or FEP)

The chain can specify its own bytes to be initialized when the chain is created (not forced anymore by the interface):
```solidity
bytes memory initializeBytesAggchain
```

The chain can choose its own bytes when a proof is sent by tye aggLayer:
```solidity
bytes calldata aggchainData
```

### 6.4. Create new chain
Chains will be created differently as it was in previous versions. Since the `initializeBytesAggchain` has been introduced to generalize the chains initialization, the entry point has been also generalized.
Old chains will be still possible to create but it will be nececcesary to encode the ininitialization bytes in the `initializeBytesAggchain`.
This approach provides a generic interface for all existing chains and allows future chains with different initialization bytes to be added without modifying the interface:

```solidity
function attachAggchainToAL(
    uint32 rollupTypeID,
    uint64 chainID,
    bytes memory initializeBytesAggchain
) external;
```

### 6.5. Verify pessimitic proof
The entry point will be the same for every chain that uses pessimistic proof. That is the function `verifyPessimisticTrustedAggregator`.
Its interface has been modified to initialize a v0.3.0 aggchain by inserting a new field `aggchainData`.
```solidity
function verifyPessimisticTrustedAggregator(
    uint32 rollupID,
    uint32 l1InfoTreeLeafCount,
    bytes32 newLocalExitRoot,
    bytes32 newPessimisticRoot,
    bytes calldata proof,
    bytes memory aggchainData
) external;
```

> For more information about the verification flow, you can refer to this [link](Diagrams.md/#verify-fep).

### 6.6. Pretty rollupData
Etherscan did not parse structs correctly. A prettier view function has been added so the returning information is human-readable on etherscan.
The following functions are the same, it is just a change on how the data is return:

- v0.2.0:
```solidity
function rollupIDToRollupDataDeserialized(
        uint32 rollupID
)
    public
    view
    returns (
        address rollupContract,
        uint64 chainID,
        address verifier,
        uint64 forkID,
        bytes32 lastLocalExitRoot,
        uint64 lastBatchSequenced,
        uint64 lastVerifiedBatch,
        uint64 _legacyLastPendingState,
        uint64 _legacyLastPendingStateConsolidated,
        uint64 lastVerifiedBatchBeforeUpgrade,
        uint64 rollupTypeID,
        VerifierType rollupVerifierType
    );
```

- v0.3.0:
```solidity
function rollupIDToRollupDataV2Deserialized(
    uint32 rollupID
)
    public
    view
    returns (
        address rollupContract,
        uint64 chainID,
        address verifier,
        uint64 forkID,
        bytes32 lastLocalExitRoot,
        uint64 lastBatchSequenced,
        uint64 lastVerifiedBatch,
        uint64 lastVerifiedBatchBeforeUpgrade,
        uint64 rollupTypeID,
        VerifierType rollupVerifierType,
        bytes32 lastPessimisticRoot,
        bytes32 programVKey
    )
{
    RollupData storage rollup = _rollupIDToRollupData[rollupID];

    rollupContract = rollup.rollupContract;
    chainID = rollup.chainID;
    verifier = rollup.verifier;
    forkID = rollup.forkID;
    lastLocalExitRoot = rollup.lastLocalExitRoot;
    lastBatchSequenced = rollup.lastBatchSequenced;
    lastVerifiedBatch = rollup.lastVerifiedBatch;
    lastVerifiedBatchBeforeUpgrade = rollup.lastVerifiedBatchBeforeUpgrade;
    rollupTypeID = rollup.rollupTypeID;
    rollupVerifierType = rollup.rollupVerifierType;
    lastPessimisticRoot = rollup.lastPessimisticRoot;
    programVKey = rollup.programVKey;
}
```

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

### 7.2.2 LocalBalanceTree
The contract implements the same `LocalBalanceTree` logic as the pessimistic program. This tree is stored in a mapping and behaves as follows:

- Decreases when a `bridge` occurs.
- Increases when a `claim` is made.
- If the token is minted on the chain itself, it does not alter the balance (no increase/decrease).

This tree was added to prevent the following scenario:

1. A chain uses a custom mapping that allows minting more tokens than are actually available.
2. A user performs a successful `bridge` with more tokens than exist on the chain.
3. The user transaction succeeds, but the pessimistic program cannot generate a valid proof because the `LocalBalanceTree` becomes negative.
4. The chain gets blocked until a `claim` is performed to inject tokens into the `LocalBalanceTree`.

This situation is avoided by having the `LocalBalanceTree` in the smart contract. Any `bridge` that would cause a negative balance is automatically reverted.

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

## 8. Roles sovereignChains contracts
Contracts used in sovereign chains: `BridgeL2SovereignChain` & `GlobalExitRootManagerL2SovereignChain`

### 8.1. BridgeL2SovereignChain
|     Role      |                              Description                              |
|:-------------:|:---------------------------------------------------------------------:|
| bridgeManager | Handles set custom tokens mapping and has the ability to clear claims |

#### bridgeManager
- **Functionality**: Manages the custom tokens mapping. It also has the ability to clear claims
- **Security Assumptions**: High. Setting custom tokens or clear claims
- **Recommended Account Type**: Timelock (specified by the chain itself)

### 8.2. GlobalExitRootManagerL2SovereignChain
|         Role          |          Description           |
|:---------------------:|:------------------------------:|
| globalExitRootUpdater | Inject GER into the bridge SC  |
| globalExitRootRemover | Removes GER from the Bridge SC |

#### globalExitRootUpdater
- **Functionality**: Injects GER to the bridge SC
- **Security Assumptions**: Low security risk. All GERS are validated via the FEP program.
- **Recommended Account Type**: EOA (hot wallet in aggOracle)

#### globalExitRootRemover
- **Functionality**: Remove GER to the bridge SC
- **Security Assumptions**: High security risk. Controller could steal funds if collide with the `globalExitRootUpdater`
- **Recommended Account Type**: Multisg (act fast to unblock the chain)

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