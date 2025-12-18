# 4.1.1 Summary

## Disclosure
Final tag: [v12.2.1](https://github.com/agglayer/agglayer-contracts/releases/tag/v12.2.1)

## Ongoing development
https://github.com/agglayer/agglayer-contracts/tree/feature/v12

## Version Updates Summary

This release includes significant updates to bridge contracts, introducing emergency management capabilities and token remapping features:

- **AgglayerBridge**: `v1.0.0` → `v1.1.0` (Bytecode optimization)
- **AgglayerBridgeL2**: `v1.1.0` → `v1.2.0` (Token remapping + Detailed claim events)
- **AgglayerManager**: `al-v0.3.1` → `v1.0.0` (Renamed from PolygonRollupManager)
- **AgglayerGateway**: `v1.1.0` (Multisig support)
- **AggchainBase**: `v1.0.0` (New aggchain implementations)
- **AggchainECDSAMultisig**: `v1.0.0` (New - ECDSA multisig support)
- **AggchainFEP**: `v3.0.0` (New - OP Succinct verification)

## Key Features
* **Multisig Support**: Enhanced multisig management in AgglayerGateway and aggchain contracts
* **Multiple Initialization Paths**: Support for fresh deployments and migrations from existing contracts
* **Configuration Management**: FEP supports multiple OP Succinct configurations
* **Flexible Verification**: Choice between SP1 proofs (FEP) and ECDSA signatures (Multisig)
* **Renaming and Reorg**: more info [link](./Rename%20&%20reorg/index.md)

## Changelog

### 🚨 Breaking Changes
- New tooling package (v12.2.1)
- Rename & Reorg: contracts/v2/PolygonRollupManager.sol -> contracts/AgglayerManager.sol: v1.0.0
- Rename & Reorg: contracts/v2/PolygonZkEVMBridgeV2.sol -> contracts/AgglayerBridge.sol: v1.1.0
- Rename & Reorg: contracts/v2/PolygonZkEVMGlobalExitRootV2.sol -> contracts/AgglayerGER.sol: v1.0.0
- Reorg: contracts/v2/AggLayerGateway.sol -> contracts/AggLayerGateway.sol: v1.1.0
- Rename & Reorg, and updates: contracts/v2/sovereignChains/BridgeL2SovereignChain.sol -> contracts/sovereignChains/AgglayerBridgeL2.sol: v1.2.0
- Rename & Reorg: contracts/v2/sovereignChains/GlobalExitRootManagerL2SovereignChain.sol -> contracts/sovereignChains/AgglayerGERL2.sol: v1.0.0
- Reorg: contracts/v2/sovereignChains/AggOracleCommittee.sol -> contracts/sovereignChains/AggOracleCommittee.sol: v1.0.0

### ✨ New Features
- ➕ New! contracts/aggchains/AggchainECDSAMultisig.sol: v1.0.0
- ➕ New! contracts/aggchains/AggchainFEP.sol: v3.0.0 // Op L2OO Semantic version
- ➕ New! contracts/sovereignChains/AggOracleCommittee.sol: v1.0.0

### PRs 
- [PR #533](https://github.com/agglayer/agglayer-contracts/pull/533) - upgrade script etrog -> sovereign
- [PR #579](https://github.com/agglayer/agglayer-contracts/pull/579) - Feature/improve tool manage roles
- [PR #569](https://github.com/agglayer/agglayer-contracts/pull/569) - script push docker all release
- [PR #568](https://github.com/agglayer/agglayer-contracts/pull/568) - Feature/emit detailed events
- [PR #573](https://github.com/agglayer/agglayer-contracts/pull/573) - test(foundry): fix Foundry test base
- [PR #548](https://github.com/agglayer/agglayer-contracts/pull/548) - feat: obsolete rollup type script
- [PR #572](https://github.com/agglayer/agglayer-contracts/pull/572) - Remove old unused tests
- [PR #566](https://github.com/agglayer/agglayer-contracts/pull/566) - support previous genesis-base versions
- [PR #545](https://github.com/agglayer/agglayer-contracts/pull/545) - compare genesis tool
- [PR #564](https://github.com/agglayer/agglayer-contracts/pull/564) - Cleanup upgrade to v2
- [PR #562](https://github.com/agglayer/agglayer-contracts/pull/562) - Cleanup old testnets
- [PR #561](https://github.com/agglayer/agglayer-contracts/pull/561) - Remove boilerplate code in tests using common consts
- [PR #547](https://github.com/agglayer/agglayer-contracts/pull/547) - feat: add Foundry support and add minimum testing framework
- [PR #550](https://github.com/agglayer/agglayer-contracts/pull/550) - add tests tools
- [PR #485](https://github.com/agglayer/agglayer-contracts/pull/485) - add test claim reentrancy
- [PR #559](https://github.com/agglayer/agglayer-contracts/pull/559) - deployOutpost: delete not used example params
- [PR #558](https://github.com/agglayer/agglayer-contracts/pull/558) - fix: deploy aggoracle committee
- [PR #557](https://github.com/agglayer/agglayer-contracts/pull/557) - minor fixes
- [PR #554](https://github.com/agglayer/agglayer-contracts/pull/554) - add script upgrade gerL2 etrog to sovereign
- [PR #555](https://github.com/agglayer/agglayer-contracts/pull/555) - add spearbits audit
- [PR #508](https://github.com/agglayer/agglayer-contracts/pull/508) - Feature/ongoing v0.3.0
- [PR #551](https://github.com/agglayer/agglayer-contracts/pull/551) - Update CHANGELOG.md v12.1.2
- [PR #549](https://github.com/agglayer/agglayer-contracts/pull/549) - add final report v0.3.5
- [PR #468](https://github.com/agglayer/agglayer-contracts/pull/468) - minor changes on LICENSE
- [PR #546](https://github.com/agglayer/agglayer-contracts/pull/546) - fix sovereign genesis tool
- [PR #543](https://github.com/agglayer/agglayer-contracts/pull/543) - Feature/fix upgrade v12
- [PR #544](https://github.com/agglayer/agglayer-contracts/pull/544) - Feature/full upgrade v12
- [PR #527](https://github.com/agglayer/agglayer-contracts/pull/527) - Feature/udpate tools
- [PR #542](https://github.com/agglayer/agglayer-contracts/pull/542) - renaming timelock
- [PR #537](https://github.com/agglayer/agglayer-contracts/pull/537) - Feature/audit remediations
- [PR #538](https://github.com/agglayer/agglayer-contracts/pull/538) - several remediations
- [PR #534](https://github.com/agglayer/agglayer-contracts/pull/534) - Feature/fix migration
- [PR #536](https://github.com/agglayer/agglayer-contracts/pull/536) - fix genesis bridgeLib + inconsistencies
- [PR #526](https://github.com/agglayer/agglayer-contracts/pull/526) - reorg v2 -> contracts
- [PR #525](https://github.com/agglayer/agglayer-contracts/pull/525) - Feature/renaming agglayer
- [PR #532](https://github.com/agglayer/agglayer-contracts/pull/532) - allow aggchainECDSAMultig with isVanillaClient = false. Add batchData…
- [PR #529](https://github.com/agglayer/agglayer-contracts/pull/529) - all global owners
- [PR #524](https://github.com/agglayer/agglayer-contracts/pull/524) - Feature/initialize tool refactor
- [PR #528](https://github.com/agglayer/agglayer-contracts/pull/528) - Internal audit + initializaiton fixes
- [PR #522](https://github.com/agglayer/agglayer-contracts/pull/522) - feat: Finished upgrade contracts to v12 script
- [PR #504](https://github.com/agglayer/agglayer-contracts/pull/504) - [v0.3.5 phase III]:newConsensusType-outpostsL2
- [PR #520](https://github.com/agglayer/agglayer-contracts/pull/520) - small docs fixes
- [PR #519](https://github.com/agglayer/agglayer-contracts/pull/519) - Fix found informationals
- [PR #517](https://github.com/agglayer/agglayer-contracts/pull/517) - internal audit fixes and PR comments
- [PR #518](https://github.com/agglayer/agglayer-contracts/pull/518) - trigger tests on feature/outposts branch
- [PR #516](https://github.com/agglayer/agglayer-contracts/pull/516) - update changelog
- [PR #507](https://github.com/agglayer/agglayer-contracts/pull/507) - add critical tooling tag check
- [PR #515](https://github.com/agglayer/agglayer-contracts/pull/515) - Rebase multisig PR with outposts current work
- [PR #511](https://github.com/agglayer/agglayer-contracts/pull/511) - Audit remediations
- [PR #506](https://github.com/agglayer/agglayer-contracts/pull/506) - L2OO v3
- [PR #509](https://github.com/agglayer/agglayer-contracts/pull/509) - Add IVersion interface
- [PR #499](https://github.com/agglayer/agglayer-contracts/pull/499) - agg oracle comittee
- [PR #502](https://github.com/agglayer/agglayer-contracts/pull/502) - update versions