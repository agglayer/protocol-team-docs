# Specification
## Motivation
### Precompiled modexp
- The precompiled modexp is enabled: [modexp](https://www.evm.codes/precompiled#0x05?fork=berlin)
    - some fixes regarding the previous version have been added
    - after a few discussions, it is decided to **set the maximum input length of the base, modulus and exponent to 32 chunks of 256 bits**. See [link](https://github.com/0xPolygonHermez/zkevm-rom-internal/issues/43) for more details
    - **if input length > %MAX_SIZE_MODEXP --> zkEVM does a revert returning all the gas consumed**

### RIP7212: p256verify
A precompiled contract that perfoms signature verifications in the `secp256r1` elliptic curve have been added: [rip7212](https://github.com/ethereum/RIPs/blob/master/RIPS/rip-7212.md)

## Tags
- zkevm-rom: [`v9.0.0-rc.2-fork.13`](https://github.com/0xPolygonHermez/zkevm-rom/releases/tag/v9.0.0-rc.2-fork.13)
- zkevm-testvectors: [`v9.0.0-rc.3-fork.13`](https://github.com/0xPolygonHermez/zkevm-testvectors/releases/tag/v9.0.0-rc.3-fork.13)
- zkevm-commonjs: [`v9.0.0-rc.3-fork.13`](https://github.com/0xPolygonHermez/zkevm-commonjs/releases/tag/v9.0.0-rc.3-fork.13)
- zkevm-proverjs:

## git diff
- zkevm-rom: [PR develop-durian](https://github.com/0xPolygonHermez/zkevm-rom/pull/409/files)
- zkevm-testvectors: [PR develop-durian](https://github.com/0xPolygonHermez/zkevm-testvectors/pull/262/files)
- zkevm-commonjs: [PR develop-durian](https://github.com/0xPolygonHermez/zkevm-commonjs/pull/186/files)
- zkevm-proverjs:

## Code changes
### zkevm-rom
- Update constant `forkId`:
```
CONST %FORK_ID = 13
```
#### Modexp
- Update selector precompiled:
```
A - 6               :JMPN(funcModexp)
```
- Update pre-modexp with fixes: [pre-modexp changes](https://github.com/0xPolygonHermez/zkevm-rom/commit/b7904d4711155972c568b27da8a22710e574ac06) + [fix](https://github.com/0xPolygonHermez/zkevm-rom/commit/ee45fd22026fd799b739f2d1caf095cc7de32b73)
- Modexp Update: [PR modexp durian](https://github.com/0xPolygonHermez/zkevm-rom/pull/408/commits)
#### p256verify
- Add new address precompiled:
    - `process-tx.zkasm`:
    ```
    ; Check zero address since zero address is not a precompiled contract
        0 => B
        $                               :EQ, JMPC(callContract)
        0x100 => B
        $                               :EQ, JMPC(selectorPrecompiledP256Verify)
        10 => B
        $                               :LT,JMPC(selectorPrecompiled, callContract)
        $                               :LT, JMPC(selectorPrecompiled, callContract)
    ```
    - `precompiled/selector.zkasm`:
    ```
    selectorPrecompiledP256Verify:
                        :JMP(funcP256VERIFY)
    ```
- Add pre-p256verify:
    - `constants.zkasm`:
    ```
    CONST %P256VERIFY_GAS = 3450 ; p256verify gas price
    ```
    - `precompiled/pre-p256verify.zkasm`: [file](https://github.com/0xPolygonHermez/zkevm-rom/blob/develop-durian/main/precompiled/pre-sha2-256.zkasm)
    - Update `isColdAddress` (`touched.zkasm`):
    ```
    ; if address is a precompiled considered as warm address
    10 => B
    $                           :LT, JMPC(finishColdPrecompiled)
    0x100 => B
    $                           :EQ, JMPC(finishColdPrecompiled)
    ```
    - Update counters: [commit counters](https://github.com/0xPolygonHermez/zkevm-rom/commit/695769018e4fb431a70e8e99c71dc97ffe929925)
- Add `p256verify`: [PR p256verify](https://github.com/0xPolygonHermez/zkevm-rom/pull/407/files)

### zkevm-proverjs
- [PR develop-durian](https://github.com/0xPolygonHermez/zkevm-proverjs/pull/361/files)

### zkevm-testvectors
- Update tests forkId = 13
- Update pre-revert tests (delete modexp)
- Add tests modexp
- Add tests p256verify
- Update tests with 0x100 address in `pre-state` (ethereum-tests)
- Update virtual counters

### zkevm-commonjs
- Update monorepo version
- Update VCs:
    - VCs `p256verify`: [file](https://github.com/0xPolygonHermez/zkevm-commonjs/blob/develop-durian/src/virtual-counters-manager.js#L417)
    - VCs `modexp`: [file](https://github.com/0xPolygonHermez/zkevm-commonjs/blob/develop-durian/src/virtual-counters-manager.js#L341) & [utils](https://github.com/0xPolygonHermez/zkevm-commonjs/blob/develop-durian/src/virtual-counters-manager-utils.js)

### fork ethereumjs-monorepo
- Update p256verify gas cost: [commit](https://github.com/0xPolygonHermez/ethereumjs-monorepo/commit/92e8544b17377c299f243176b2a6d68d7decb544)
- RIP 7212 implementation: [commit](https://github.com/0xPolygonHermez/ethereumjs-monorepo/commit/34cc5dad1849d9b1d12e868f9140ac284f97867c) + [fix](https://github.com/0xPolygonHermez/ethereumjs-monorepo/commit/e32a91d9af5f22dae3347d18d248eeb73db72e87)
- Update VCs RIP7212: [commit](https://github.com/0xPolygonHermez/ethereumjs-monorepo/commit/55cf2a57cd08c245839da3710369ab74399c3f3a)