# Verify genesis implementations

A lightweight script that verifies the genesis contract implementations starting from a given `bridge proxy address`.

Given a Bridge Proxy address, the script retrieves and verifies:

- **Bridge Implementation**: obtained from the proxy’s EIP-1967 implementation storage slot.
- **Global Exit Root Implementation**: resolved by calling `globalExitRootManager()` on the bridge to find the GER proxy, then reading its EIP-1967 implementation slot.

## Requirements

You need the following installed and available in your environment:

- git: for cloning the repository.

- Node.js (and npm): to install dependencies and compile with Hardhat.

- Foundry’s `cast`: used to read storage and call contract methods (cast storage, cast call).

## Parameters

| Flag             | Required | Description                                                    |
| ---------------- | -------- | -------------------------------------------------------------- |
| `--bridge-proxy` | ✅        | Bridge **proxy** address (checksummed).                        |
| `--tag`          | ✅        | Git tag to check out in `agglayer-contracts` (e.g. `v12.1.1`). |
| `--rpc-url`      | ✅        | RPC endpoint for the target chain.                             |
| `--chainid`      | ✅        | Chain ID for the network entry.                                |
| `--api-url`      | ✅        | Explorer API base URL (Etherscan-compatible).                  |
| `--browser-url`  | ✅        | Explorer browser URL (used by Hardhat for links).              |

## Usage
```
  verify-genesis.sh \
    --bridge-proxy <bridge-proxy-address> \
    --tag <git-tag> \
    --rpc-url <url> \
    --chainid <id> \
    --api-url <url> \
    --browser-url <url>
```

## General script

verify-genesis.sh:

```
#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  verify-agglayer.sh \
    --bridge-proxy <bridge-proxy-address> \
    --tag <git-tag> \
    --rpc-url <url> \
    --chainid <id> \
    --api-url <url> \
    --browser-url <url>
EOF
}

# --- Long flag parsing ---
BRIDGE_PROXY=""
TAG=""
CUSTOM_PROVIDER=""
CUSTOM_CHAIN_ID=""
CUSTOM_API_URL=""
CUSTOM_BROWSER_URL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bridge-proxy)  BRIDGE_PROXY="${2:-}"; shift 2 ;;
    --tag)           TAG="${2:-}"; shift 2 ;;
    --rpc-url)       CUSTOM_PROVIDER="${2:-}"; shift 2 ;;
    --chainid)       CUSTOM_CHAIN_ID="${2:-}"; shift 2 ;;
    --api-url)       CUSTOM_API_URL="${2:-}"; shift 2 ;;
    --browser-url)   CUSTOM_BROWSER_URL="${2:-}"; shift 2 ;;
    -h|--help)       usage; exit 0 ;;
    *) echo "Unknown flag: $1"; usage; exit 1 ;;
  esac
done

# --- Validation ---
[[ -n "$BRIDGE_PROXY" ]] || { echo "Missing --bridge-proxy"; usage; exit 1; }
[[ -n "$TAG" ]] || { echo "Missing --tag"; usage; exit 1; }
[[ -n "$CUSTOM_PROVIDER" ]] || { echo "Missing --rpc-url"; usage; exit 1; }
[[ -n "$CUSTOM_CHAIN_ID" ]] || { echo "Missing --chainid"; usage; exit 1; }
[[ -n "$CUSTOM_API_URL" ]] || { echo "Missing --api-url"; usage; exit 1; }
[[ -n "$CUSTOM_BROWSER_URL" ]] || { echo "Missing --browser-url"; usage; exit 1; }

# --- Helpers ---
SLOT_IMPL="0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"

hex_to_addr () {
  # Recibe 0x<64-hex> y devuelve 0x<40-hex> (últimos 20 bytes)
  local v="${1#0x}"
  printf "0x%s\n" "${v: -40}"
}

# --- Compute values from the provided proxy ---
# Get bridge implementation address
RAW_IMPL=$(cast storage "$BRIDGE_PROXY" "$SLOT_IMPL" --rpc-url "$CUSTOM_PROVIDER")
BRIDGE_IMPL=$(hex_to_addr "$RAW_IMPL")

# Get globalExitRootManager proxy address
GER_PROXY=$(cast call "$BRIDGE_PROXY" "globalExitRootManager()(address)" --rpc-url "$CUSTOM_PROVIDER")
RAW_GER_IMPL=$(cast storage "$GER_PROXY" "$SLOT_IMPL" --rpc-url "$CUSTOM_PROVIDER")
GER_IMPL=$(hex_to_addr "$RAW_GER_IMPL")

echo "Using:"
echo "  Bridge Proxy:      $BRIDGE_PROXY"
echo "  Bridge Implementation: $BRIDGE_IMPL"
echo "  GER Implementation:    $GER_IMPL"

# --- Temporary workspace + cleanup ---
WORKDIR="$(mktemp -d -t agglayer-contracts-XXXXXX)"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

# --- Clone, install, and compile ---
git clone git@github.com:agglayer/agglayer-contracts.git "$WORKDIR/agglayer-contracts"
cd "$WORKDIR/agglayer-contracts"
git checkout "$TAG"
npm i
npx hardhat compile

FILE="hardhat.config.ts"
# --- Update hardhat config with custom chain (if it doesn't exist) ---
if ! grep -Eq '^[[:space:]]*custom[[:space:]]*:[[:space:]]*{' "$FILE"; then
    awk '
      /sepolia:/ && !done {
        print "        custom: {";
        print "            url: process.env.CUSTOM_PROVIDER ? process.env.CUSTOM_PROVIDER : '\''http://127.0.0.1:8545'\'',";
        print "            accounts: {";
        print "                mnemonic: process.env.MNEMONIC || DEFAULT_MNEMONIC,";
        print "                path: \"m/44'\''/60'\''/0'\''/0\",";
        print "                initialIndex: 0,";
        print "                count: 20,";
        print "            },";
        print "        },";
        print $0;
        done=1;
        next
      }
      { print $0 }
    ' "$FILE" > tmp && mv tmp "$FILE"

    awk '
      /customChains[[:space:]]*:[[:space:]]*\[/ && !done {
        print $0;
        print "            {";
        print "                network: '\''custom'\'',";
        print "                chainId: Number(process.env.CUSTOM_CHAIN_ID),";
        print "                urls: {";
        print "                    apiURL: `${process.env.CUSTOM_API_URL}`,";
        print "                    browserURL: `${process.env.CUSTOM_BROWSER_URL}`,";
        print "                },";
        print "            },";
        done=1; next
      }
      { print }
    ' "$FILE" > "tmp.$$" && mv "tmp.$$" "$FILE"

    awk '
      /apiKey:/ && !done {
        print $0;
        print "            custom: `${process.env.CUSTOM_ETHERSCAN_API_KEY}`,";
        done=1; next
      }
      { print }
    ' "$FILE" > "tmp.$$" && mv "tmp.$$" "$FILE"

    echo "Added custom network configuration to $FILE"
else
    echo "Custom network configuration already exists in $FILE, skipping modification."
fi

# --- Create .env for custom network ---
cat > .env <<EOF
CUSTOM_PROVIDER=$CUSTOM_PROVIDER
CUSTOM_CHAIN_ID=$CUSTOM_CHAIN_ID
CUSTOM_API_URL=$CUSTOM_API_URL
CUSTOM_BROWSER_URL=$CUSTOM_BROWSER_URL
EOF

# --- Verification ---
# PolygonZkEVMBridge implementation
npx hardhat verify --network custom "$BRIDGE_IMPL"
# PolygonZkEVMGlobalExitRootL2 implementation - constructor args: bridge address
npx hardhat verify --network custom "$GER_IMPL" "$BRIDGE_PROXY"

echo "✔ Verification completed using tag $TAG"
```

## What the script does

- Validates flags and exits with a helpful message if anything is missing.

- Derives implementations:
    - Reads the EIP-1967 implementation slot 0x3608…bbcc from the bridge proxy to get Bridge Implementation.
    - Calls globalExitRootManager() on the bridge to obtain the GER proxy, then reads its EIP-1967 slot for GER Implementation.

- Creates a temporary workspace (mktemp) and ensures it’s deleted on exit (trap).

- Clones `agglayer-contracts`, checks out the provided tag, installs dependencies, and compiles.

- Injects a custom network into hardhat.config.ts if it isn’t already present:
Adds a networks.custom entry and a customChains entry with your apiURL and browserURL.

- Writes a `.env` with your explorer/RPC details to feed Hardhat.

- Runs npx hardhat verify for:
    - Bridge Implementation (no constructor params)
    - GER Implementation (constructor: bridge proxy address)

- Prints a success line with the tag used.