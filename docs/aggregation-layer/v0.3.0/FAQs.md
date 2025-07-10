# FAQs

## 1. Docker

### Why use `sudo` in docker scripts?

The use of sudo with those files is required to ensure compatibility with `GHA` (GitHub Actions), as elevated permissions are often necessary in that environment. However, in some cases, it may be necessary to remove those commands from the script when running docker locally, depending on the user's system configuration and permissions.

### What about the legacy rollups (PP)?

You can still create rollups using the same process as before. Compatibility remains unchanged — we've only added support for the new ones.

To better understand compatibility, you can refer to this [table](https://didactic-giggle-9pqo9jg.pages.github.io/aggregation-layer/v0.3.0/SC-specs/#15-table-agglayer-chains-supported).
> Note that the deployment files have changed slightly, as mentioned in this [section](https://didactic-giggle-9pqo9jg.pages.github.io/aggregation-layer/v0.3.0/Docker/#5-diff-with-version-v020).

## 2. Smart Contracts
### Contracts errors, events and functions selectors

This [link](https://github.com/agglayer/agg-contracts-internal/blob/feature/ongoing-v0.3.0/docs/selectors.txt) contains the full list of contract errors (and their signatures), as well as the functions and events.

### Reverted with data '0x'
Potential cases:

- [function selector (first 4 bytes on the calldata)](https://github.com/agglayer/agg-contracts-internal/blob/feature/ongoing-v0.3.0/contracts/v2/PolygonRollupManager.sol#L1210-L1217)

- calldata parameters defined as `bytes` incorrectly parsed inside the SC:
    - [bytes proof](https://github.com/agglayer/agg-contracts-internal/blob/feature/ongoing-v0.3.0/contracts/v2/PolygonRollupManager.sol#L1215)
        - [must follow this enconding](https://github.com/agglayer/agg-contracts-internal/blob/feature/ongoing-v0.3.0/contracts/v2/AggLayerGateway.sol#L120-L122)
        - [sanity check on the length here](https://github.com/agglayer/agg-contracts-internal/blob/feature/ongoing-v0.3.0/contracts/v2/AggLayerGateway.sol#L129)
        - parsed in [here](https://github.com/agglayer/agg-contracts-internal/blob/feature/ongoing-v0.3.0/contracts/v2/AggLayerGateway.sol#L133) and [here](https://github.com/agglayer/agg-contracts-internal/blob/feature/ongoing-v0.3.0/contracts/v2/AggLayerGateway.sol#L145)
        - note that if the verifier is mock...everything will be fine. If the verififer is real, SP1 also does some parsing [here](https://github.com/agglayer/agg-contracts-internal/blob/feature/ongoing-v0.3.0/contracts/verifiers/v4.0.0-rc.3/SP1VerifierPlonk.sol#L47) and [here](https://github.com/agglayer/agg-contracts-internal/blob/feature/ongoing-v0.3.0/contracts/verifiers/v4.0.0-rc.3/SP1VerifierPlonk.sol#L57)
    - [aggchainData](https://github.com/agglayer/agg-contracts-internal/blob/feature/ongoing-v0.3.0/contracts/v2/PolygonRollupManager.sol#L1216)
        - parsed [here](https://github.com/agglayer/agg-contracts-internal/blob/feature/ongoing-v0.3.0/contracts/v2/aggchains/AggchainFEP.sol#L434-L443) and [here](https://github.com/agglayer/agg-contracts-internal/blob/feature/ongoing-v0.3.0/contracts/v2/aggchains/AggchainFEP.sol#L560-L568)
- calldata `cast` parsing:
```
cast decode-calldata "verifyPessimisticTrustedAggregator(uint32,uint32,bytes32,bytes32,bytes,bytes)" 0x6c76687700000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000059824c4849da053ff471f1ce2bc4f8fc2d257aa61fc7bee86c1f5ce0463f7d4a68756fe264848d34dd69293eac0fc7ad0c7d0eaf9398231b17b381b13b8af7035400000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000004000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000420000c52de932284856798760c67a6c602cdd0f47ae4af86321e44ed28637f634dbef0000000000000000000000000000000000000000000000000000000000000169000000000000000000000000000000000000000000000000000000000000 | \
awk '
  NR==1 { print "rollupID: " $0 }
  NR==2 { print "l1InfoTreeLeafCount:   " $0 }
  NR==3 { print "newLocalExitRoot:    " $0 }
  NR==4 { print "newPessimisticRoot:      " $0 }
  NR==5 { print "proof:         " $0 }
  NR==6 { print "aggchainData:  " $0 }
'
```

## 3. VKeys Aggchain (FEP)

| VKey                         | Alternative Names | Prover               | Primary Use                 | Used When...                                                                                         | Change with                                                                                                      |
| ---------------------------- | ----------------- | -------------------- | --------------------------- | ---------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `programVkey`                | `agglayerVkey`    | agglayer             | Only used for *pessimistic* | `addNewRollupType` -> [PolygonRollupManager](https://github.com/agglayer/agglayer-contracts/blob/feature/ongoing-v0.3.0/contracts/v2/PolygonRollupManager.sol#L497)                                                                                   | create new rollup type                                                                                           |
| `pessimisticVkey` / `ppVkey` | `agglayerVkey`    | agglayer             | Only used for *FEP, v0.3.0* | Whenever configuring the `aggLayerGateway` ([deploy_parameters.json](https://github.com/agglayer/agglayer-contracts/blob/feature/ongoing-v0.3.0/deployment/v2/deploy_parameters.json.example#L14))                                | `addPessimisticVKeyRoute` -> [AgglayerGateway](https://github.com/agglayer/agglayer-contracts/blob/feature/ongoing-v0.3.0/contracts/v2/AggLayerGateway.sol#L189)                                                                      |
| `aggchainVkey`               | `aggkitVkey`      | aggkit-prover        | Only used for *FEP, v0.3.0* | During FEP setup: [aggchainParams](https://github.com/agglayer/agglayer-contracts/blob/feature/ongoing-v0.3.0/tools/initializeRollup/initialize_rollup.json.example#L32) `initOwnedAggchainVKey` &  `addDefaultAggchainVKey` --> [AgglayerGateway](https://github.com/agglayer/agglayer-contracts/blob/feature/ongoing-v0.3.0/contracts/v2/AggLayerGateway.sol#L236) | `addDefaultAggchainVKey/updateDefaultAggchainVKey` -> [AgglayerGateway](https://github.com/agglayer/agglayer-contracts/blob/feature/ongoing-v0.3.0/contracts/v2/AggLayerGateway.sol#L261),  `addOwnedAggchainVKey` -> [rollupContract](https://github.com/agglayer/agglayer-contracts/blob/feature/ongoing-v0.3.0/contracts/v2/lib/AggchainBase.sol#L316) |
| `aggregationVkey`            | —                 | op-succinct-proposer | Only used for *FEP, v0.3.0* | [initParams](https://github.com/agglayer/agglayer-contracts/blob/feature/ongoing-v0.3.0/tools/initializeRollup/initialize_rollup.json.example#L28):   aggregationVkey                                                                        | —                                                                                                                |

During environment setup, four distinct verification keys (vkeys) are defined, each serving a specific purpose in the proof verification and deployment workflows. Below is a detailed description of each key and its corresponding usage:

### programVkey

  This [key](https://github.com/agglayer/agglayer-contracts/blob/feature/ongoing-v0.3.0/tools/addRollupType/add_rollup_type.json.example#L16) is used to verify proofs (`agglayer-prover`) when operating under pessimistic consensus.
  In any scenario outside of pessimistic consensus, the value of programVkey must be set to zero (0).

### pessimisticVkey (`agglayerVkey` or `ppvkey`)

  Similar to programVkey, this key is used to verify proofs (`agglayer-prover`).

  This is the vkey to be specified in the [deploy_parameters.json](https://github.com/agglayer/agglayer-contracts/blob/feature/ongoing-v0.3.0/deployment/v2/deploy_parameters.json.example#L14) file when launching a new environment.

  To add a new ppvkey after deployment, it must be registered in the AgglayerGateway contract using the addPessimisticVKeyRoute [function](https://github.com/agglayer/agglayer-contracts/blob/feature/ongoing-v0.3.0/contracts/v2/AggLayerGateway.sol#L189).

  A dedicated [tool](https://github.com/agglayer/agglayer-contracts/tree/feature/ongoing-v0.3.0/tools/aggLayerGatewayTools/addPessimisticVKeyRoute) is available to facilitate this operation.

  Cast commands:
  
  - `addPessimisticVKeyRoute`
  ```
  cast send \
    --rpc-url $SEPOLIA_PROVIDER \
    --private-key $ZKEVM_ADMIN_KEY \
    $AGGLAYER_GW_ADDR \
    'addPessimisticVKeyRoute(bytes4,address,bytes32)' \
    $AGGLAYER_VKEYSELECTOR $PPVKEY_VERIFIER $AGGLAYER_VKEY
  ```
  - check `pessimisticVKeyRoute`
  ```
  cast call \
    --rpc-url $SEPOLIA_PROVIDER \
    $AGGLAYER_GW_ADDR \
    'pessimisticVKeyRoutes(bytes4)' \
    $AGGLAYER_VKEYSELECTOR
  ```

### aggchainVkey

  This key is used by the `aggkit-prover`.

  During the initialize step of the FEP, it must be included in [aggchainParams](https://github.com/agglayer/agglayer-contracts/blob/feature/ongoing-v0.3.0/tools/initializeRollup/initialize_rollup.json.example#L32) under the `initOwnedAggchainVKey` field.

  It must be added to the AgglayerGateway using the a `addDefaultAggchainVKey` [tool](https://github.com/agglayer/agglayer-contracts/tree/feature/ongoing-v0.3.0/tools/aggLayerGatewayTools/addDefaultAggchainVKey).

  To update this vkey after deployment, use either `addDefaultAggchainVKey` ([tool](https://github.com/agglayer/agglayer-contracts/tree/feature/ongoing-v0.3.0/tools/aggLayerGatewayTools/addDefaultAggchainVKey)) or `updateDefaultAggchainVKey` ([tool](https://github.com/agglayer/agglayer-contracts/tree/feature/ongoing-v0.3.0/tools/aggLayerGatewayTools/updateDefaultAggchainVKey)).

  Additionally, the `ownedAggchainVkey` field must be updated on the `rollupContract` with this `addOwnedAggchainVKey` [function](https://github.com/agglayer/agglayer-contracts/blob/feature/ongoing-v0.3.0/contracts/v2/lib/AggchainBase.sol#L316) or `updateOwnedAggchainVKey` [function](https://github.com/agglayer/agglayer-contracts/blob/feature/ongoing-v0.3.0/contracts/v2/lib/AggchainBase.sol#L338C14-L338C37).

  Cast commands:

  - `addOwnedAggchainVKey`
  ```
  cast send \
    --rpc-url $SEPOLIA_PROVIDER \
    --private-key $ZKEVM_ADMIN_KEY \
    $ROLLUP_ADDR \
    'addOwnedAggchainVKey(bytes4,bytes32)' \
    $AGGKIT_VKEYSELECTOR $AGGKIT_VKEY
  ```
  - `updateOwnedAggchainVKey` (same `AGGKIT_VKEYSELECTOR`)
  ```
  cast send \
    --rpc-url $SEPOLIA_PROVIDER \
    --private-key $ZKEVM_ADMIN_KEY \
    $ROLLUP_ADDR \
    'updateOwnedAggchainVKey(bytes4,bytes32)' \
    $AGGKIT_VKEYSELECTOR $AGGKIT_VKEY
  ```
  - check `ownedAggchainVKey`
  ```
  cast call \
    --rpc-url $SEPOLIA_PROVIDER \
    $ROLLUP_ADDR \
    'ownedAggchainVKeys(bytes4)' \
    $AGGKIT_VKEYSELECTOR
  ```
  - `addDefaultAggchainVKey`
  ```
  cast send \
    --rpc-url $SEPOLIA_PROVIDER \
    --private-key $ZKEVM_ADMIN_KEY \
    $AGGLAYER_GW_ADDR \
    'addDefaultAggchainVKey(bytes4,bytes32)' \
    $AGGKIT_VKEYSELECTOR $AGGKIT_VKEY
  ```
  - `updateDefaultAggchainVKey` (same `AGGKIT_VKEYSELECTOR`)
  ```
  cast send \
    --rpc-url $SEPOLIA_PROVIDER \
    --private-key $ZKEVM_ADMIN_KEY \
    $AGGLAYER_GW_ADDR \
    'updateDefaultAggchainVKey(bytes4,bytes32)' \
    $AGGKIT_VKEYSELECTOR $AGGKIT_VKEY
  ```
  - check `defaultAggchainVKey`
  ```
  cast call \
    --rpc-url $SEPOLIA_PROVIDER \
    $AGGLAYER_GW_ADDR \
    'defaultAggchainVKeys(bytes4)' \
    $AGGKIT_VKEYSELECTOR
  ```

### aggregationVkey

  This [vkey](https://github.com/agglayer/agglayer-contracts/blob/feature/ongoing-v0.3.0/tools/initializeRollup/initialize_rollup.json.example#L28) is provided by the `op-succinct-proposer` component.

## 4. Debug Invalid Proof

When encountering the `InvalidProof error`, it's important to understand that this means the proof being submitted is not valid—as the error name itself suggests.

When we call the `verifyPessimisticTrustedAggregator` function, we do so with the following parameters:
```
uint32 rollupID,
uint32 l1InfoTreeLeafCount,
bytes32 newLocalExitRoot,
bytes32 newPessimisticRoot,
bytes calldata proof,
bytes calldata aggchainData
```

Internally, this function invokes `verifyProof`, which is called with three key parameters:
- `programVKey`
- `publicValues`
- `proofBytes`

These are the required inputs for eventually calling the underlying `verify` function.

### proofBytes

This parameter is typically correct. If you run into a `WrongVerifierSelector` error instead, it usually means that the verification is being routed to the wrong verifier.

### programVKey

You should ensure that this verification key (vkey) is correct.

- For rollups using a verifier of type `pessimistic`, the key is named `programVKey`.
- For rollups using an `ALGateway` verifier, the key is called `pessimisticVKey`.

It is crucial to confirm that the vkey you’re using matches the one expected by the system. You can validate this by using the appropriate command for each verifier type:

- Command for rollup with `pessimistic` verifier

```
cast call <polygonRollupManager> "rollupIDToRollupDataV2Deserialized(uint32)(address,uint64,address,uint64,bytes32,uint64,uint64,uint64,uint64,uint8,bytes32,bytes32)" <rollupID> --rpc-url <sepolia_url>
```

> fill <polygonRollupManager>, <rollupID>, <sepolia_url>

The `programVKey` is the last parameter of the output.
    
- Output: 
    - 0xF21452f6b9606B4026fd1C057FDbd8bB7E33c487
    - 472
    - 0x0459d576A6223fEeA177Fb3DF53C9c77BF84C459
    - 12
    - 0x6a327b365efeb205f2dedc9ec6dd505d3c5c5dbb6d84a33233d4a9d6fb74295c
    - 0
    - 0
    - 0
    - 30
    - 1
    - 0x04970a4ae71b81bfca444f84318475a48475e6d1a1c6126e31c046d952eec6f2
    - ==**0x00eff0b6998df46ec388bb305618089ae3dc74e513e7676b2e1909694f49cc30**==
    
- Command for rollup with `ALGateway` verifier

```
cast call <agglayerGatewayAddress> "pessimisticVKeyRoutes(bytes4)(address,bytes32,bool)" <ppSelector> --rpc-url <sepolia_url>
```

> fill <agglayerGatewayAddress>, <ppSelector>, <sepolia_url>

The `pessimisticVkey` is the second parameter of the output.
- Output:
    - 0x0459d576A6223fEeA177Fb3DF53C9c77BF84C459
    - ==**0x00eff0b6998df46ec388bb305618089ae3dc74e513e7676b2e1909694f49cc30**==
    - false

### publicInputs

```
publicInputs = _getInputPessimisticBytes(
    rollupID,
    rollup,
    l1InfoRoot,
    newLocalExitRoot,
    newPessimisticRoot,
    aggchainData
);
```

where:

```
inputPessimisticBytes = abi.encodePacked(
    rollup.lastLocalExitRoot,
    rollup.lastPessimisticRoot,
    l1InfoTreeRoot,
    rollupID,
    consensusHash,
    newLocalExitRoot,
    newPessimisticRoot
);
```

These are the parameters used to construct the public inputs. Therefore, we should carefully review each one individually to ensure they are correct:
    
#### lastLocalExitRoot & lastPessimisticRoot
    
```
cast call <polygonRollupManager> "rollupIDToRollupDataV2Deserialized(uint32)(address,uint64,address,uint64,bytes32,uint64,uint64,uint64,uint64,uint8,bytes32,bytes32)" <rollupID> --rpc-url <sepolia_url>
```
    
- Output: 
    - 0xF21452f6b9606B4026fd1C057FDbd8bB7E33c487
    - 472
    - 0x0459d576A6223fEeA177Fb3DF53C9c77BF84C459
    - 12
    - ==**0x6a327b365efeb205f2dedc9ec6dd505d3c5c5dbb6d84a33233d4a9d6fb74295c**== (`lastLocalExitRoot`)
    - 0
    - 0
    - 0
    - 30
    - 1
    - ==**0x04970a4ae71b81bfca444f84318475a48475e6d1a1c6126e31c046d952eec6f2**== (`lastPessimisticRoot`)
    - 0x00eff0b6998df46ec388bb305618089ae3dc74e513e7676b2e1909694f49cc30

#### l1InfoTreeRoot
```
cast call <globalExitRootManager> "l1InfoRootMap(uint32)" <l1InfoTreeLeafCount> --rpc-url <sepolia_url>
```
> fill globalExitRootManager, l1InfoTreeLeafCount, sepolia_url
    
#### rollupID
```
cast call <rollupManagerAddress> "rollupAddressToID(address)" <rollupAddress> --rpc-url <sepolia_url>
```
> rollupManagerAddress, rollupAddress, sepolia_url
    
#### consensusHash

- For pessimistic verifier:
```
cast call <rollupContractAddress> "getConsensusHash()" --rpc-url <sepolia_url>
```
> fill <rollupContractAddress, <sepolia_url>
    
- For ALGateway verifier, aggchainFEP --> `getAggchainHash(aggchainData)`:
    
```
cast call <rollupContractAddress> "getAggchainHash(bytes)" <aggchainData> --rpc-url <sepolia_url>
```
    
ConsensusHash is:
```
keccak256(
    abi.encodePacked(
        CONSENSUS_TYPE,
        getAggchainVKey(_aggchainVKeySelector),
        aggchainParams
    )
);
```

Where:
    
- `CONSENSUS_TYPE`:
```
cast call <rollupContractAddress> "CONSENSUS_TYPE()" --rpc-url <sepolia_url>
```
> fill rollupContractAddress, sepolia_url
    
- `getAggchainVKey(_aggchainVKeySelector)`:
    - `aggchainVKeySelector` from `aggchainData`:
```
@param aggchainData custom bytes provided by the chain
    aggchainData:
     Field:           | _aggchainVKeySelector | _outputRoot  | _l2BlockNumber |
     length (bits):   | 32                   | 256          | 256            |
```

Then `aggchainVKeySelector`:
```
cast call <rollupContractAddress> "getAggchainVKey(bytes4)" <aggchainVKeySelector> --rpc-url <sepolia_url>
```
> fill rollupContractAddress, aggchainVKeySelector, sepolia_url
    
- aggchainParams:
```
bytes32 aggchainParams = keccak256(
    abi.encodePacked(
        l2Outputs[latestOutputIndex()].outputRoot,
        _outputRoot,
        _l2BlockNumber,
        rollupConfigHash,
        optimisticMode,
        trustedSequencer,
        rangeVkeyCommitment,
        aggregationVkey
    )
);
```
   
- l2Outputs[latestOutputIndex()].outputRoot --> internal
    
- `outputRoot`, `l2BlockNumber` from `aggchainData`:
    
```
@param aggchainData custom bytes provided by the chain
    aggchainData:
     Field:           | _aggchainVKeySelector | _outputRoot  | _l2BlockNumber |
     length (bits):   | 32                    | 256          | 256            |
```

- rollupConfigHash:
```
cast call <rollupContractAddress> "rollupConfigHash()" --rpc-url <sepolia_url>
```

- optimisticMode:
```
cast call <rollupContractAddress> "optimisticMode()" --rpc-url <sepolia_url> 
```

- trustedSequencer:
```
cast call <rollupContractAddress> "trustedSequencer()" --rpc-url <sepolia_url> 
```

- rangeVkeyCommitment:
```
cast call <rollupContractAddress> "rangeVkeyCommitment()" --rpc-url <sepolia_url>    
```

- aggregationVkey:
```
cast call <rollupContractAddress> "aggregationVkey()" --rpc-url <sepolia_url>    
```
   
> fill rollupContractAddress, sepolia_url
#### newLocalExitRoot & newPessimisticRoot
- `newLocalExitRoot`: New local exit root
- `newPessimisticRoot`: New pessimistic information, Hash(localBalanceTreeRoot, nullifierTreeRoot)

### Quick command
#### Pessimistic    
```
// TODO: Update params
POLYGON_ROLLUP_MANAGER="0x.."
ROLLUP_ADDRESS="0x.."
GLOBAL_EXIT_ROOT_MANAGER="0x.."
SEPOLIA_URL="https://sepolia..."
ROLLUP_ID=35
L1_INFO_TREE_LEAF_COUNT=1

output=$(cast call $POLYGON_ROLLUP_MANAGER "rollupIDToRollupDataV2Deserialized(uint32)(address,uint64,address,uint64,bytes32,uint64,uint64,uint64,uint64,uint8,bytes32,bytes32)" $ROLLUP_ID --rpc-url $SEPOLIA_URL)
programVKey=$(echo "$output" | grep -Eo '0x[a-fA-F0-9]{40,}' | tail -n 1)
lastLocalExitRoot=$(echo "$output" | sed -n '5p')
lastPessimisticRoot=$(echo "$output" | tail -n 2 | head -n 1)
l1InfoTreeRoot=$(cast call $GLOBAL_EXIT_ROOT_MANAGER "l1InfoRootMap(uint32)" $L1_INFO_TREE_LEAF_COUNT --rpc-url $SEPOLIA_URL)
rollupID=$(cast call $POLYGON_ROLLUP_MANAGER "rollupAddressToID(address)" $ROLLUP_ADDRESS --rpc-url $SEPOLIA_URL)
consensusHash=$(cast call $ROLLUP_ADDRESS "getConsensusHash()" --rpc-url $SEPOLIA_URL)

echo "programVKey: $programVKey"
echo "lastLocalExitRoot: $lastLocalExitRoot"
echo "lastPessimisticRoot: $lastPessimisticRoot"
echo "l1InfoTreeRoot: $l1InfoTreeRoot"
echo "rollupID (address to ID): $rollupID"
echo "consensusHash: $consensusHash"

```
#### AgglayerGateway
```
// TODO: Update params
POLYGON_ROLLUP_MANAGER="0x..."
ROLLUP_ADDRESS="0x..."
AGGLAYERGATEWAY="0x..."
GLOBAL_EXIT_ROOT_MANAGER="0x..."
SEPOLIA_URL="https://sepolia..."

ROLLUP_ID=34
PP_SELECTOR="0x00000004"
L1_INFO_TREE_LEAF_COUNT=1
AGGCHAIN_DATA="0x..."

output=$(cast call $AGGLAYERGATEWAY "pessimisticVKeyRoutes(bytes4)(address,bytes32,bool)" $PP_SELECTOR --rpc-url $SEPOLIA_URL)
programVKey=$(echo "$output" | sed -n '2p')
output=$(cast call $POLYGON_ROLLUP_MANAGER "rollupIDToRollupDataV2Deserialized(uint32)(address,uint64,address,uint64,bytes32,uint64,uint64,uint64,uint64,uint8,bytes32,bytes32)" $ROLLUP_ID --rpc-url $SEPOLIA_URL)
lastLocalExitRoot=$(echo "$output" | sed -n '5p')
lastPessimisticRoot=$(echo "$output" | tail -n 2 | head -n 1)
l1InfoTreeRoot=$(cast call $GLOBAL_EXIT_ROOT_MANAGER "l1InfoRootMap(uint32)" $L1_INFO_TREE_LEAF_COUNT --rpc-url $SEPOLIA_URL)
rollupID=$(cast call $POLYGON_ROLLUP_MANAGER "rollupAddressToID(address)" $ROLLUP_ADDRESS --rpc-url $SEPOLIA_URL)
consensusHash=$(cast call $ROLLUP_ADDRESS "getAggchainHash(bytes)" $AGGCHAIN_DATA --rpc-url $SEPOLIA_URL)
rollupConfigHash=$(cast call $ROLLUP_ADDRESS "rollupConfigHash()" --rpc-url $SEPOLIA_URL)
optimisticMode=$(cast call $ROLLUP_ADDRESS "optimisticMode()" --rpc-url $SEPOLIA_URL)
trustedSequencer=$(cast call $ROLLUP_ADDRESS "trustedSequencer()" --rpc-url $SEPOLIA_URL)
rangeVkeyCommitment=$(cast call $ROLLUP_ADDRESS "rangeVkeyCommitment()" --rpc-url $SEPOLIA_URL)
aggregationVkey=$(cast call $ROLLUP_ADDRESS "aggregationVkey()" --rpc-url $SEPOLIA_URL)

echo "programVKey: $programVKey"
echo "lastLocalExitRoot: $lastLocalExitRoot"
echo "lastPessimisticRoot: $lastPessimisticRoot"
echo "l1InfoTreeRoot: $l1InfoTreeRoot"
echo "rollupID (address to ID): $rollupID"
echo "consensusHash: $consensusHash"
echo "rollupConfigHash: $rollupConfigHash"
echo "optimisticMode: $optimisticMode"
echo "trustedSequencer: $trustedSequencer"
echo "rangeVkeyCommitment: $rangeVkeyCommitment"
echo "aggregationVkey: $aggregationVkey"
```
