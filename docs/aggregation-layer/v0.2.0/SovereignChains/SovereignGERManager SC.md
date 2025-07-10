### GlobalExitRootManagerL2SovereignChain Smart Contract Documentation
[Link SC](https://github.com/0xPolygonHermez/zkevm-contracts/blob/feature/audit-remediations/contracts/v2/sovereignChains/GlobalExitRootManagerL2SovereignChain.sol)
> Warning: This contract has not been audited. Use at your own risk.

### Introduction

The GlobalExitRootManagerL2SovereignChain smart contract is designed to manage exit roots for Sovereign chains and global exit roots.
It extends the PolygonZkEVMGlobalExitRootL2 contract and implements the Initializable interface from OpenZeppelin. The contract allows authorized parties to insert and remove global exit roots, maintaining a mapping of these roots with an insertion order.

### Table of Contents

* Overview
* State Variables
* Events
* Constructor
* Modifiers
* Functions
    * initialize
    * insertGlobalExitRoot
    * removeLastGlobalExitRoots
* Errors
* Usage Notes
* Disclaimer
* Overview

The GlobalExitRootManagerL2SovereignChain contract serves as a manager for global exit roots in the context of Sovereign chains. It allows a designated globalExitRootUpdater to insert new global exit roots and remove the last inserted ones. This contract ensures the integrity and order of global exit roots, which are crucial for cross-chain interactions and validations.

### State Variables

### globalExitRootUpdater
```
address public globalExitRootUpdater;
```
**Description**: The address authorized to insert and remove global exit roots. If set to the zero address, the block.coinbase address is used as the updater.
**Usage**: Functions restricted to the global exit root updater use this address for access control.

### insertedGERCount
```
uint256 public insertedGERCount;
```
**Description**: A counter tracking the total number of inserted global exit roots.
**Usage**: Helps maintain the insertion order of global exit roots and ensures correct removal of the last inserted roots.

### Events

1. **InsertGlobalExitRoot**
```
event InsertGlobalExitRoot(bytes32 indexed newGlobalExitRoot);
```
**Description**: Emitted when a new global exit root is inserted.
**Parameters**:
* newGlobalExitRoot: The hash of the newly inserted global exit root.

2. **RemoveLastGlobalExitRoot**
```
event RemoveLastGlobalExitRoot(bytes32 indexed removedGlobalExitRoot);
```
**Description**: Emitted when the last inserted global exit root is removed.
**Parameters**:
* removedGlobalExitRoot: The hash of the removed global exit root.
---
### Constructor
```
constructor(address _bridgeAddress) PolygonZkEVMGlobalExitRootL2(_bridgeAddress) { _disableInitializers(); }
```
**Parameters**:
* _bridgeAddress: The address of the PolygonZkEVMBridge contract.

**Description**: Initializes the contract by calling the parent constructor with the provided bridge address and disables further initializations.
**Note**: Ensures that the contract cannot be improperly initialized again.

### Modifiers

1. **onlyGlobalExitRootUpdater**
```
modifier onlyGlobalExitRootUpdater() {
    if (globalExitRootUpdater == address(0)) {
        if (block.coinbase != msg.sender) {
            revert OnlyGlobalExitRootUpdater();
        }
    } else {
        if (globalExitRootUpdater != msg.sender) {
            revert OnlyGlobalExitRootUpdater();
        }
    }
    _;
}
```
**Description**: Restricts function access to the globalExitRootUpdater.
**Behavior**:
* If globalExitRootUpdater is set to the zero address (address(0)), only the block.coinbase address can call the function.
* Otherwise, only the address stored in globalExitRootUpdater can call the function.

**Usage**: Applied to functions that should only be callable by the global exit root updater.

### Functions

1. **initialize**
```
function initialize(address _globalExitRootUpdater) external virtual initializer
```
**Parameters**:
* _globalExitRootUpdater: The address to be set as the global exit root updater.
**Description**: Initializes the contract by setting the globalExitRootUpdater address.
**Behavior**:
* Sets the globalExitRootUpdater state variable.
* Marks the contract as initialized to prevent re-initialization.

**Notes**:
This function is marked with the initializer modifier to ensure it can only be called once.

2. **insertGlobalExitRoot**
```
function insertGlobalExitRoot(bytes32 _newRoot) external onlyGlobalExitRootUpdater
```
**Parameters**:
* _newRoot: The new global exit root to insert.
**Description**: Inserts a new global exit root into the mapping and increments the insertion count.
**Behavior**:
* Checks if the _newRoot has already been inserted by verifying globalExitRootMap[_newRoot].
* If not inserted, increments insertedGERCount and updates the mapping.
* Emits the InsertGlobalExitRoot event.
* If already inserted, reverts with GlobalExitRootAlreadySet().
* Access Control: Restricted to the globalExitRootUpdater via the onlyGlobalExitRootUpdater modifier.

3. **removeLastGlobalExitRoots**
```
function removeLastGlobalExitRoots(bytes32[] calldata gersToRemove) external onlyGlobalExitRootUpdater
````

**Parameters**:
* gersToRemove: An array of global exit roots to remove. The array should be in the order of insertion, with the first element being the last inserted root.

**Description**: Removes the last inserted global exit roots specified in the array.
**Behavior**:
* Checks if there are enough inserted roots to remove the requested number by comparing gersToRemove.length with insertedGERCount.
* Iterates over gersToRemove:
    * Verifies that each root to remove is indeed the last inserted by checking globalExitRootMap[rootToRemove] == insertedGERCountCache.
    * If verification passes, deletes the root from the mapping and decrements insertedGERCount.
    * Emits the RemoveLastGlobalExitRoot event for each removed root.
* If any root is not the last inserted, reverts with NotLastInsertedGlobalExitRoot().
* If there are not enough roots to remove, reverts with NotEnoughGlobalExitRootsInserted().
* Access Control: Restricted to the globalExitRootUpdater via the onlyGlobalExitRootUpdater modifier.
---
### Errors

* **OnlyGlobalExitRootUpdater**(): Thrown when a function is called by an address that is not authorized as the global exit root updater.
* **GlobalExitRootAlreadySet**(): Thrown when attempting to insert a global exit root that has already been inserted.
* **NotEnoughGlobalExitRootsInserted**(): Thrown when attempting to remove more global exit roots than have been inserted.
* **NotLastInsertedGlobalExitRoot**(): Thrown when attempting to remove a global exit root that is not the last inserted one.

---
### Usage Notes

* **Global Exit Root Updater**: The globalExitRootUpdater plays a crucial role in managing global exit roots. It can be set to a specific address or left as the zero address. When set to zero, the block.coinbase (the miner or validator who mined the block) becomes the authorized updater.
* **Insertion Order**: The contract maintains an insertion order for global exit roots using the insertedGERCount. This ensures that only the last inserted roots can be removed, preserving the integrity of the exit root sequence.
* **Access Control**: Functions that modify the state of global exit roots are protected by the onlyGlobalExitRootUpdater modifier to prevent unauthorized access.
* **Initialization**: The initialize function must be called after deployment to set the globalExitRootUpdater. This function can only be called once due to the initializer modifier.
* **Error Handling**: The contract uses custom errors to provide more efficient and informative error handling. These errors should be handled appropriately when interacting with the contract.

**Disclaimer**: This documentation is provided for informational purposes only and may not cover all aspects of the contract. Always review the contract code thoroughly before interacting with it.