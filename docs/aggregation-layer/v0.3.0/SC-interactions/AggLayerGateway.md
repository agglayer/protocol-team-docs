# AggLayer Gateway SC

## 1. Interactions & Usage

The definition can be found [here](../SC-specs.md#2-agglayer-gateway-specifications).

### 1.1. addPessimisticVKeyRoute

Function to add a pessimistic verification key route.

Parameters:
```
@param pessimisticVKeySelector The 4 bytes selector to add to the pessimistic verification keys.
@param verifier The address of the verifier contract.
@param pessimisticVKey New pessimistic program verification key
```

Events:
```
@param selector The verifier selector that was added.
@param verifier The address of the verifier contract.
@param pessimisticVKey The verification key

event RouteAdded(
    bytes4 selector,
    address verifier,
    bytes32 pessimisticVKey
)
```

Errors:

- Thrown when adding a verifier route and the selector returned by the verifier is zero:
```
error PPSelectorCannotBeZero();
```
- Thrown when adding a verifier route and the selector already contains a route:
```
@param selector The pessimistic verification key selector that was specified.
@param verifier The address of the verifier contract in the existing route.

error RouteAlreadyExists(bytes4 selector, address verifier);
```

### 1.2. freezePessimisticVKeyRoute

Function to freeze a pessimistic verification key route.

Parameters:
```
@param pessimisticVKeySelector The 4 bytes selector to freeze the pessimistic verification key route
```

Events:
```
@param selector The verifier selector that was added.
@param verifier The address of the verifier contract.
@param pessimisticVKey The verification key

event RouteFrozen(
    bytes4 selector,
    address verifier,
    bytes32 pessimisticVKey
);
```

Errors:

- Thrown when the verifier route is not found:
```
@param selector The verifier selector that was specified

error RouteNotFound(bytes4 selector);
```

- Thrown when trying to freeze a route that is already frozen:
```
@param selector The pessimistic verification key selector that was specified

error RouteIsAlreadyFrozen(bytes4 selector);
```

### 1.3. addDefaultAggchainVKey

Function to add an aggchain verification key.

Parameters:
```
@param defaultAggchainSelector The 4 bytes selector to add to the default aggchain verification keys.
@dev First 2 bytes of the selector  are the 'verification key identifier', the last 2 bytes are the aggchain type (ex: FEP, ECDSA)
@param defaultAggchainVKey New default aggchain verification key to be added
```

Events:
```
@param selector The 4 bytes selector of the added default aggchain verification key.
@param newVKey New aggchain verification key to be added

event AddDefaultAggchainVKey(bytes4 selector, bytes32 newVKey);
```

Errors:

- Thrown when trying to add an aggchain verification key that already exists:
```
error AggchainVKeyAlreadyExists();
```
- Thrown when adding a verifier key with value zero:
```
error VKeyCannotBeZero();
```

### 1.4. updateDefaultAggchainVKey

Function to update a default aggchain verification key from the mapping.

Parameters:
```
@param defaultAggchainSelector The 4 bytes selector to update the default aggchain verification keys.
@param newDefaultAggchainVKey Updated default aggchain verification key value
```

Events:
```
@param selector The 4 bytes selector of the updated default aggchain verification key.
@param previousVKey Aggchain verification key previous value
@param newVKey Aggchain verification key updated value

event UpdateDefaultAggchainVKey(
    bytes4 selector,
    bytes32 previousVKey,
    bytes32 newVKey
);
```

Errors:

- Thrown when trying to retrieve an aggchain verification key from the mapping that doesn't exists:
```
error AggchainVKeyNotFound();
```
- Thrown when new defaultAggchainVKey is zero:
```
error VKeyCannotBeZero();
```

### 1.5. unsetDefaultAggchainVKey

Function to unset a default aggchain verification key from the mapping.

Parameters:
```
@param defaultAggchainSelector The 4 bytes selector to update the default aggchain verification keys
```

Events:
```
@param selector The 4 bytes selector of the updated default aggchain verification key

event UnsetDefaultAggchainVKey(
    bytes4 selector
);
```

Errors:

- Thrown when trying to retrieve an aggchain verification key from the mapping that doesn't exists:
```
error AggchainVKeyNotFound();
```


### 1.6. getDefaultAggchainVKey

Function to retrieve the default aggchain verification key.

Parameters:
```
@param defaultAggchainSelector The default aggchain selector for the verification key.
@dev First 2 bytes are the aggchain type, the last 2 bytes are the 'verification key identifier'.
```

Errors:

- Thrown when trying to retrieve an aggchain verification key from the mapping that doesn't exists:
```
error AggchainVKeyNotFound();
```

### 1.7. verifyPessimisticProof
Function to verify the pessimistic proof.

Parameters:
```
@param publicValues Public values of the proof.
@param proofBytes Proof for the pessimistic verification.
@dev First 4 bytes of the pessimistic proof are the pp selector.
 proof[0:4]: 4 bytes selector pp
 proof[4:8]: 4 bytes selector SP1 verifier
 proof[8:]: proof
```

Errors:

- Thrown when the verifier route is not found:
```
@param selector The verifier selector that was specified

error RouteNotFound(ppSelector)
```

- Thrown when the verifier route is found, but is frozen:
```
@param selector The verifier selector that was specified

error RouteIsFrozen(ppSelector)
```


## 2. Tooling available

### 2.1. deployment AggLayerGateway

[Tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/deployAggLayerGateway) to deploy `AggLayerGateway` contract.

### 2.2. Add default aggchain vkey

[Tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/aggLayerGatewayTools/addDefaultAggchainVKey) to add default aggchain vkey.

### 2.3. Update default aggchain vkey

[Tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/aggLayerGatewayTools/updateDefaultAggchainVKey) to update default aggchain vkey.

### 2.4. Unset default aggchain vkey

[Tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/aggLayerGatewayTools/unsetDefaultAggchainVKey) to unset default aggchain vkey.

### 2.5. Add pessimistic vkey route

[Tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/aggLayerGatewayTools/addPessimisticVKeyRoute) to add pessimitic vkey route.

### 2.6. Freeze pessimistic vkey route

[Tool](https://github.com/agglayer/agglayer-contracts/tree/v11.0.0/tools/aggLayerGatewayTools/freezePessimisticVKeyRoute) to freeze pessimistic vkey route.
