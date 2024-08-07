#!/bin/bash -eux

# USAGE:
# ./bbn-start-and-upgrade-signet-launch.sh

# Runs the signet launch upgrade '-'
# It adds new btc headers to the running chain

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"

NODE_BIN="${1:-$CWD/../../babylon/build/babylond}"

STARTERS="${STARTERS:-$CWD/starters}"
UPGRADES="${UPGRADES:-$CWD/upgrades}"

CHAIN_DIR="${CHAIN_DIR:-$CWD/data}"
DATA_OUTPUTS="${DATA_OUTPUTS:-$CHAIN_DIR/outputs}"
BTC_BASE_HEADER_FILE="${BTC_BASE_HEADER_FILE:-$DATA_OUTPUTS/btc-base-header.json}"

. $CWD/helpers.sh
mkdir -p $DATA_OUTPUTS

# Start bitcoind
$STARTERS/start-bitcoind.sh
sleep 2

writeBaseBtcHeaderFile $BTC_BASE_HEADER_FILE

# Setup and start single node with base btc header set
BTC_BASE_HEADER_FILE=$BTC_BASE_HEADER_FILE $STARTERS/start-babylond-single-node.sh

# wait for a block
sleep 6

# Writes the btc headers into babylond upgrades
$STARTERS/setup-staking-indexer.sh

btcHeaderTipBeforeUpgrade=$($NODE_BIN q btclightclient tip -o json | jq .header.height -r)

# Gov prop, waits for block, kill and reestart in the new version
PRE_BUILD_UPGRADE_SCRIPT=$UPGRADES/write-upgrade-btc-headers.sh SOFTWARE_UPGRADE_FILE=$UPGRADES/props/signet-launch.json \
  BABYLON_VERSION_WITH_UPGRADE="rafilx/e2e-upgrade-btc-headers" $UPGRADES/upgrade-single-node.sh

# checks if all the btc headers were added '-'
btcHeaderTipAfterUpgrade=$($NODE_BIN q btclightclient tip -o json | jq .header.height -r)

if ! [[ $btcHeaderTipAfterUpgrade -gt $btcHeaderTipBeforeUpgrade ]]; then
  echo "Upgrade should have applied a bunch of btc headers"
  exit 1
fi

echo "Signet launch upgrade was correctly executed"
