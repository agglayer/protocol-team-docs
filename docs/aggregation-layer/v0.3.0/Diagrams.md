# Flows

## Add new Aggchain FEP

Here's the flow that needs to be followed to add a new aggchain (in this case, an AggchainFEP):

![Flow add new AggchainFEP](/aggregation-layer/v0.3.0/img/flow_FEP.png)

### addNewRollupType
First step a new rollup type is added. This [tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/addRollupType) will be used to do it.

Following the next [README](https://github.com/agglayer/agglayer-contracts/blob/v11.0.0/tools/addRollupType/README.md), a new rollup type is added by calling the `addNewRollupType` function of `PolygonRollupManager` contract. Once called, the `rollupTypeID` parameter will be obtained and should be used in the following tool.

### attachAggchainToAL
The second step is to create a new chain with the rollup type we created earlier. This [tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/createNewRollup) will be used to do it.

The following [README](https://github.com/agglayer/agglayer-contracts/blob/v11.0.0/tools/createNewRollup/README.md) can be followed to create the new `AggchainFEP` by calling the `attachAggchainToAL` function, using the `rollupTypeID` created with the previous tool.

### add vkeys to AggLayerGateway

The third step is to initialize the vkeys in `AggLayerGateway` contract:

- This [tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/aggLayerGatewayTools/addPessimisticVKeyRoute) is used to add the pessimistic vkey route (`addPessimisticVKeyRoute`).
- This [tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/aggLayerGatewayTools/addDefaultAggchainVKey) is used to add the aggchain vkey (`addDefaultAggchainVKey`).

## Update v0.2.0-ECDSA to v0.3.0-FEP

![Flow update to AggchainFEP](/aggregation-layer/v0.3.0/img/update_FEP.png)

### addNewRollupType
First step a new rollup type is added. This [tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/addRollupType) will be used to do it.

Following the next [README](https://github.com/agglayer/agglayer-contracts/blob/v11.0.0/tools/addRollupType/README.md), a new rollup type is added by calling the `addNewRollupType` function of `PolygonRollupManager` contract. Once called, the `rollupTypeID` parameter will be obtained and should be used in the following tool.

### updateRollup
The second step is to update the old rollup to the new rollup type that was created with the previous tool. This [tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/updateRollup) will be used to do it.

The following [README](https://github.com/agglayer/agglayer-contracts/blob/v11.0.0/tools/updateRollup/README.md) can be followed to update the old rollup to the new rollup type created with the previous tool by calling the `updateRollup` function, using the `rollupTypeID` created with the previous tool.

### add vkeys to AggLayerGateway

The third step is to initialize the vkeys in `AggLayerGateway` contract:

- This [tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/aggLayerGatewayTools/addPessimisticVKeyRoute) is used to add the pessimistic vkey route (`addPessimisticVKeyRoute`).
- This [tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/aggLayerGatewayTools/addDefaultAggchainVKey) is used to add the aggchain vkey (`addDefaultAggchainVKey`).

## Verify FEP

### Data Schemas
To better understand the verification flow, it is important to first understand the structure of the data involved. The following section outlines the three core data schemas that are used throughout the process. Each schema defines a specific data format that plays a critical role in different stages of the verification logic.

#### Proof
This is how the proof is constructed:
![proof](/aggregation-layer/v0.3.0/img/proof_A.png)

You can find the full information of the proof we use for verification in this [spec](SC-specs.md#22-pessimistic-proof-routes).

#### AggchainData FEP
Specific custom data used to verify Aggregation Layer chains.
This data is used, for example, in the `getAggchainHash` function and to extract the necessary information required during the verification process.

![aggchainData](/aggregation-layer/v0.3.0/img/aggchainData_B.png)

You can find more details about this AggchainData for FEP in this [link](SC-specs.md#52-fep).

#### AggchainVKeySelector
This is part of the `AggchainData`.
We use it to determine the `aggchainVKey`, which is then used in the computation of the `getAggchainHash` function.
The following diagram shows how this selector is built:

![aggchainVKeySelector](/aggregation-layer/v0.3.0/img/aggchainVKeySelector.png)

For more information, see this [link](SC-specs.md#5-aggchain-types-provided).

### Flow diagram
The following diagram aims to illustrate the flow of data during a verification process.

> Note: Before the flow itself begins, the first essential step is to register a route in the AgglayerGateway contract using the addPessimisticVKeyRoute function. This setup step is not part of the flow per se but is a prerequisite for the rest of the process.

![Verify pessimistic proof](/aggregation-layer/v0.3.0/img/verify_flow.png)

The process starts with a call to the `verifyPessimisticTrustedAggregator` function.

Inside this function, the `getInputPessimisticBytes` function is called.

As part of its execution, the `getAggchainHash` function is invoked. The `getAggchainHash` function uses the `aggchainData` to compute the hash.

Once the `inputPessimisticBytes` are obtained, and along with the proof we previously described, the verification call is forwarded to the `AgglayerGateway` with function `verifyPesimissticProof`.

Within the `AgglayerGateway` , the `ppSelector` extracted from the proof is used to correctly route the call to the appropriate verifier.

If the verification succeeds:

- The `updateExitRoot` function is called..
- Then, using the `aggchainData`, the `onVerifyPessimistic` function of the corresponding Aggchain contract is called.
- This function emits `OutputProposed` event.

## Migration to PP or ALGateway

### Migration Initialization

A new [function](https://github.com/agglayer/agglayer-contracts/blob/v11.0.0/contracts/v2/PolygonRollupManager.sol#L954), `initMigration`, enables the explicit start of a migration process.

This function performs checks to ensure:

- It checks that the current `rollupVerifierType` is `StateTransition`, confirming the rollup originates from the legacy system.
- It ensures there are no pending batches left unverified before initiating the migration.
- It enforces that the new `rollupVerifierType` being set is `PP` or `ALGateway`.
- Finally, it calls the internal `_updateRollup` function to execute the migration. To support this, the internal check in `updateRollup` that restricted updates to only the same verifier type or ALGateway was removed. This restriction has been relocated to the public functions, allowing internal reuse of `updateRollup` for all update flows—including migrations—while preserving proper guard conditions.

### Proof Verification During Migration

The `verifyPessimisticTrustedAggregator` [function](https://github.com/agglayer/agglayer-contracts/blob/v11.0.0/contracts/v2/PolygonRollupManager.sol#L1313) was adjusted to support special cases that occur during the migration process.

- It now allows the verification of bootstrap certificates, which are required to validate the first proof after switching to the new system.
- It's a hard requirement that the `newLocalExitRoot` matches the current `lastLocalExitRoot` meaning that the certificates covers all the bridges
> If the rollup has never verifed a batch with bridges, the expected `newLocalExitRoot` must be to root of an empty 32 levels tree
- These changes ensure that proofs submitted during migration are processed correctly without breaking the existing logic.

### Flow migration
![Flow migration](/aggregation-layer/v0.3.0/img/migration_flow.png)

#### addNewRollupType
First step a new rollup type is added. This [tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/addRollupType) will be used to do it.

Following the next [README](https://github.com/agglayer/agglayer-contracts/blob/v11.0.0/tools/addRollupType/README.md), a new rollup type is added by calling the `addNewRollupType` function of `PolygonRollupManager` contract. Once called, the `rollupTypeID` parameter will be obtained and should be used in the following tool.

#### initMigration
To initiate the migration, this tool can be used: [initMigration tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/initMigration)
We will see that an event indicating the migration has been initialized is emitted (`InitMigration`).
Finally, when the verification is done with `verifyPessimisticTrustedAggregator`, an event indicating that the migration has been completed will be emitted (`CompletedMigration`).