## TLDR
- Sovereign chains only uses pessimistic proof
- Types of Sovereign chains:
    - existing chain: deploy sovereign bridge contracts
    - new chain
        - cdk-erigon client: mimic genesis cdk-erigon. Standard genesis + injected batch information
        - vanilla client (op-geth): genesis with sovereign bridge contracts + initialize the bridge information (injected batch)

## Resources
- [Tool create new rollup](https://github.com/0xPolygonHermez/zkevm-contracts/tree/feature/audit-remediations/tools/createNewRollup)
- [SovereignBridge SC](https://github.com/0xPolygonHermez/zkevm-contracts/tree/feature/audit-remediations/contracts/v2/sovereignChains)

## Description
Sovereign chains refer to chains that have their own independent governance, state management, and operations while still being able to interact with other chains through the invariant/pessimistic proof for interoperability.

Sovereign chains may rely on independent security models. They can use their own consensus mechanism but their security will only impact their own chain. They don't have to be EVM compatible as long as they have any kind of accountability of balances. For example Solana.

## Types
### Existing chains
Sovereign bridge SC should be deployed on this chain in order to add BridgeLxLy functionality.
cdk-component `agg-oracle` will be in charge to add/remove GERs to this chain.
It is important to mention that an existing chain has its own secuencer and its own consensus.

### New chains
New chains will need a genesis in order to start. Depending on the client that is used, we would need to adapt the genesis creation.

#### cdk-erigon
This client works as the zkEVM was designed. Therefore, the client itself is the one that injects GER into L2 since it runs exactly the same as the executor from the zkEVM.
The bridge initialization is done via the `injected batch`. The `injected batch` is synched from L1 events in a rollup chain scenario. From a sovereign chain, this data is generated when the rollup is created

#### vanilla clients
This clients do not set nativelly GER into the bridge SC. In order to achieve that, the genesis should have the `SovereignBridge SC` instead of the legacy ones with its proper initialization. Therefore, the chain will just start with a genesisj that alredy ahve the `SovereignBridge SC` and its initialization.
cdk-component `agg-oracle` will be in charge to add GER to bridge

## Sovereign chains and the aggregation Layer
Sovereign chains will be able to join the aggregation layer and share liquidity (interoperability) with other chains always secured with the invariant proof in a way where a chain can not bridge more tokens than had been claimed. This is handled by aggregation layer and SP1 proving system.
In existing chains, the remapping functionality of the `SovereignBridge` will help to map other bridge tokens with the ones used by the BridgeLxLy.

## How to add a sovereign chain to the aggregation layer
To link Sovereign chains to the aggregation layer, they should be added as a chain to Polygon's rollupManager at L1. A new rollup should be created on L1 rollup Manager at the same time that a genesis is created for the L2 chain. The genesis will mainly have a bridge and a GlobalExitRootManager to handle bridges executed from and to that network.
The script to handle this process is the following: [Tool create new rollup](https://github.com/0xPolygonHermez/zkevm-contracts/tree/feature/audit-remediations/tools/createNewRollup)

## TLDR SC Sovereign new functionalities
- `BridgeL2SovereignChain` and `GlobalExitRootManagerL2SovereignChain`
    - 100% compatible with a vanilla client
    - Allow custom implementations of ERC20s since was a feature needed for some projects (e.g USDC, Katana staking)
- `GlobalExitRootManagerL2SovereignChain`
    - the logic change basically to allow insert GERs from the EVM, a new important event will be `InsertGlobalExitRoot`
    - abiltiy to delete global exit roots, new event `RemoveLastGlobalExitRoot`
    - bridge syncher componenets should we aware fo those events
- `BridgeL2SovereignChain`
    - add custom erc20 implementations via the feature `custom mappings`
    - event `SetSovereignTokenAddress` , the bridge now will map an erc20 given a `uint32 originNetwork # address originTokenAddress`, to an address `sovereignTokenAddress` (instead of the default created by the bridge). This is important to keep track, since we will have several tokens supported on or UI, and e.g the user will want to know easily which address has USDC mainnet (originNetwork = 0, address = USDCmainnet)
    - `MigrateLegacyToken` scenario: default erc20 token was created `defaultERC20`. A remap `SetSovereignTokenAddress` is done for that same token. Now all the new tokens minted will be to `sovereignTokenAddress` implementation, but there are some tokens of some users on `defaultERC20`  which we call it `legacyToken`. Ww let reconvert those tokens in the bridge from those users from the legacy to the new remmaped `sovereignTokenaddress` (this event signals the scenario mentioned)
    - `RemoveLegacySovereignTokenAddress`: very related to the last one. Once all the tokens has been mgirated, or in some point we can "stop support migrations" in that moment we will call this function and this event will be emitted