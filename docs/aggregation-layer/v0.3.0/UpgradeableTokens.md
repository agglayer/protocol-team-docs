# UpgradeableTokens

## 1. Glossary
- `wrappedToken`: ERC20 standard token created by the bridge
- `upgradeableWrappedToken`: TransparentProxy pointing to a ERC20 standard upgradeable implementation

## 2. Rationale
### 2.1 Current scenario
Wrapped tokens are created by the bridge using the create2 opcode and it creates a simple and standard ERC20 token.  
Note that current deployed chains use this approach to create wrappedTokens and wrapped tokens have the same addresses in all chains deployed.  
This approach does not imply any security assumption beyond the address that is able to upgrade the bridge (normally a timelock).  

### 2.2 Current issue
On SovereignChains, a new approach to allow more features on the wrapped Tokens has been implemented: [custom mappings](https://github.com/agglayer/agg-contracts-internal/blob/feature/ongoing-v0.3.0/contracts/v2/sovereignChains/BridgeL2SovereignChain.sol#L330). This feature currently works given the featured wanted: extend the wrappedToken features.

This feature is purely [managed by the `bridgeManager`](https://github.com/agglayer/agg-contracts-internal/blob/feature/ongoing-v0.3.0/contracts/v2/sovereignChains/BridgeL2SovereignChain.sol#L335) meaning that this feature is chain-centric (instead of asset-centric). Asset-centric means that the owner of the asset could deploy its own wrappedToken (or similarly, deploy an upgradeable wrappedToken and give the ownership to an address controlled by the asset).
An asset-centric feature could not be applied on top of the `custom mappings` implementation. Therefore a new approach needs to be specified in order to allow future version to be asset-centric.

Besides, this approach implies another risky concern about users being able to stop the PP of the chain if LBT reaches a negative balance (this assumption purely depends on the approach on how to use the customMappings. Example: Katana). The implementation of the LBT at SC level provides guarantees that the PP will not be blocked, but just the user claim. NOTE that this affects `customMappings` and `upgradeableWrappedTokens`.

### 2.3 Solving the issue
Deploy transparent proxy which has a ERC20 upgradeable implementation

- `proxiedTokensManager` is the owner of the proxy admin of the proxy
- `proxiedTokensManager` can delegate ownership to any address later on
- `proxiedTokensManager` is set at initialization of sovereign bridge from initialization inputs. In case of L1, bridgeV2, `proxiedTokensManager` is set from the proxy owner of the proxy admin of the bridge itself. The role can be transferred with a two steps procedure.

Security assumptions:

  - `SovereignBridge` is a proxy controlled by a certain address. Managing the tokens from the same address has the same security assumptions.
  - LBT implementation avoids chain DoS on the PP, more specifically on the LBT with negative value given that an asset could `mint` tokens as its wish
  - mainnet bridge to produce the same addresses once it is upgraded

Custom mappings:

  - keep functionality on SovereignBridges
  - theoretically, functionality will not be used and therefore removed in future versions

> :warning:
> :bulb: Already deployed SovereignBridges can have an extra functionality which is deploying the new `upgradeableWrappedTokens`. Then, a customMapping could be done to override the `wrappedToken` address. CustomMappings provides the ability to migrate tokens if used correctly.

>If the `upgradeableWrappedTokens` mints outside the bridge could potentially unbalance the liquidity and/or steal user's assets

## 3. Requirements
- Deterministic addresses on all chains
- Mainnet bridge and SovereignBridges to deploy new `upgradeableWrappedTokens`
- `upgradeableWrappedTokens` pointing to a ERC20 standard upgradeable implementation
- `upgradeableWrappedTokens` to set `bridgeManager` as its initial owner
- keep `customMappings` feature

## 4. Cases
### 4.1 New SovereignBridges deployed
All the tokens created by the `SovereignBridge` will have the new addresses and will be upgradeable ERC20 tokens.
Mainnet bridge will also produce the same addresses once the bridge is upgraded.

> :warning:
> Previous tokens deployed by the bridge will still have the old addresses and will not be upgraded. therefore, old address will have all the token liquidity. There will not be liquidity fragmentation.

>:bulb: A mechanism to upgrade previous tokens has been introduced `deployWrappedTokenAndRemap`.Function to deploy an upgradeable wrapped token without having to claim asset. It is used to upgrade legacy tokens to the new upgradeable token. After deploying the token it is remapped to be the new functional wtoken. This function can only be called once for each originNetwork/originTokenAddress pair because it deploys a deterministic contract with create2

All tokens created by the bridge will effectively not have the same address as previous `wrappedToken` versions.

### 4.2 Previous bridges deployed
Bridges will be upgraded to start using `upgradeableWrappedTokens`.  
All previous tokens deployed on those bridges will have the same address as before and same address will be used.  
New tokens will have the new address produced by the `upgradeableWrappedToken`.  

### 4.3 Chains with no PP (zkEVM / Validium / Mainnet)
Chains with NO PP proofs cannot use this feature since all bridge assets can be stolen, not just the chain's ones.
Mainnet could be a special case where the owner of the `upgradeableWrappedTokens` is the `securityCouncil`

> `securityCouncil` is the same address that could potentially halt the bridge and `zkEVMMultisig` to perform an upgrade with delay 0 afterwards

> therefore, seems more rational to setup the timelock as the owner of all `upgradeableWrappedTokens`

> Timelock is not accessible from the Bridge. Therefore, adding a role `bridgeManager` and initialize it with the timelock fits better. Later on, bridgeManager can be initialized as the securityCouncil address or the timelock.

## 5. Specs
### 5.1 Deterministic address specification
In order to get a deterministic address when deploying a ERC20 upgradeable token we need to make the `create2` parameters to be only dependant on the token information. The rest of the parameters must be equal across all the chains.  
The common data shared among all the bridges deployed is its address.

### 5.2 Previous knowledge
`create2` formula to generate addresses:
```
address = keccak256(0xFF ++ deployer ++ salt ++ keccak256(init_code))[12:]
```
[ProxyTransparentProxy constructor parameters](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/transparent/TransparentUpgradeableProxy.sol#L79):
- `_logic`: implementation address
- `initialOwner`: owner of the proxy
- `_data`:  typically to initialize storage proxy

### 5.3 Create2 params TransparentProxy
#### 5.3.1 deployer
The deployer will be always the bridge address when the proxy is deployed

#### 5.3.2 salt
The [TokenInfoHash](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v10.0.0-rc.6/contracts/v2/PolygonZkEVMBridgeV2.sol#L554) will be set as a `salt` since it is the unique identifier of a given token.
> Note that in previous bridge versions, not only the `TokenInfoHash` changed the address deployed but also the [token metadata since it was appended to the initBytecode](https://github.com/0xPolygonHermez/zkevm-contracts/blob/v10.0.0-rc.6/contracts/v2/PolygonZkEVMBridgeV2.sol#L1171) to be able to setup the constructor.

#### 5.3.4 init_code
initBytecode `proxyInitBytecode # constructorArgs`:
```
/// @dev A bytecode stored on chain is used to deploy the proxy in a way that ALWAYS it's used the same
/// bytecode, therefore the proxy addresses are the same in all chains as they are deployed deterministically with same init bytecode
/// @dev there is no constructor args as the implementation address + owner of the proxied are set at constructor level and taken from the bridge itself
bytes memory proxyInitBytecode = abi.encodePacked(
    INIT_BYTECODE_TRANSPARENT_PROXY()
);
```
Here it is the most tricky part since as mentioned before, the constructor arguments of the proxy are the following:

- `_logic`: implementation address
- `initialOwner`: owner of the proxy
- `_data`:  typically to initialize storage proxy
Therefore, all above parameters must be the same in all chains in order to get the same address.

### 5.4 Implementation
- When deploying the new bridge implementation
    - deploy proxy init bytecode and store it on an immutable address
    - deploy erc20 upgradeable implementation and store it on an immutable address
- When deploying a new upgradeableWrappedToken
    - Deploy TokenWrappedTransparentProxy with create2
        - The constructor has been modified to get the params from the msg.sender (the bridge). This way, we are not sending constructor args and the init code it's no dependant on constructor and the address is determined byt the bytecode.
```
   constructor()
        payable
        ERC1967Proxy(
            IPolygonZkEVMBridgeV2(msg.sender)
                .getWrappedTokenBridgeImplementation(),
            new bytes(0)
        )
    {
        // Get bridge interface to retrieve proxied tokens manager role
        _changeAdmin(
            IPolygonZkEVMBridgeV2(msg.sender).getProxiedTokensManager()
        );
    }
```
    - attach `initBytecodeProxy` with params
```
// 'proxyBytecodeStorer' is the address that contains the initBytecode
bytes memory initBytecode = abi.encodePacked(
    IProxyInitCode(wrappedTokenBytecodeStorer).PROXY_INIT_BYTECODE();,
    constructorArgsProxy
);
```
    - create2 opcode
```
/// @solidity memory-safe-assembly
assembly {
    newWrappedTokenProxy := create2(
        0,
        add(initBytecode, 0x20),
        mload(initBytecode),
        tokenInfoHash
    )
}
```
    - initialize proxy contract
```
newWrappedTokenProxy.initialize(name, symbol, decimals);
```

![](../UpgradeableTokens.png)