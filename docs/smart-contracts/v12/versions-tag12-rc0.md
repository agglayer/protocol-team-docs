## Tag `12.0.0-rc0`

### Core Infrastructure
* `PolygonRollupManager`: v1.0.0
* [`PolygonZkEVMBridgeV2`: v1.0.0 → v1.1.0](./PolygonZkEVMBridgeV2-v1.1.0.md)
* `PolygonZkEVMGlobalExitRootV2`: v1.0.0
* [`AggLayerGateway`: v1.0.0 → v1.1.0](./AggLayerGateway-Multisig.md)

### Bridge Contracts
* [`BridgeL2SovereignChain`: v1.0.0 → v2.0.0](./BridgeL2SovereignChain-v2.0.0.md)
* `GlobalExitRootManagerL2SovereignChain`: v1.0.0

### Aggchain Implementations
* [`AggchainBase`](./AggchainBase.md): Abstract base contract for aggchain implementations
* [`AggchainFEP`: v3.0.0](./AggchainFEP.md) - FEP (Full Exit Proof) implementation with SP1 proving
* [`AggchainECDSAMultisig`: v1.0.0](./AggchainECDSAMultisig.md) - ECDSA multisig-based implementation
* `AggOracleCommittee`: v1.0.0

### Key Features
* **Multisig Support**: Enhanced multisig management in AggLayerGateway and aggchain contracts
* **Multiple Initialization Paths**: Support for fresh deployments and migrations from existing contracts
* **Configuration Management**: FEP supports multiple OP Succinct configurations
* **Flexible Verification**: Choice between SP1 proofs (FEP) and ECDSA signatures (Multisig)