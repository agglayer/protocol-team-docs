# Compatibility Table

The following compatibility table shows which components should be used depending on the chain you are working with. This table helps ensure that the correct configurations and contracts are selected for each setup:

|    Chain     |  verifierType   |        SC consensus         |  Proofs/Prover   |       Client       | AgglayerBridgeL2 | AgglayerGERL2 + AggOracle | AggOracleCommittee  | AggSender | Provers |
|:------------:|:---------------:|:---------------------------:|:----------------:|:------------------:|:----------------:|:-------------------------:|:-------------------:|:---------:|:-------:|
|    zkEVM     | StateTransition |      [PolygonZkEVMEtrog](https://github.com/agglayer/agglayer-contracts/blob/v12.1.5/contracts/consensus/zkEVM/PolygonZkEVMEtrog.sol)    |   FEP # Hermez   |  legacy-cdk-erigon |        ❌        |            ❌             |           ❌        |     ❌    |    ❌   |
|  Valididum   | StateTransition |    [PolygonValidiumEtrog](https://github.com/agglayer/agglayer-contracts/blob/v12.1.5/contracts/consensus/validium/PolygonValidiumEtrog.sol)     |   FEP # Hermez   |  legacy-cdk-erigon |        ❌        |            ❌             |           ❌        |     ❌    |    ❌   |
| v0.3.0-ECDSA |    ALGateway    |   [AggchainECDSAMultisig](https://github.com/agglayer/agglayer-contracts/blob/v12.1.5/contracts/aggchains/AggchainECDSAMultisig.sol)     |     PP # SP1     |  legacy-cdk-erigon |        ❌        |            ❌             |           ❌        |     ✅    |    ❌   |
| v0.3.0-ECDSA |    ALGateway    |   [AggchainECDSAMultisig](https://github.com/agglayer/agglayer-contracts/blob/v12.1.5/contracts/aggchains/AggchainECDSAMultisig.sol)     |     PP # SP1     | vanilla-cdk-erigon |  ✅ (optional)   |            ✅             |    ✅ (optional)    |     ✅    |    ❌   |
| v0.3.0-ECDSA |    ALGateway    |   [AggchainECDSAMultisig](https://github.com/agglayer/agglayer-contracts/blob/v12.1.5/contracts/aggchains/AggchainECDSAMultisig.sol)     |     PP # SP1     |      op-stack      |  ✅ (optional)   |            ✅             |    ✅ (optional)    |     ✅    |    ❌   |
|  v0.3.0-FEP  |    ALGateway    |         [AggchainFEP](https://github.com/agglayer/agglayer-contracts/blob/v12.1.5/contracts/aggchains/AggchainFEP.sol)         | (PP + FEP) # SP1 |      op-stack      |        ✅        |            ✅             |    ✅ (optional)    |     ✅    |    ✅   |

### More information

### Client - Sovereign contracts compatibility
When considering compatibility, it’s important to understand that sovereign contracts (`AgglayerBridgeL2` + `AgglayerGERL2`) can only be used if you are not using a `hermez-prover` prover.
The reason for this is that in the case of the `hermez-prover`, GERs are injected directly by the client. If sovereign contracts were used in this configuration, the GERs would instead be injected by the `aggOracle`.
This would pose a critical security risk, as it would allow someone to easily steal all the bridge funds (the validation would not be enforced properly).

### AggOracleCommittee
When using sovereign GERs, they are injected by the `AggOracle`.
If you want to use multiple `AggOracle`, you can optionally include an `AggOracleCommittee`, which coordinates among them.

### AgglayerBridgeL2
The sovereign bridge is only required for the `AggchainFEP` setup because `hashChains` are necessary, which are used in the `aggchain-proof` (located in the `provers`).
However, when using it, you will lose access to some of the utilities available in other configurations, such as custom mappings, local exit root, and similar features.

### Provers
Repository provers [link](https://github.com/agglayer/provers/releases).
