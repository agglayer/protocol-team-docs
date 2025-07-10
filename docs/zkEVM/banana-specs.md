# Specification
## Motivation
- Stability current forkid.9
- Minimal resilient features
- Allow sequence and proving in the same transaction

## Resources
- [SC implementation](https://github.com/0xPolygonHermez/zkevm-contracts/releases/tag/v7.0.0-rc.1-fork.10)
- [ROM fix error cold address](https://github.com/0xPolygonHermez/qa-protocol-kanban/issues/412)
- [Full-tracer fix error logs](https://github.com/0xPolygonHermez/zkevm-prover/commit/23cf552758bd76fca0de8419cdfdabbe3c3d384f)
- [Banana implication for CDKs](https://hackmd.io/Sap9CUaISOWboittWft4aA?view)
- [Proposal design rollback sequences](https://hackmd.io/PDY-iuodSSupZ_L7hlfzQw?view)
- [List bugs executor past and current](https://hackmd.io/cjhsK4lFT0iP47750325WA)
- [Slides](https://docs.google.com/presentation/d/1FdwaRpfEFW8lgWeU1GYh1tXzUrt_QQOrhR0WqhdcJ3g/edit#slide=id.g2f09c811271_0_176)

## List changes
- [Rollback sequences](#rollback)
- [Deterministic `l1InfoTreeRoot`](#det-l1)
- [Verify `accumulate Input Hash`](#ver-acc)
- [Fix cold address access](#fix-cold)
- [Fix issues `geth blockhash` padding 32 bytes](#fix-padding-log)
- [Suggestions resilience](#sugg-resilience)
- [New events](#new-events)

### Rollback sequences<a id="rollback"></a>
#### Description
- Sequencer commits DA to L1 via the `sequenceBatches` SC call. When data is commited, the aggregator needs to verify that data
- This implies that posting some wrong data to L1 may imply a re-org on L2 or the stop of the network verification (pausing withdrawals and emergency upgrade)
- This feature adds the possibility to delete commit data posted to L1, so the recovery is straightforward causing less outage of the network

#### Implementation
- https://github.com/0xPolygonHermez/zkevm-contracts/blob/v7.0.0-rc.1-fork.10/contracts/v2/PolygonRollupManager.sol#L737

#### Implications
- Synchronizer should detect the new event emitted and apply it to the virtual state
- A verifed state cannot be rolled back

#### Resources
- [Proposal design rollback sequences](https://hackmd.io/PDY-iuodSSupZ_L7hlfzQw?view)

### Deterministic `l1InfoTreeRoot`<a id="det-l1"></a>
#### Description
- Current protocol selects the `l1InfoRoot` when the `sequenceBatches` call is done. This approach is optimal in terms of GAS saving but it implies that the `accInputHash` is non-deterministic
- This has been an issue when the sequencer does not correctly select the proper `indexL1InfoTree` or the synchronization could be wrong
- This feature implies that it will be a mapping containing all the `l1InfoRoot` in the SC
- The sequencer will be able to select one of them when sequence a batch

#### Implementation
- https://github.com/0xPolygonHermez/zkevm-contracts/blob/v7.0.0-rc.1-fork.10/contracts/v2/lib/PolygonRollupBaseEtrog.sol#L415
- https://github.com/0xPolygonHermez/zkevm-contracts/blob/v7.0.0-rc.1-fork.10/contracts/v2/lib/PolygonRollupBaseEtrog.sol#L440
- https://github.com/0xPolygonHermez/zkevm-contracts/blob/v7.0.0-rc.1-fork.10/contracts/v2/lib/PolygonRollupBaseEtrog.sol#L444

#### Implications
- `sequence-sender` to choose the `indexL1InfoRoot` to verify all the imported `GERs` in the `changeL2Block` transactions
- `indexL1InfoRoot` must exist on the SC. Otherwise, the SC reverts
> tip: choose the last `indexL1InfoRoot` that has been added in a finalized etheruem block
> tip: `sequence-sender` to perform a sanity-check when choosing the `indexL1InfoRoot`.
> Get all the `indexL1InfoTree` in the full sequence, with its corresponding data and check that indeed matches against the selected `l1InfoTreeRoot` selected

### Verify `accumulate Input Hash`<a id="ver-acc"></a>
#### Description
- Assuming `l1InfoTreeRoot` is deterministic, the sequencer can now pre-compute the `accInputHash` in advance
- The `accInputHash` is a summary of all the data processed in L2. Therefore, it acts as a sanity check when sequencing batches in L1

#### Implementation
- https://github.com/0xPolygonHermez/zkevm-contracts/blob/v7.0.0-rc.1-fork.10/contracts/v2/lib/PolygonRollupBaseEtrog.sol#L417
- https://github.com/0xPolygonHermez/zkevm-contracts/blob/v7.0.0-rc.1-fork.10/contracts/v2/lib/PolygonRollupBaseEtrog.sol#L563
- [JS accInputHash](https://github.com/0xPolygonHermez/zkevm-commonjs/blob/main/src/contract-utils.js#L15)
- [Go implementation accInputHash](https://github.com/0xPolygonHermez/zkevm-aggregator/blob/develop/aggregator/aggregator.go#L1529)

#### Implications
- `sequence-sender` needs to compute the `accInputHash` and send it to L1
> tip: if transaction reverts for this reason, it means that the data processed by the trsuted-sequencer and the one sent by the sequence-sender is different. Some sort of alarm/notification should be trigerred

### Fix cold address access<a id="fix-cold"></a>
#### Description
- Even if `create`/`create2` operation fails, the computed address will remain in the warm addresses set
- Full isues with details: https://github.com/0xPolygonHermez/zkevm-rom/issues/389

#### Implementation
- https://github.com/0xPolygonHermez/zkevm-rom/pull/390

#### Implications
- execution to mimic zkEVM ROM

### Fix issues `geth blockhash` padding 32 bytes<a id="fix-padding-log"></a>
#### Description
- Logs not padded to 32 bytes are not correctky returned by the full-tracer to the sequencer
- Sequencer computes and stores logs based on full-tracer response
- There is a current mismatch of the logs stored on L2 and the logs stored on the node

#### Implementation
- https://github.com/0xPolygonHermez/zkevm-prover/commit/23cf552758bd76fca0de8419cdfdabbe3c3d384f

#### Implications
- execution to mimic zkEVM ROM

### Suggestions resilience<a id="sugg-resilience"></a>
- sanity check `expectedNewStateRoot`
    - before verifying the batch to L1
        - trusted sequencer to provide its computed `state-root`
        - execute aggregator and aggregator to detect possible state-root differences
        - if this happens --> alarm/notification
            - most probably a re-org or rollback sequences may be needed
- detect change `l2Coinbase` at `sequence-sender` level
    - there is only one `l2Coinbase` per each sequence (multiple batches)
    - a new sequence needs to be creared if the `l2Coinbase` is chnaged

### New events<a id="new-events"></a>
#### Description
- Add `l1InfoTree` leaf information into an  new event

#### Implementation
- https://github.com/0xPolygonHermez/zkevm-contracts/blob/feature/update-l1-info-tree-v2/contracts/v2/PolygonZkEVMGlobalExitRootV2.sol#L39

#### Implications
- Adds costs for every deposit
- Enable to synchronize `l1InfoRoot` from events
- Does not break compatibility for `bridge-service`