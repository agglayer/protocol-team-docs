# Compatibility Table

The following compatibility table shows which components should be used depending on the chain you are working with. This table helps ensure that the correct configurations and contracts are selected for each setup:

## Legend
### Clients


## Table

|    Chain     |  verifierType   |        SC consensus         |  Proofs/Prover   |       Client       |                      |        SC         |                         |           | Components |         |
|:------------:|:---------------:|:---------------------------:|:----------------:|:------------------:|:--------------------:|:-----------------:|:-----------------------:|:---------:|:---------:|:-------:|
|              |                 |                             |                  |                    | AgglayerBridgeL2     | AgglayerGERL2     | AggOracleCommittee      | AggOracle | AggSender | Provers |
|    zkEVM     | StateTransition |      [PolygonZkEVMEtrog](https://github.com/agglayer/agglayer-contracts/blob/v12.1.5/contracts/consensus/zkEVM/PolygonZkEVMEtrog.sol)    |   FEP # Hermez   |  legacy-cdk-erigon |          ❌          |         ❌        |            ❌           |     ❌    |     ❌    |    ❌   |
|  Valididum   | StateTransition |    [PolygonValidiumEtrog](https://github.com/agglayer/agglayer-contracts/blob/v12.1.5/contracts/consensus/validium/PolygonValidiumEtrog.sol)     |   FEP # Hermez   |  legacy-cdk-erigon |          ❌          |         ❌        |            ❌           |     ❌    |     ❌    |    ❌   |
| v0.3.5-ECDSA |    ALGateway    |   [AggchainECDSAMultisig](https://github.com/agglayer/agglayer-contracts/blob/v12.1.5/contracts/aggchains/AggchainECDSAMultisig.sol)     |     PP # SP1     |  legacy-cdk-erigon |    ✅ (optional)     |   ✅ (optional)   |      ✅ (optional)      | ✅ (optional) |     ✅    |    ❌   |
| v0.3.5-ECDSA |    ALGateway    |   [AggchainECDSAMultisig](https://github.com/agglayer/agglayer-contracts/blob/v12.1.5/contracts/aggchains/AggchainECDSAMultisig.sol)     |     PP # SP1     | vanilla-cdk-erigon |    ✅ (optional)     |         ✅        |      ✅ (optional)      |     ✅    |     ✅    |    ❌   |
| v0.3.5-ECDSA |    ALGateway    |   [AggchainECDSAMultisig](https://github.com/agglayer/agglayer-contracts/blob/v12.1.5/contracts/aggchains/AggchainECDSAMultisig.sol)     |     PP # SP1     |      op-stack      |    ✅ (optional)     |         ✅        |      ✅ (optional)      |     ✅    |     ✅    |    ❌   |
|  v0.3.5-FEP  |    ALGateway    |         [AggchainFEP](https://github.com/agglayer/agglayer-contracts/blob/v12.1.5/contracts/aggchains/AggchainFEP.sol)         | (PP + FEP) # SP1 |      op-stack      |          ✅          |         ✅        |      ✅ (optional)      |     ✅    |     ✅    |    ✅   |


## Clients
### Client legacy-cdk-erigon
To give some context compared to the previous version, we wanted to make a clear distinction between `vanilla-cdk-erigon` and `legacy-cdk-erigon`.
The latter is the client responsible for injecting batches and GERs, while the former will handle this through `AgglayerGERL2` and `AggOracle`.

### Client - Sovereign contracts compatibility
When considering compatibility, it’s important to understand that sovereign contracts (`AgglayerBridgeL2` + `AgglayerGERL2`) can only be used if you are not using a `hermez-prover` prover.
The reason for this is that in the case of the `hermez-prover`, GERs are injected directly by the client. If sovereign contracts were used in this configuration, the GERs would instead be injected by the `aggOracle`.
This would pose a critical security risk, as it would allow someone to easily steal all the bridge funds (the validation would not be enforced properly).

## L2 SC
### AgglayerBridgeL2
The `AgglayerBridgeL2` smart contract is designed to be deployed on L2.
It is only required for the `AggchainFEP` setup because `hashChains` are necessary, which are used in the `aggchain-proof` (located in the `provers`).
The contract implements the same `LocalBalanceTree` logic as the pessimistic program.
The contract allows authorized parties to insert and remove global exit roots, maintaining a mapping of these roots with an insertion order. All GERs inserted on L2 must be verifiable against a valid `L1InfoTreeRoot`. This ensures the validity of every GER injected into the chain.

> More information v0.2.0 [link](https://agglayer.github.io/protocol-team-docs/aggregation-layer/v0.2.0/SovereignChains/SovereignBridge%20SC/)
> Update v0.3.0 [link](https://agglayer.github.io/protocol-team-docs/aggregation-layer/v0.3.0/SC-specs/#72-bridgel2sovereignchain)

## Components
### AggOracle
Coordinate GER injection [link](https://github.com/agglayer/aggkit/tree/develop/aggoracle).

### Provers
Repository provers [link](https://github.com/agglayer/provers/releases).
