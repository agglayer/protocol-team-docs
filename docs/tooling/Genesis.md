[TOC]
## **Glossary**
- `sovereign chain`: chain that ONLY uses the pessimistic proof and has NOT any state-transition proof
- `sovereign contracts`: smart contracts to be used by vanilla clients (i.e. clients that does not have the necessary code to insert GER natively)
- `rollupTypeID`: it forces rollup parameters when the rollup is created
    - `legacy`: forces the genesis root
    - `sovereign`: genesis root is not forced (it is `0x00..000`)
- `timelock admin`: setup timelock administration address and its delay. Timelock controls upgrades over the L2 contracts (Bridge & GERManager)
- `premint account`: Initial pre minted account to be able to do a very first bridge claim

## **Chains types**
- `legacy`: Hermez prover based chains (zkEVM, Validums)
- `sovereign erigon`: sovereign chain with cdk-sovereign-erigon client
- `sovereign vanilla`: sovereign chain with a vanilla client

## **Table**
|                   | from rollupTypeID |    Bridge initialization     | SovereignContracts | timelock admin | premint account |
| :---------------: | :---------------: | :--------------------------: | :----------------: | :------------: | :-------------: |
|      legacy       |  :green_circle:   | Decentralized injected batch |        :x:         |      :x:       |       :x:       |
| sovereign erigon  |        :x:        |  Centralized injected batch  |        :x:         |      :x:       |       :x:       |
| sovereign vanilla |        :x:        |   Embedded in the genesis    |   :green_circle:   | :green_circle: | :green_circle:  |

## **Extra notes**
- `legacy`: genesis` on `legacy` chains is created beforehand the chain is created. It is set when the `rollupTypeID` is created
- `sovereign erigon`:
    - select a `genesis-base` based on the network (sepolia, mainnet) & RollupManager address (`genesis-base` is the genesis that has been used by `legacy` chains)
    - once the rollup is created, the Smart contract assigns a `rollupID` to the rollup
    - create `injected batch` data and add it to the client as metadata
- `sovereign vanilla`
    - select a `genesis-base` based on the network (sepolia, mainnet) & RollupManager address (`genesis-base` is the genesis that has been used by `legacy` chains)
    - upgrade `genesis-base` contracts in order to have `sovereign contracts`
    - upgrade `genesis-base` contracts in order to have a pre-mint account and setup its timelock security