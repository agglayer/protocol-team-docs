# Tooling

## Add new rollup type
![addNewRollupType](/aggregation-layer/v0.3.0/img/tool_addNewRollupType.png)

Tool to call `addNewRollupType` function.

This tool adds a new rollup type to `PolygonRollupManager` contract. 

1. Go to repository: [agg-contracts-internal](https://github.com/agglayer/agg-contracts-internal).
2. You can use [this tool](https://github.com/agglayer/agg-contracts-internal/tree/feature/ongoing-v0.3.0/tools/addRollupType) to add new rollup type
    - Follow the steps found in this [README](https://github.com/agglayer/agg-contracts-internal/blob/feature/ongoing-v0.3.0/tools/addRollupType/README.md).
    - Set parameters `add_rollup_type.json`.
    - Run tool `npx hardhat run ./tools/addRollupType/addRollupType.ts --network <network>`

## Create new rollup (attachAggchainToAL)
![attachAggchainToAL](/aggregation-layer/v0.3.0/img/tool_attachAggchainToAL.png)

Tool to call `attachAggchainToAL` function.

This tool adds a new aggchain to `PolygonRollupManager` contract. 

1. Go to repository: [agg-contracts-internal](https://github.com/agglayer/agg-contracts-internal).
2. You can use [this tool](https://github.com/agglayer/agg-contracts-internal/tree/feature/ongoing-v0.3.0/tools/createNewRollup) to add new chain
    - Follow the steps found in this [README](https://github.com/agglayer/agg-contracts-internal/blob/feature/ongoing-v0.3.0/tools/createNewRollup/README.md).
    - Set parameters `create_new_rollup.json`.
    - Copy `genesis.json` file
    - Run tool `npx hardhat run ./tools/createNewRollup/createNewRollup.ts --network <network>`

## Upate rollup
![updateRollup](/aggregation-layer/v0.3.0/img/tool_updateRollup.png)

Tool to call `updateRollup` function.

This tool update rollup to new rollup type in `PolygonRollupManager` contract.

1. Go to repository: [agg-contracts-internal](https://github.com/agglayer/agg-contracts-internal).
2. You can use [this tool](https://github.com/agglayer/agg-contracts-internal/tree/feature/ongoing-v0.3.0/tools/updateRollup) to update rollup to new type
    - Follow the steps found in this [README](https://github.com/agglayer/agg-contracts-internal/blob/feature/ongoing-v0.3.0/tools/updateRollup/README.md).
    - Set parameters `updateRollup.json`
    - Run tool `npx hardhat run ./tools/updateRollup/updateRollup.ts --network <network>`