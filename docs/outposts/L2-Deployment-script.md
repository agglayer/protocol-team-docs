# L2 Deployment script

## 1. Deploy Outpost Chain Script

!!! info
    The tooling specifications and code can be found [here](https://github.com/agglayer/agglayer-contracts/blob/v12.2.3/tools/deployOutpostChain/README.md)

## 1.1 Overview

The **deployOutpostChain** script is an automated deployment solution designed to facilitate the establishment of sovereign blockchain networks within the Agglayer ecosystem. This tool provides a streamlined approach to deploying all necessary smart contracts required for an outpost chain implementation.

## 1.2 Primary Objective

The script serves as a comprehensive deployment framework for creating sovereign blockchain networks with integrated cross-chain bridging capabilities. It enables the deployment of blockchain infrastructure that supports:

- **Cross-chain asset transfers** and token bridging functionality
- **Global exit root management** for secure cross-chain transaction finalization
- **Decentralized governance mechanisms** through timelock controllers
- **Optional oracle committee integration** for enhanced security and decentralization

## 1.3 Core Contract Deployments

The deployment process encompasses five primary smart contracts:

### 1.3.1 TimelockController
- **Purpose**: Implements governance timelock mechanisms for secure contract upgrades
- **Function**: Provides time-delayed execution of administrative operations

### 1.3.2 ProxyAdmin
- **Purpose**: Manages proxy contract upgrade processes
- **Function**: Controls the upgrade lifecycle of proxied contracts

### 1.3.3 BridgeL2SovereignChain
- **Purpose**: Facilitates cross-chain asset transfers
- **Function**: Handles token deposits, withdrawals, and cross-chain communication

### 1.3.4 GlobalExitRootManagerL2SovereignChain
- **Purpose**: Manages the global exit root merkle tree
- **Function**: Maintains cryptographic proofs for cross-chain transaction validation

### 1.3.5 AggOracleCommittee *(Optional)*
- **Purpose**: Provides decentralized oracle functionality
- **Function**: Enables committee-based validation of cross-chain data through consensus mechanisms

### 1.3.6 Additional Infrastructure Components

The deployment includes several auxiliary contracts:

- **WrappedTokenBytecodeStorer**: Optimizes contract size by storing token bytecode externally
- **WrappedTokenBridgeImplementation**: Serves as template for wrapped token deployments
- **BridgeLib**: Contains shared bridge functionality to reduce contract complexity
- **WETH Token**: Chain-specific wrapped Ether, deployed by the bridge during `initialize` to represent L1 ETH on the outpost (separate from the native gas token)

## 1.4 Key Architectural Features

### 1.4.1 Automated Configuration Management
- **Address Pre-calculation**: Utilizes deterministic address generation for circular dependency resolution
- **Parameter Derivation**: Automatically calculates the gas token parameters from the `rollupID`. The gas token is **always configured as a native L2 token**: `gasTokenAddress` is the `rollupID` (32-bit hex) repeated 5 times, `gasTokenNetwork` is the `rollupID` (not the chain ID), and `gasTokenMetadata` is `abi.encode(tokenName, tokenSymbol, tokenDecimals)` of the outpost native coin. Configuring an external token is not supported by the script. See [5.3 Gas token configuration](Gas-token.md)
- **Governance Integration**: Establishes proper ownership hierarchies and access controls

### 1.4.2 Security Mechanisms
- **Proxy Pattern Implementation**: Enables secure contract upgrades through established patterns
- **Timelock Governance**: Enforces delayed execution for critical administrative functions
- **Multi-signature Oracle Support**: Provides optional decentralized validation through committee consensus

### 1.4.3 Deployment Flexibility
- **Configurable Oracle Systems**: Supports both single-oracle and committee-based configurations
- **Standardized Deployment Process**: Utilizes OpenZeppelin's established upgrade patterns
- **Comprehensive Validation**: Includes automated verification of deployment integrity

!!! info
    The tooling specifications and code can be found [here](https://github.com/agglayer/agglayer-contracts/blob/v12.2.3/tools/deployOutpostChain/README.md)