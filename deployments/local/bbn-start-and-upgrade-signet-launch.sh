#!/bin/bash -eu

# USAGE:
# ./bbn-start-and-upgrade-signet-launch.sh

# Runs the signet launch upgrade '-'
# It adds new btc headers to the running chain

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"

NODE_BIN="${1:-$CWD/../../babylon/build/babylond}"

STARTERS="${STARTERS:-$CWD/starters}"
UPGRADES="${UPGRADES:-$CWD/upgrades}"

# Start bitcoind
$STARTERS/start-bitcoind.sh

# Setup and start single node with base btc header set
$STARTERS/start-babylond-single-node.sh

# wait for a block
sleep 6

# Writes the btc headers into babylond upgrades


# Gov prop, waits for block, kill and reestart in the new version
SOFTWARE_UPGRADE_FILE=$UPGRADES/props/signet-launch.json $UPGRADES/upgrade-single-node.sh

# checks if new fp was added '-'
# lenFpsAfterUpgrade=$($NODE_BIN q btcstaking finality-providers -o json | jq ".finality_providers | length")

# if ! [[ "$lenFpsAfterUpgrade" -gt $lenFpsBeforeUpgrade ]]; then
#   echo "Upgrade should have applied a new finality provider"
#   exit 1
# fi
