#!/bin/bash -eu

# USAGE:
# ./print-epoch-msgs.sh <option of full path to babylond>

# Iterates over all epochs and print the number of msgs on it

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

NODE_BIN="${1:-$CWD/../../../babylon/build/babylond}"

CHAIN_ID="${CHAIN_ID:-test-1}"
DATA_DIR="${DATA_DIR:-$CWD/../data}"
CHAIN_DIR="${CHAIN_DIR:-$DATA_DIR/babylon}"
SOFTWARE_UPGRADE_FILE="${SOFTWARE_UPGRADE_FILE:-$CWD/../upgrades/props/v1.json}"
outdir="$DATA_DIR/out"

. $CWD/../helpers.sh $NODE_BIN
checkBabylond

nodeF="--node https://rpc-covenant.testnet.babylonlabs.io:443"

lastEpoch=$($NODE_BIN q epoching epoch $nodeF -o json | jq -r '.epoch.epoch_number')

for epochNumber in $(seq 1 $lastEpoch);
do
  msgsQnt=$($NODE_BIN q epoching epoch-msgs $epochNumber $nodeF -o json | jq '.msgs | length')
  echo "Epoch number" $epochNumber " had " $msgsQnt " msgs"
done