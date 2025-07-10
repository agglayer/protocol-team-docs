## BridgeL2SovereignChain Smart Contract Documentation
[Link SC](https://github.com/0xPolygonHermez/zkevm-contracts/blob/feature/audit-remediations/contracts/v2/sovereignChains/BridgeL2SovereignChain.sol)
> Warning: This contract has not been audited. Use at your own risk.

### Introduction

The BridgeL2SovereignChain smart contract is designed to be deployed on Ethereum and Sovereign chains. It extends the PolygonZkEVMBridgeV2 and implements the IBridgeL2SovereignChains interface. The contract manages token interactions across different networks, including token wrapping, remapping, and migration of legacy tokens.

### Table of Contents

* Overview
* State Variables
* Events
* Constructor
* Modifiers
* Functions
    * initialize
    * setBridgeManager
    * setMultipleSovereignTokenAddress
    * setSovereignTokenAddress
    * removeLegacySovereignTokenAddress
    * setSovereignWETHAddress
    * migrateLegacyToken
    * _bridgeWrappedAsset
    * _claimWrappedAsset
    * activateEmergencyState
    * deactivateEmergencyState
* Errors
* Usage Notes
* Overview
* Deployment

The BridgeL2SovereignChain contract acts as a bridge for token interactions between Ethereum and Sovereign chains. It handles:

Managing token wrapping and unwrapping.
Remapping tokens to new sovereign addresses.
Migrating legacy tokens to updated tokens.
Setting custom mappings for tokens and WETH addresses.
State Variables

1. **wrappedAddressIsNotMintable**
```
mapping(address wrappedAddress => bool isNotMintable) public wrappedAddressIsNotMintable;
```
* **Description**: Maps wrapped token addresses to a boolean indicating whether they are not mintable.
* **Usage**: Determines if a wrapped token should be transferred instead of minted/burned.
 
2. bridgeManager
```
address public bridgeManager;
```
**Description**: The address of the bridge manager who can set custom mappings for any token.
**Usage**: Functions restricted to the bridge manager use this address for access control.

---

### Events

1. **SetBridgeManager**
```
event SetBridgeManager(address bridgeManager);
```
**Description**: Emitted when the bridge manager is updated.

2. **SetSovereignTokenAddress**
```
event SetSovereignTokenAddress( uint32 originNetwork, address originTokenAddress, address sovereignTokenAddress, bool isNotMintable );
```
**Description**: Emitted when a token address is remapped to a sovereign token address.

3. **MigrateLegacyToken**
```
event MigrateLegacyToken( address sender, address legacyTokenAddress, address updatedTokenAddress, uint256 amount );
```
**Description**: Emitted when a legacy token is migrated to a new token.

4. **RemoveLegacySovereignTokenAddress**
```
event RemoveLegacySovereignTokenAddress(address sovereignTokenAddress);
```
**Description**: Emitted when a remapped token is removed from the mapping.

5. **SetSovereignWETHAddress**
```
event SetSovereignWETHAddress( address sovereignWETHTokenAddress, bool isNotMintable );
```
**Description**: Emitted when a WETH address is remapped to a sovereign WETH address.

---
### Constructor
```
constructor() { _disableInitializers(); }
```
**Description**: Disables initializers on the implementation contract following best practices.
Note: Ensures that the contract cannot be initialized improperly.

### Modifiers

1. **onlyBridgeManager**
```
modifier onlyBridgeManager() { if (bridgeManager != msg.sender) { revert OnlyBridgeManager(); } _; }
```
**Description**: Restricts function access to the bridge manager.
**Usage**: Applied to functions that should only be callable by the bridge manager.

### Functions

#### 1. **initialize**
```
function initialize( uint32 _networkID, address _gasTokenAddress, uint32 _gasTokenNetwork, IBasePolygonZkEVMGlobalExitRoot _globalExitRootManager, address _polygonRollupManager, bytes memory _gasTokenMetadata, address _bridgeManager, address _sovereignWETHAddress, bool _sovereignWETHAddressIsNotMintable ) public virtual initializer
```
**Parameters**:  

* _networkID: The network ID.  
* _gasTokenAddress: The address of the gas token.  
* _gasTokenNetwork: The network ID of the gas token.  
* _globalExitRootManager: The global exit root manager address.  
* _polygonRollupManager: The rollup manager address (set to address(0) on L2).  
* _gasTokenMetadata: ABI-encoded metadata for the gas token.  
* _bridgeManager: The bridge manager address.  
* _sovereignWETHAddress: The sovereign WETH token address.  
* _sovereignWETHAddressIsNotMintable: Indicates if the WETH token is not mintable.  

**Description**: Initializes the contract with the provided parameters. It sets up the gas token, WETH token, and bridge manager. If the gas token is Ether (i.e., _gasTokenAddress is address(0)), it performs specific checks and setups.

**Behavior**:

* Sets the network ID, global exit root manager, and bridge manager.  
* Initializes the gas token:  
* If Ether, ensures _gasTokenNetwork is zero and no WETH address is provided.  
* If ERC20, sets up the gas token address, network, and metadata.  
* Sets up the WETH token:  
* If no _sovereignWETHAddress is provided, deploys a new wrapped token.  
* If provided, uses the given WETH address and sets its mintability.  
* Initializes OpenZeppelin contracts, such as ReentrancyGuard.  

**Notes**:

* This function overrides the initializer from PolygonZkEVMBridgeV2.
* If the gas token is Ether, WETH remapping is not supported.  

#### 2. **setBridgeManager**

```
function setBridgeManager(address _bridgeManager) external onlyBridgeManager
```

**Parameters**:

* _bridgeManager: The new bridge manager address.  

**Description**: Updates the bridge manager to a new address.

**Behavior**:

* Validates that the new address is not zero.
* Updates the bridgeManager state variable.
* Emits the SetBridgeManager event.

#### 3. **setMultipleSovereignTokenAddress**
```
function setMultipleSovereignTokenAddress( uint32[] memory originNetworks, address[] memory originTokenAddresses, address[] memory sovereignTokenAddresses, bool[] memory isNotMintable ) external onlyBridgeManager
```
**Parameters**:

* originNetworks: Array of origin network IDs.
* originTokenAddresses: Array of origin token addresses.
* sovereignTokenAddresses: Array of new sovereign token addresses.
* isNotMintable: Array of booleans indicating if each token is not mintable.

**Description**: Remaps multiple wrapped tokens to new sovereign token addresses in a batch operation.

**Behavior**:

* Ensures all input arrays have the same length.
* Iterates over the arrays and calls _setSovereignTokenAddress for each token.

#### 4. **setSovereignTokenAddress**
```
function setSovereignTokenAddress( uint32 originNetwork, address originTokenAddress, address sovereignTokenAddress, bool isNotMintable ) external onlyBridgeManager
```
**Parameters**:

* originNetwork: The origin network ID.
* originTokenAddress: The origin token address (cannot be zero).
* sovereignTokenAddress: The new sovereign token address (cannot be zero).
* isNotMintable: Indicates if the token is not mintable.

**Description**: Remaps a wrapped token to a new sovereign token address.  
**Behavior**: Calls _setSovereignTokenAddress internally with the provided parameters.

#### 5. **_setSovereignTokenAddress**
```
function _setSovereignTokenAddress( uint32 originNetwork, address originTokenAddress, address sovereignTokenAddress, bool isNotMintable ) internal
```
**Parameters**: Same as setSovereignTokenAddress.  
**Description**: Internal function that performs the actual remapping of a wrapped token to a new sovereign token address.  
**Behavior**:  

* Validates that neither originTokenAddress nor sovereignTokenAddress is zero.
* Ensures that originNetwork is not the current network ID.
* Checks that the token is not already mapped.
* Updates the mappings:
    * tokenInfoToWrappedToken with the new sovereign token address.
    * wrappedTokenToTokenInfo with the token information.
    * wrappedAddressIsNotMintable with the mintability status.
* Emits the SetSovereignTokenAddress event.

#### 6. **removeLegacySovereignTokenAddress**
```
function removeLegacySovereignTokenAddress( address sovereignTokenAddress ) external onlyBridgeManager
```
**Parameters**:

* sovereignTokenAddress: The sovereign token address to remove from mapping.

**Description**: Removes a remapped token from the mappings, effectively stopping support for the legacy sovereign token.
**Behavior**:

* Checks that the token was previously remapped.
* Deletes the token from wrappedTokenToTokenInfo and wrappedAddressIsNotMintable.
* Emits the RemoveLegacySovereignTokenAddress event.

#### 7. **setSovereignWETHAddress**
```
function setSovereignWETHAddress( address sovereignWETHTokenAddress, bool isNotMintable ) external onlyBridgeManager
```
**Parameters**:

* sovereignWETHTokenAddress: The new sovereign WETH token address.
* isNotMintable: Indicates if the WETH token is not mintable.

**Description**: Remaps the WETH token to a new sovereign WETH address.
**Behavior**:

* Validates that the gas token is not Ether (WETH remapping is not supported on Ether networks).
* Updates the WETHToken variable with the new address.
* Updates wrappedAddressIsNotMintable with the mintability status.
* Emits the SetSovereignWETHAddress event.

#### 8. **migrateLegacyToken**
```
function migrateLegacyToken( address legacyTokenAddress, uint256 amount ) external
```
**Parameters**:

* legacyTokenAddress: The address of the legacy token to migrate.
* amount: The amount of tokens to migrate.

**Description**: Migrates old native or remapped tokens to the new mapped tokens. If the token is mintable, it will be burned and minted; otherwise, it will be transferred.
**Behavior**:

* Retrieves the token information for the legacy token.
* Ensures that the token is mapped.
* Retrieves the current token address from tokenInfoToWrappedToken.
* Checks that the legacy token is different from the current token.
* Calls _bridgeWrappedAsset to burn or transfer the legacy tokens from the sender.
* Calls _claimWrappedAsset to mint or transfer the new tokens to the sender.
* Emits the MigrateLegacyToken event.

#### 9. **_bridgeWrappedAsset**
```
function _bridgeWrappedAsset( TokenWrapped tokenWrapped, uint256 amount ) internal override
```
**Parameters**:

* tokenWrapped: The wrapped token to burn or transfer.
* amount: The amount of tokens.

**Description**: Burns tokens from the wrapped token to execute the bridge. If the token is not mintable, it transfers the tokens instead.
**Behavior**:

* Checks wrappedAddressIsNotMintable for the token address.
* If not mintable, transfers the tokens from the sender to the contract.
* If mintable, burns the tokens from the sender.

#### 10. **_claimWrappedAsset**
```
function _claimWrappedAsset( TokenWrapped tokenWrapped, address destinationAddress, uint256 amount ) internal override
```
**Parameters**:

* tokenWrapped: The wrapped token to mint or transfer.
* destinationAddress: The address to receive the tokens.
* amount: The amount of tokens.

**Description**: Mints tokens from the wrapped token to proceed with the claim. If the token is not mintable, it transfers the tokens instead.  

**Behavior**:

* Checks wrappedAddressIsNotMintable for the token address.
* If not mintable, transfers the tokens to the destinationAddress.
* If mintable, mints the tokens to the destinationAddress.

#### 11. **activateEmergencyState**
```
function activateEmergencyState() external override(IPolygonZkEVMBridgeV2, PolygonZkEVMBridgeV2)
```
**Description**: Overrides the function to prevent activation of the emergency state. Reverts when called.  
**Behavior**: Always reverts with NotValidBridgeManager().

#### 12. **deactivateEmergencyState**
```
function deactivateEmergencyState() external override(IPolygonZkEVMBridgeV2, PolygonZkEVMBridgeV2)
```
**Description**: Overrides the function to prevent deactivation of the emergency state. Reverts when called.  
**Behavior**: Always reverts with NotValidBridgeManager().

### Errors

* **OnlyBridgeManager**(): Thrown when a function is called by an address that is not the bridge manager.
* **NotValidBridgeManager**(): Thrown when the bridge manager address is invalid (e.g., zero address).
* **InvalidZeroAddress**(): Thrown when a zero address is provided where it is not allowed.
* **OriginNetworkInvalid**(): Thrown when the origin network ID is the same as the current network ID.
* **TokenAlreadyMapped**(): Thrown when attempting to map a token that is already mapped.
* **TokenNotRemapped**(): Thrown when attempting to remove a token that was not remapped.
* **InputArraysLengthMismatch**(): Thrown when input arrays in a function have mismatched lengths.
* **TokenNotMapped**(): Thrown when attempting to migrate a token that is not mapped.
* **TokenAlreadyUpdated**(): Thrown when the token to migrate is already updated.
* **InvalidInitializeFunction**(): Thrown when an invalid initialize function is called.
* **GasTokenNetworkMustBeZeroOnEther**(): Thrown when the gas token network is not zero while the gas token is Ether.
* **InvalidSovereignWETHAddressParams**(): Thrown when invalid parameters are provided for the sovereign WETH address.
* **WETHRemappingNotSupportedOnGasTokenNetworks**(): Thrown when attempting to remap WETH on networks where the gas token is Ether.

### Usage Notes

* **Bridge Manager**: Only the bridge manager can call functions that change the state mappings or manager address.
* **Token Remapping**: When remapping tokens, ensure that the origin network ID is different from the current network ID and that the token addresses are valid.
* **Mintability**: The isNotMintable flag indicates whether tokens should be transferred instead of minted/burned. This is important for tokens that do not support minting or burning.
* **Legacy Token Migration**: Users can migrate legacy tokens to new tokens if they have been remapped by the bridge manager.
* **Emergency State**: Activation and deactivation of the emergency state are intentionally disabled in this contract.

> Disclaimer: This documentation is provided for informational purposes only and may not cover all aspects of the contract. Always review the contract code thoroughly before interacting with it.

### Docker build

- Set params at `create_rollup_parameters_docker.json`

```
"isVanillaClient": false, // If true, sovereignParams are mandatory
    "sovereignParams": {
        "bridgeManager": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266", // Address pf the bridge manager
        "sovereignWETHAddress": "0x0000000000000000000000000000000000000000", // Address of the sovereign WETH address, zero if not applies
        "sovereignWETHAddressIsNotMintable": false, // is sovereign WETH address mintable? False if not applies
        "globalExitRootUpdater": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" // Address of the global Exit root admin
    }
```

- `npm run dockerv2:contracts`

