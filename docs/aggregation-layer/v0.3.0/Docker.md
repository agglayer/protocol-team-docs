# Docker documentation

By default the following mnemonic will be used to deploy the smart contracts `MNEMONIC="test test test test test test test test test test test junk"`.
Also the first 20 accounts of this mnemonic will be funded with ether.
The first account of the mnemonic will be the deployer of the smart contracts and therefore the holder of all the MATIC test tokens, which are necessary to pay the `sendBatch` transactions.
You can change the deployment `mnemonic` creating a `.env` file in the project root with the following variable:
`MNEMONIC=<YOUR_MENMONIC>`

## 1. Requirements

- node version: 14.x
- npm version: 7.x
- docker
- docker-compose

## 2. Config files
In the case of the Docker deployment, we are going to take the default configuration files that we have in this [folder](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/docker/scripts/v2).

### 2.1. deploy_parameters.json

### 2.1.1. Docker config file

```
{
 "test": true,
 "timelockAdminAddress": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
 "minDelayTimelock": 3600,
 "salt": "0x0000000000000000000000000000000000000000000000000000000000000000",
 "initialZkEVMDeployerOwner": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
 "admin": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
 "trustedAggregator": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
 "trustedAggregatorTimeout": 604799,
 "pendingStateTimeout": 604799,
 "emergencyCouncilAddress": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
 "polTokenAddress": "",
 "zkEVMDeployerAddress": "",
 "deployerPvtKey": "",
 "maxFeePerGas": "",
 "maxPriorityFeePerGas": "",
 "multiplierGas": ""
}
```

### 2.1.2. Description

-   `test`: bool, Indicate if it's a test deployment, which will fund the deployer address with pre minted ether and will give more powers to the deployer address to make easier the flow.
-   `timelockAdminAddress`: address, Timelock owner address, able to send start an upgradeability process via timelock
-   `minDelayTimelock`: number, Minimum timelock delay,
-   `salt`: bytes32, Salt used in `PolygonZkEVMDeployer` to deploy deterministic contracts, such as the PolygonZkEVMBridge
-   `initialZkEVMDeployerOwner`: address, Initial owner of the `PolygonZkEVMDeployer`
-   `admin`: address, Admin address, can adjust RollupManager parameters or stop the emergency state
-   `trustedAggregator`: address, Trusted aggregator address
-   `trustedAggregatorTimeout`: uint64, If a sequence is not verified in this timeout everyone can verify it
-   `pendingStateTimeout`: uint64, Once a pending state exceeds this timeout it can be consolidated by everyone
-   `emergencyCouncilAddress`: address, Emergency council address
-   `polTokenAddress`: address, POL token address, only if deploy on testnet can be left blank and will fulfilled by the scripts.
-   `zkEVMDeployerAddress`: address, Address of the `PolygonZkEVMDeployer`. Can be left blank, will be fulfilled automatically with the `deploy:deployer:ZkEVM:goerli` script.
-   `ppVKey`: pessimistic program verification key (AggLayerGateway)
-   `ppVKeySelector`:  The 4 bytes selector to add to the pessimistic verification keys (AggLayerGateway)
-   `realVerifier`: bool, Indicates whether deploy a real verifier or not (AggLayerGateway)

### 2.2. create_rollup_parameters.json

### 2.2.1. Docker config file (FEP, by default)

```
{
    "realVerifier": false,
    "trustedSequencerURL": "http://zkevm-json-rpc:8123",
    "networkName": "zkevm",
    "description": "0.0.1",
    "trustedSequencer": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    "chainID": 1001,
    "adminZkEVM": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    "forkID": 0,
    "consensusContract": "AggchainFEP",
    "gasTokenAddress": "deploy",
    "deployerPvtKey": "",
    "maxFeePerGas": "",
    "maxPriorityFeePerGas": "",
    "multiplierGas": "",
    "programVKey": "0xac51a6a2e513d02e4f39ea51d4d133cec200b940805f1054eabbb6d6412c959f",
    "isVanillaClient": true,
    "sovereignParams": {
        "bridgeManager": "0xC7899Ff6A3aC2FF59261bD960A8C880DF06E1041",
        "sovereignWETHAddress": "0x0000000000000000000000000000000000000000",
        "sovereignWETHAddressIsNotMintable": false,
        "globalExitRootUpdater": "0xB55B27Cca633A73108893985350bc26B8A00C43a",
        "globalExitRootRemover": "0xB55B27Cca633A73108893985350bc26B8A00C43a"
    },
    "aggchainParams": {
        "initParams": {
            "l2BlockTime": 1,
            "rollupConfigHash": "0x1111111111111111111111111111111111111111111111111111111111111111",
            "startingOutputRoot" : "0x1111111111111111111111111111111111111111111111111111111111111111",
            "startingBlockNumber": 100,
            "startingTimestamp": 7000000,
            "submissionInterval": 5,
            "aggchainManager": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
            "optimisticModeManager": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
        },
        "useDefaultGateway": true,
        "ownedAggchainVKey": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "aggchainVKeySelector": "0x1234",
        "vKeyManager": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    }
}
```

### 2.2.2. Description

-   `realVerifier`: bool, Indicates whether deploy a real verifier or not for the new created
-   `trustedSequencerURL`: string, trustedSequencer URL
-   `networkName`: string, networkName
-   `description`: string, Description of the new rollup type
-   `trustedSequencer`: address, trusted sequencer address
-   `chainID`: uint64, chainID of the new rollup
-   `adminZkEVM`: address, Admin address, can adjust Rollup parameters
-   `forkID`: uint64, Fork ID of the new rollup, indicates the prover (zkROM/executor) version
-   `consensusContract`: select between consensus contract. Supported: `["PolygonZkEVMEtrog", "PolygonValidiumEtrog", "PolygonPessimisticConsensus", "AggchainECDSA", "AggchainFEP"]`.
-   `gasTokenAddress`: address, Gas token address, empty or address(0) for ether
-   `programVKey`:  program key for pessimistic consensus. if consensus != pessimistic, programVKey === bytes32(0).
-   `isVanillaClient`: Flag for vanilla/sovereign clients handling
-   `sovereignParams`: Only mandatory if isVanillaClient = true
    -   `bridgeManager`: bridge manager address
    -   `sovereignWETHAddress`: sovereign WETH address
    -   `sovereignWETHAddressIsNotMintable`: Flag to indicate if the wrapped ETH is not mintable
    -   `globalExitRootUpdater`: Address of globalExitRootUpdater for sovereign chains
    -   `globalExitRootRemover`: Address of globalExitRootRemover for sovereign chains
- `aggchainParams`: Only mandatory if consensusContract is AggchainECDSA or AggchainFEP
    - `initParams`: Only mandatory if consensusContract is AggchainFEP
        - `l2BlockTime`: The time between L2 blocks in seconds
        - `rollupConfigHash`: The hash of the chain's rollup configuration
        - `startingOutputRoot`: Init output root
        - `startingBlockNumber`: The number of the first L2 block
        - `startingTimestamp`:  The timestamp of the first L2 block
        - `submissionInterval`: The minimum interval in L2 blocks at which checkpoints must be submitted
        - `aggchainManager`: Address that manages all the functionalities related to the aggchain
        - `optimisticModeManager`: Address that can trigger the optimistic mode
    - `useDefaultGateway`: bool, flag to setup initial values for the owned gateway
    - `ownedAggchainVKey`: bytes32, Initial owned aggchain verification key
    - `aggchainVKeySelector`: bytes2, Initial aggchain selector
    - `vKeyManager`: address, Initial vKeyManager

### 2.2.3. Docker config file (ECDSA)

This aggchain is not deployed by default. You can deploy it, as we mentioned in the following section, by running the script that deploys a rollup of each type.

```
{
    "trustedSequencerURL": "http://zkevm-json-rpc:8123",
    "networkName": "zkevm",
    "description": "0.0.1",
    "trustedSequencer": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    "chainID": 1002,
    "adminZkEVM": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    "forkID": 0,
    "consensusContract": "AggchainECDSA",
    "gasTokenAddress": "deploy",
    "deployerPvtKey": "",
    "maxFeePerGas": "",
    "maxPriorityFeePerGas": "",
    "multiplierGas": "",
    "programVKey": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "isVanillaClient": true,
    "sovereignParams": {
        "bridgeManager": "0xC7899Ff6A3aC2FF59261bD960A8C880DF06E1041",
        "sovereignWETHAddress": "0x0000000000000000000000000000000000000000",
        "sovereignWETHAddressIsNotMintable": false,
        "globalExitRootUpdater": "0xB55B27Cca633A73108893985350bc26B8A00C43a",
        "globalExitRootRemover": "0xB55B27Cca633A73108893985350bc26B8A00C43a"
    },
    "aggchainParams": {
        "useDefaultGateway": true,
        "initOwnedAggchainVKey": "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
        "initAggchainVKeyVersion": "0x5678",
        "vKeyManager": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    }
}

```

### 2.2.3. Docker config file (ecdsa-v.0.2.0)

This aggchain is not deployed by default. You can deploy it, as we mentioned in the following section, by running the script that deploys a rollup of each type.

```
{
    "realVerifier": false,
    "trustedSequencerURL": "http://zkevm-json-rpc:8123",
    "networkName": "zkevm",
    "description": "0.0.1",
    "trustedSequencer": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    "chainID": 1003,
    "adminZkEVM": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    "forkID": 11,
    "consensusContract": "PolygonPessimisticConsensus",
    "gasTokenAddress": "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
    "deployerPvtKey": "",
    "maxFeePerGas": "",
    "maxPriorityFeePerGas": "",
    "multiplierGas": "",
    "programVKey": "0xac51a6a2e513d02e4f39ea51d4d133cec200b940805f1054eabbb6d6412c959f",
    "isVanillaClient": false,
    "sovereignParams": {
        "bridgeManager": "0xC7899Ff6A3aC2FF59261bD960A8C880DF06E1041",
        "sovereignWETHAddress": "0x0000000000000000000000000000000000000000",
        "sovereignWETHAddressIsNotMintable": false,
        "globalExitRootUpdater": "0xB55B27Cca633A73108893985350bc26B8A00C43a",
        "globalExitRootRemover": "0xB55B27Cca633A73108893985350bc26B8A00C43a"
    }
}
```

### 2.3. Optional Parameters on both deployments

-   `deployerPvtKey`: string, pvtKey of the deployer, overrides the address in `MNEMONIC` of `.env` if exist
-   `maxFeePerGas`: string, Set `maxFeePerGas`, must define as well `maxPriorityFeePerGas` to use it
-   `maxPriorityFeePerGas`: string, Set `maxPriorityFeePerGas`, must define as well `maxFeePerGas` to use it
-   `multiplierGas`: number, Gas multiplier with 3 decimals. If `maxFeePerGas` and `maxPriorityFeePerGas` are set, this will not take effect
-   `dataAvailabilityProtocol`: string, Data availability protocol, only mandatory/used when consensus contract is a Validium, currently the only supported value is: `PolygonDataCommittee`

## 3. Run script

In project root execute:

- With this command, you can deploy an environment with an `AggchainFEP`:
```
npm i
npm run docker:contracts
```

- With the following command, you achieve the same, but using the new version of `docker-compose`:

```
npm i
npm run dockerv2:contracts
```

- And finally, with this command, you get an environment with `AggchainFEP`, `AggchainECDSA`, and `PessimisticConsensus`, using the new version of `docker-compose`:
``` 
npm i 
npm run dockerv2:contracts:all
```

A new docker `geth-zkevm-contracts:latest` will be created
This docker will contain a geth node with the deployed contracts.
To run the docker you can use: `docker run -p 8545:8545 geth-zkevm-contracts:latest`.

To create other rollup:

-   copy template from `./docker/scripts/v2/create_rollup_parameters_docker-xxxx.json` to `deployment/v2/create_rollup_parameters.json`
-   update `chainID`
-   copy `genesis.json`, `genesis_sovereign.json` and `deploy_ouput.json` (from `docker/deploymentOutput`) to `deployment/v2/`
-   run `npx hardhat run ./deployment/v2/4_createRollup.ts --network localhost`
-   If you want, you can copy the file that has been generated here (`deployment/v2/create_rollup_output_*.json`) to deployment output folder (`docker/deploymentOutput`)

## 4. Deployment output

The deployment output can be found in:

- `docker/deploymentOutput/create_rollup_output.json`
- `docker/deploymentOutput/deploy_output.json`
- `docker/deploymentOutput/genesis.json`
- `docker/deploymentOutput/genesis_sovereign.json`
- `docker/deploymentOutput/aggLayerGateway.json`

## 5. Diff with version v0.2.0

### 5.1. deploy_parameters.json

- Add:
    -   `ppVKey`: pessimistic program verification key (AggLayerGateway)
    -   `ppVKeySelector`:  The 4 bytes selector to add to the pessimistic verification keys (AggLayerGateway)
    -   `realVerifier`: bool, Indicates whether deploy a real verifier or not (AggLayerGateway)

### 5.2. deploy_output.json

- Add:
    - `aggLayerGatewayAddress`: AggLayerGateway address
    - `pessimisticVKeyRouteALGateway`: AggLayerGateway information. Pessimistic VKey Route:
        - `ppVKey`: pessimistic program verification key
        - `ppVKeySelector`: 4 bytes selector to add to the pessimistic verification keys
        - `verifier`: address of the SP1 verifier contract

### 5.3. create_rollup_parameters.json

- Add:
    -   `isVanillaClient`: Flag for vanilla/sovereign clients handling
    -   `sovereignParams`: Only mandatory if isVanillaClient = true
        -   `bridgeManager`: bridge manager address
        -   `sovereignWETHAddress`: sovereign WETH address
        -   `sovereignWETHAddressIsNotMintable`: Flag to indicate if the wrapped ETH is not mintable
        -   `globalExitRootUpdater`: Address of globalExitRootUpdater for sovereign chains
        -   `globalExitRootRemover`: Address of globalExitRootRemover for sovereign chains
    - `aggchainParams`: Only mandatory if consensusContract is AggchainECDSA or AggchainFEP
        - `initParams`: Only mandatory if consensusContract is AggchainFEP
            - `l2BlockTime`: The time between L2 blocks in seconds
            - `rollupConfigHash`: The hash of the chain's rollup configuration
            - `startingOutputRoot`: Init output root
            - `startingBlockNumber`: The number of the first L2 block
            - `startingTimestamp`:  The timestamp of the first L2 block
            - `submissionInterval`: The minimum interval in L2 blocks at which checkpoints must be submitted
            - `aggchainManager`: Address that manages all the functionalities related to the aggchain
            - `optimisticModeManager`: Address that can trigger the optimistic mode
        - `useDefaultGateway`: bool, flag to setup initial values for the owned gateway
        - `ownedAggchainVKey`: bytes32, Initial owned aggchain verification key
        - `aggchainVKeySelector`: bytes2, Initial aggchain selector
        - `vKeyManager`: address, Initial vKeyManager

### 5.4. create_rollup_output_*

- Output from `4_createRollup` is `create_rollup_output_<timestamp>.json`.
- Add `defaultAggchainVKeyALGateway`, AggLayerGateway information. Default aggchain VKey:
    - `defaultAggchainSelector`: 4 bytes selector for default aggchain verification key
    - `newAggchainVKey`: default aggchain verification key

### 5.5. Deployed consensus

Previously, a `PolygonPessimisticConsensus` was deployed. Now, by default, we deploy an `AggchainFEP`.  

If you choose the `dockerv2:contracts:all` option, all three versions are deployed:

- `AggchainFEP`
- `AggchainECDSA`
- `PolygonPessimisticConsensus`
