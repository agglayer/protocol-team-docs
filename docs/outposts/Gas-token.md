# Gas token configuration

Every outpost has a native coin, the coin users pay gas with (for example `baseETH` on Base). When the `AgglayerBridgeL2` contract is initialized on the outpost, it must be told **which Agglayer token that native coin is**. This page explains the parameters involved, the two possible answers (**native L2 token** or **external token**), and what each one implies for users and operators.

!!! info
    Code references point to [`agglayer-contracts` v12.2.3](https://github.com/agglayer/agglayer-contracts/tree/v12.2.3) and [`agglayer` v0.6.2](https://github.com/agglayer/agglayer/tree/v0.6.2) (pessimistic proof).

---

## 1. Bridge parameters

### 1.1 Initialize parameters

The gas token is configured through `AgglayerBridgeL2.initialize(...)` ([`AgglayerBridgeL2.sol#L296-L392`](https://github.com/agglayer/agglayer-contracts/blob/v12.2.3/contracts/sovereignChains/AgglayerBridgeL2.sol#L296-L392)):

|              Parameter              |                                                 Meaning                                                 |
| :---------------------------------: | :-----------------------------------------------------------------------------------------------------: |
|          `gasTokenAddress`          |                          Origin address of the token the native coin represents                         |
|          `gasTokenNetwork`          | Agglayer network ID where that token originates (`0` = Ethereum L1). It is a network ID, not a chain ID |
|          `gasTokenMetadata`         |          `abi.encode(name, symbol, decimals)` attached to every bridge exit of the native coin          |
|        `sovereignWETHAddress`       |         Optional existing ERC20 to use as WETH. `0x0` makes the bridge deploy its own WETH token        |
| `sovereignWETHAddressIsNotMintable` |    `true` if the WETH token set above is transferred from the bridge balance instead of minted/burnt    |

### 1.2 Token identity

Across the Agglayer, a token is identified by the pair **`(originNetwork, originTokenAddress)`**, never by its local address on a given chain. The same pair is used in bridge exits, in the bridge's wrapped-token mapping and in the local balance tree.

Declaring the gas token means: *"the native coin of this chain is the token `(gasTokenNetwork, gasTokenAddress)`"*. Concretely, the bridge then:

- **Bridging out the native coin**: `bridgeAsset(..., token = 0x0, ...)` with `msg.value == amount` locks the coin in the bridge and emits a leaf with `originNetwork = gasTokenNetwork`, `originTokenAddress = gasTokenAddress` and `metadata = gasTokenMetadata` ([`AgglayerBridge.sol#L307-L316`](https://github.com/agglayer/agglayer-contracts/blob/v12.2.3/contracts/AgglayerBridge.sol#L307-L316)).
- **Claiming the gas token**: a claim whose `(originNetwork, originTokenAddress)` equals `(gasTokenNetwork, gasTokenAddress)` is paid with a native transfer (`call{value: amount}`) **from the bridge contract balance**. If the bridge does not hold enough native coin, the transfer fails and the claim reverts with `EtherTransferFailed` ([`AgglayerBridge.sol#L597-L611`](https://github.com/agglayer/agglayer-contracts/blob/v12.2.3/contracts/AgglayerBridge.sol#L597-L611)).
- **Other networks** see the native coin as a regular foreign token: when they claim it, their bridge deploys a wrapped ERC20 using `gasTokenMetadata` as name, symbol and decimals ([`AgglayerBridge.sol#L612-L667`](https://github.com/agglayer/agglayer-contracts/blob/v12.2.3/contracts/AgglayerBridge.sol#L612-L667)).

### 1.3 Initialization rules

The contract enforces the following ([`AgglayerBridgeL2.sol#L348-L388`](https://github.com/agglayer/agglayer-contracts/blob/v12.2.3/contracts/sovereignChains/AgglayerBridgeL2.sol#L348-L388)):

- **`gasTokenAddress = 0x0`** means the native coin **is L1 ETH**:
    - `gasTokenNetwork` must be `0`, otherwise it reverts with `GasTokenNetworkMustBeZeroOnEther`
    - `sovereignWETHAddress` must be `0x0` and `sovereignWETHAddressIsNotMintable` must be `false`, otherwise it reverts with `InvalidSovereignWETHAddressParams`
    - `gasTokenMetadata` is ignored and no WETH token exists
- **`gasTokenAddress != 0x0`** means the native coin is a token other than ETH:
    - `gasTokenAddress`, `gasTokenNetwork` and `gasTokenMetadata` are stored
    - a **WETH token** is needed to represent L1 ETH on the chain. If `sovereignWETHAddress = 0x0`, the bridge deploys a wrapped token with metadata `("Wrapped Ether", "WETH", 18)`; otherwise the given address is used
    - the WETH token can later be remapped by the bridge manager with `setSovereignWETHAddress`, which is only allowed when `gasTokenAddress != 0x0`
- **The gas token cannot be changed after initialization without a contract upgrade (the bridge is an upgradeable proxy)**: `initialize` is a `reinitializer(3)` that can only be called once by the deployer, and there is no setter for `gasTokenAddress`, `gasTokenNetwork` or `gasTokenMetadata`. Choose the configuration before deploying.

!!! warning
    On chains with a gas token (`gasTokenAddress != 0x0`), `bridgeMessage` must be called with `msg.value = 0` (`NoValueInMessagesOnGasTokenNetworks`). ETH value in messages is sent with `bridgeMessageWETH`, which burns WETH ([`AgglayerBridge.sol#L424-L466`](https://github.com/agglayer/agglayer-contracts/blob/v12.2.3/contracts/AgglayerBridge.sol#L424-L466)).

### 1.4 Local balance tree

The local balance tree tracks, per token, how much of a **foreign** token a network holds: claims increase the balance and bridge exits decrease it. A network cannot bridge out more of a foreign token than it has received. Tokens whose `originNetwork` is the network itself are **not tracked**, so they are never limited. Message leaves (`bridgeMessage` value) also count against the balance of L1 ETH `(0, 0x0)`, so on a chain whose gas token is declared as ETH, `bridgeMessage` with value is limited too.

The GlobalExitRootRemover can overwrite the on-contract balances with `setLocalBalanceTree`, only in emergency state; the pessimistic proof keeps enforcing its own tree.

This rule is enforced twice:

- **On the outpost**, by `AgglayerBridgeL2`: `bridgeAsset` reverts with `LocalBalanceTreeUnderflow` ([`AgglayerBridgeL2.sol#L1251-L1279`](https://github.com/agglayer/agglayer-contracts/blob/v12.2.3/contracts/sovereignChains/AgglayerBridgeL2.sol#L1251-L1279)).
- **In the pessimistic proof**, which fails with `BalanceUnderflowInBridgeExit` ([`local_state/mod.rs#L146-L162`](https://github.com/agglayer/agglayer/blob/v0.6.2/crates/pessimistic-proof-core/src/local_state/mod.rs#L146-L162)).

The gas token is subject to this rule like any other token. This is why the choice between the two options below matters.

---

## 2. Option A: native L2 token (recommended for outposts)

The native coin is declared as a token that **originates on the outpost itself**.

### 2.1 Convention

|     Parameter      |                                  Value                                   |
| :----------------: | :----------------------------------------------------------------------: |
| `gasTokenAddress`  | `rollupID` as 32-bit hex (8 hex characters), repeated 5 times (160 bits) |
| `gasTokenNetwork`  |                                `rollupID`                                |
| `gasTokenMetadata` |         `abi.encode(name, symbol, decimals)` of the native coin          |

The address is a convention: there is no contract at that address. It only has to be unique and stable, so that `(rollupID, derivedAddress)` identifies the native coin across the Agglayer.

**Worked example**: an outpost with `rollupID = 1001` (`0x3e9`):

- `gasTokenNetwork = 1001`
- `gasTokenAddress = 0x000003e9000003e9000003e9000003e9000003e9`
- `gasTokenMetadata = abi.encode(name, symbol, decimals)` of the native coin, e.g. `abi.encode("outpostETH", "OETH", 18)` as in the tool's example parameters

Set `decimals` to the decimals the native coin really has (18 for ETH-like native coins): bridge amounts are passed unchanged, so the decimals only affect how wrapped copies display them.

### 2.2 Bridging flows

Example for an outpost with `rollupID = 1001` and Ethereum L1 (network `0`):

|                Flow               |                       What the user sends                       | Leaf token identity `(originNetwork, originTokenAddress)` |                                     What the user receives                                    |
| :-------------------------------: | :-------------------------------------------------------------: | :-------------------------------------------------------: | :-------------------------------------------------------------------------------------------: |
|         L1 ETH -> outpost         |              ETH on L1 (`bridgeAsset`, token `0x0`)             |                         `(0, 0x0)`                        |                      **WETH** ERC20 on the outpost (minted by the bridge)                     |
|     Outpost native coin -> L1     |      native coin (`bridgeAsset`, token `0x0`, `msg.value`)      |              `(1001, 0x000003e9...000003e9)`              | wrapped native coin ERC20 on L1 (e.g. `wrapped outpostETH`), deployed with `gasTokenMetadata` |
|         Outpost WETH -> L1        |         WETH ERC20 (`bridgeAsset`, token = WETH address)        |                         `(0, 0x0)`                        |                                       **real ETH** on L1                                      |
| L1 wrapped native coin -> outpost | `wrapped outpostETH` ERC20 on L1 (`bridgeAsset`, token address) |              `(1001, 0x000003e9...000003e9)`              |                **native coin** on the outpost, released from the bridge balance               |

On the outpost, `bridgeAsset(token = 0x0)` always moves the **native coin**; WETH is a separate ERC20 and is moved by passing its address. UIs must therefore let users choose between the native coin and WETH on the outpost, and between ETH and the wrapped native coin on L1.

### 2.3 Implications

- **Bridging the native coin out produces a wrapped representation**: on L1 (or any other network) the user receives a wrapped ERC20 of the native coin, e.g. `wrapped outpostETH`, not ETH. This holds even if the native coin is economically "ETH" (Base): for the Agglayer it is a different token.
- **No liquidity pre-funding**: the bridge only pays out native coin that was previously locked in it by `bridgeAsset`. Wrapped copies on other networks can only be minted from exits of the outpost, so the bridge always holds enough native coin to honour them.
- **Not constrained by the local balance tree**: `originNetwork = rollupID` is the outpost itself, so the native coin is never limited by the outpost's local balance tree, neither in the contract nor in the pessimistic proof.
- **L1 ETH arrives as WETH, not as gas**: ETH bridged from L1 is claimed as the WETH ERC20 on the outpost. It cannot be used to pay gas, and bridging WETH back returns real ETH on L1.
- **Users get native coin for gas through the chain's own canonical bridge** (e.g. the Base bridge), not through the Agglayer bridge, unless they bring back native coin that was previously bridged out.
- **The metadata is public-facing**: `gasTokenMetadata` is what wrapped copies on every other network show as name, symbol and decimals.
- **Fixed at initialization**: see [1.3](#13-initialization-rules).

!!! note
    **Tested scope**: the native L2 token convention has been tested on outpost deployments. It has not yet been tested on a chain created with the Agglayer from genesis, where the gas token and native supply are set in the genesis.

---

## 3. Option B: external token

The native coin is declared as the representation of a token that **originates on another network**:

- **L1 ETH**: `gasTokenAddress = 0x0`, `gasTokenNetwork = 0` (`gasTokenMetadata` is ignored)
- **An ERC20**: `gasTokenAddress` = token address **on its origin network**, `gasTokenNetwork` = the origin network ID (`0` for Ethereum L1), `gasTokenMetadata` = the token metadata

### 3.1 Implications

- **The native coin is not actually that token**: declaring Base's native coin as `(0, 0x0)` tells the Agglayer that `baseETH` *is* L1 ETH. It is not: `baseETH` is backed by Base's own canonical bridge, and the Agglayer L1 bridge never received the ETH behind it.
- **The outpost bridge must be pre-funded with native coin**: claims of the gas token are paid from the bridge's native balance (see [1.2](#12-token-identity)). Until the bridge holds native coin, claims of the external token (e.g. L1 ETH bridged to the outpost) revert. The bridge effectively acts as a **liquidity pool**. Note that `AgglayerBridge` has no `receive` or `fallback` function, so the liquidity cannot be added with a plain native transfer; the current outpost tooling does not cover funding the bridge.
- **The local balance tree blocks bridging the native coin out**: every `bridgeAsset(token = 0x0)` decreases the balance of `(gasTokenNetwork, gasTokenAddress)`. Until an equivalent amount of that token has been **claimed into** the outpost, the call reverts with `LocalBalanceTreeUnderflow` (and the pessimistic proof would reject the exit anyway).
- **The L1 side cannot release what it never received**: the L1 bridge only holds the ETH (or ERC20) that was deposited into it. The local balance tree is what prevents the outpost from withdrawing more than it received, which is the failure illustrated in [Intro, 4.1](Intro.md#41-outpost-declaring-its-native-coin-as-l1-eth-external-token).

### 3.2 When it makes sense

An external token is only correct when the chain's native coin **really is backed 1:1 by the origin token through the Agglayer bridge itself**, i.e. the only way to obtain native coin on the chain is to bridge the origin token in through the Agglayer.

This is the model of **chains created with the Agglayer from genesis**:

- The bridge is initialized in the genesis, and the genesis base preallocates the native supply to the bridge proxy (balance `2^128 - 1` in [`genesis-base.json.example`](https://github.com/agglayer/agglayer-contracts/blob/v12.2.3/tools/createSovereignGenesis/genesis-base.json.example)), so the native coin enters circulation only through claims.
- The genesis tooling derives the gas token from an L1 token address: an L1 ERC20 is used as `(0, address)`, while a token that is itself a wrapped token in the L1 bridge is resolved to its origin `(originNetwork, originTokenAddress)`. No address means ETH `(0, 0x0)` ([`create-sovereign-genesis.ts#L200-L229`](https://github.com/agglayer/agglayer-contracts/blob/v12.2.3/tools/createSovereignGenesis/create-sovereign-genesis.ts#L200-L229); same logic for rollups created by the rollup manager in [`PolygonRollupBaseEtrog.sol#L825-L845`](https://github.com/agglayer/agglayer-contracts/blob/v12.2.3/contracts/lib/PolygonRollupBaseEtrog.sol#L825-L845)).

An outpost is an existing chain whose native coin is minted by its own canonical bridge or by its own consensus, so this condition does not hold. **Outposts should use the native L2 token option.**

---

## 4. Common pitfalls

- **The OP stack custom gas token config is not the Agglayer bridge config**: settings of the OP stack native bridge (e.g. `SystemConfig` / `L1Block` `isCustomGasToken`) do not configure the Agglayer bridge. The `AgglayerBridgeL2` gas token is configured only through its own `initialize` parameters.
- **`gasTokenAddress = 0x0` with `gasTokenNetwork = 0` means ETH**, not "no gas token" or "custom token". For example, an OP stack chain configured with a custom gas token at the OP level, but whose Agglayer bridge was initialized with `0x0` / `0` / `0x`, has its native coin treated by the Agglayer as L1 ETH.
- **`gasTokenNetwork` must be the `rollupID` for a native L2 token**: if it differs, the native coin is treated as a foreign token and the local balance tree blocks bridging it out until equivalent amounts are claimed in.
- **`gasTokenNetwork` is an Agglayer network ID**, not an EVM chain ID.
- **Do not confuse the gas token with WETH**: `gasTokenMetadata` describes the outpost's native coin (e.g. `outpostETH`), while WETH is the separate ERC20 that represents L1 ETH on the outpost and is created by the bridge.
- **No changes after initialization**: see [1.3](#13-initialization-rules).

---

## 5. How to configure

The [`deployOutpostChain`](https://github.com/agglayer/agglayer-contracts/blob/develop/tools/deployOutpostChain/README.md) tool always configures the **native L2 token** option ([`deployOutpostChain.ts#L235-L244`](https://github.com/agglayer/agglayer-contracts/blob/v12.2.3/tools/deployOutpostChain/deployOutpostChain.ts#L235-L244), [`#L325-L336`](https://github.com/agglayer/agglayer-contracts/blob/v12.2.3/tools/deployOutpostChain/deployOutpostChain.ts#L325-L336), [`#L421-L434`](https://github.com/agglayer/agglayer-contracts/blob/v12.2.3/tools/deployOutpostChain/deployOutpostChain.ts#L421-L434)):

- `gasTokenAddress` is derived from `network.rollupID` as described in [2.1](#21-convention)
- `gasTokenNetwork` is `network.rollupID`
- `gasTokenMetadata` is `abi.encode(network.tokenName, network.tokenSymbol, network.tokenDecimals)`
- `sovereignWETHAddress = 0x0` and `sovereignWETHAddressIsNotMintable = false`, so the bridge deploys its own WETH token

The relevant part of `deploy_parameters.json`:

```json
"network": {
    "chainID": 1001,
    "rollupID": 1001,
    "networkName": "OutpostChain",
    "tokenName": "outpostETH",
    "tokenSymbol": "OETH",
    "tokenDecimals": 18
}
```

`tokenName`, `tokenSymbol` and `tokenDecimals` describe the outpost's **native coin**, not WETH. The external token option is **not supported** by the tool.

For the operational procedure, see the runbook [Deploy outpost: Setup GasToken](https://github.com/agglayer/runbooks/blob/main/operations/deploy-outpost.md#setup-gastoken).

---

## 6. Decision summary

|               Aspect              |              Native L2 token              |                                External token                                |
| :-------------------------------: | :---------------------------------------: | :--------------------------------------------------------------------------: |
|         `gasTokenAddress`         |        derived from `rollupID` (5x)       |              `0x0` (ETH) or token address on its origin network              |
|         `gasTokenNetwork`         |                 `rollupID`                |                 origin network ID (`0` for ETH / L1 tokens)                  |
|   Native coin on other networks   | wrapped ERC20 (e.g. `wrapped outpostETH`) |                      the origin token itself (e.g. ETH)                      |
|       L1 ETH on the outpost       |                 WETH ERC20                |         native coin (if ETH is the gas token), otherwise WETH ERC20          |
|    Bridge liquidity pre-funding   |                 not needed                |                     required to pay claims of the token                      |
|      Local balance tree limit     |                    none                   |                bridging out limited by the amount claimed in                 |
|            Suitable for           |                  outposts                 | chains whose native coin is created only by Agglayer claims (genesis chains) |
| Supported by `deployOutpostChain` |                    yes                    |                                      no                                      |
