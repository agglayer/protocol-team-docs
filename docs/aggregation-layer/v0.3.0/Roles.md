# Roles
Table with all roles that are new to this release and should be properly assigned

## [AggLayer protocol](SC-specs.md#24-agglayergateway-access-control-roles)
| Contract  |         Role/Address         |
|:---------:|:----------------------------:|
| ALGateway |     `DEFAULT_ADMIN_ROLE`     |
| ALGateway | `AGGCHAIN_DEFAULT_VKEY_ROLE` |
| ALGateway |    `AL_ADD_PP_ROUTE_ROLE`    |
| ALGateway |  `AL_FREEZE_PP_ROUTE_ROLE`   |

### Recommendation
- `DEFAULT_ADMIN_ROLE`: current timelock deployed
- `AGGCHAIN_DEFAULT_VKEY_ROLE`: current multisig, security assumptions for aggchainDefaultVKeyRoleAddress are the same as for updating a rollup which currently is brought by a multisig.
- `AL_ADD_PP_ROUTE_ROLE`: current timelock deployed
- `AL_FREEZE_PP_ROUTE_ROLE`: current multisig

## [Katana - L1 (FEP aggchain)](SC-specs.md#521-roles)
| Contract |         Role          |
|:--------:|:---------------------:|
|   FEP    |      vKeyManager      |
|   FEP    |         admin         |
|   FEP    |   trustedSequencer    |
|   FEP    |    aggchainManager    |
|   FEP    | optimisticModeManager |

### Recommendation
- `vKeyManager`: current timelock deployed (most probably not used since it will rely on default aggchain vKeys provided by the ALGateway)
- `admin`: new Multisig address
- `trustedSequencer`: new EOA address
- `aggchainManager`: new internal multisig
- `optimisticModeManager`: new security council multisig

## [Katana - L2](SC-specs.md#7-roles-sovereignchains-contracts)
|               Contract                |         Role          |
|:-------------------------------------:|:---------------------:|
|        BridgeL2SovereignChain         |     bridgeManager     |
| GlobalExitRootManagerL2SovereignChain | globalExitRootUpdater |
| GlobalExitRootManagerL2SovereignChain | globalExitRootRemover |

- `bridgeManager`: new timelock or multisig
- `globalExitRootUpdater`: EOA (hot wallet `aggOracle` component)
- `globalExitRootRemover`: Multisig (security council)