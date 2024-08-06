#!/bin/bash -eu

# USAGE:
# ./bbn-start-and-upgrade-vanilla.sh

# Runs the vanilla upgrade '-'

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"

NODE_BIN="${1:-$CWD/../../babylon/build/babylond}"

STARTERS="${STARTERS:-$CWD/starters}"
UPGRADES="${UPGRADES:-$CWD/upgrades}"

# Setup and start single node
$STARTERS/start-babylond-single-node.sh

# wait for a block
sleep 6

lenFpsBeforeUpgrade=$($NODE_BIN q btcstaking finality-providers -o json | jq ".finality_providers | length")

# Gov prop, waits for block, kill and reestart in the new version
$UPGRADES/upgrade-single-node.sh

# checks if new fp was added '-'
lenFpsAfterUpgrade=$($NODE_BIN q btcstaking finality-providers -o json | jq ".finality_providers | length")

if ! [[ "$lenFpsAfterUpgrade" -gt $lenFpsBeforeUpgrade ]]; then
  echo "Upgrade should have applied a new finality provider"
  exit 1
fi

echo "Vanilla upgrade was correctly executed"