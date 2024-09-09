#!/bin/bash -eux

# USAGE:
# ./bbn-start-and-upgrade-signet-launch.sh

# Runs the signet launch upgrade '-'
# It adds new btc headers to the running chain

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"

NODE_BIN="${1:-$CWD/../../babylon/build/babylond}"

STARTERS="${STARTERS:-$CWD/starters}"
UPGRADES="${UPGRADES:-$CWD/upgrades}"

DATA_DIR="${DATA_DIR:-$CWD/data}"
DATA_OUTPUTS="${DATA_OUTPUTS:-$DATA_DIR/outputs}"
BTC_BASE_HEADER_FILE="${BTC_BASE_HEADER_FILE:-$DATA_OUTPUTS/btc-base-header.json}"

. $CWD/helpers.sh $NODE_BIN
mkdir -p $DATA_OUTPUTS

# Start bitcoind
$STARTERS/start-bitcoind.sh
sleep 2

# writes block zero from BTC to babylon
writeBaseBtcHeaderFile $BTC_BASE_HEADER_FILE

# Setup and start single node with base btc header set
BTC_BASE_HEADER_FILE=$BTC_BASE_HEADER_FILE $STARTERS/start-babylond-single-node.sh

# wait for a block
sleep 6

# Writes the btc headers into babylond upgrades
$STARTERS/setup-staking-indexer.sh

btcHeaderTipBeforeUpgrade=$($NODE_BIN q btclightclient tip -o json | jq .header.height -r)
fpsLengthBeforeUpgrade=$($NODE_BIN q btcstaking finality-providers --output json | jq '.finality_providers | length')

# Gov prop, waits for block, kill and reestart in the new version
PRE_BUILD_UPGRADE_SCRIPT=$UPGRADES/write-upgrades-data.sh SOFTWARE_UPGRADE_FILE=$UPGRADES/props/signet-launch.json \
  BABYLON_VERSION_WITH_UPGRADE="main" $UPGRADES/upgrade-single-node.sh

# checks if all the btc headers and fps were added '-'
upgradeHeight=$($NODE_BIN q upgrade applied signet-launch --output json | jq ".height" -r)
btcHeaderTipAfterUpgrade=$($NODE_BIN q btclightclient tip -o json | jq .header.height -r)
fpsLengthAfterUpgrade=$($NODE_BIN q btcstaking finality-providers --output json | jq '.finality_providers | length')

if ! [[ $btcHeaderTipAfterUpgrade -gt $btcHeaderTipBeforeUpgrade ]]; then
  echo "Upgrade should have applied a bunch of btc headers"
  exit 1
fi
if ! [[ $fpsLengthAfterUpgrade -gt $fpsLengthBeforeUpgrade ]]; then
  echo "Upgrade should have applied a bunch of finality providers"
  exit 1
fi

echo "Signet launch upgrade was correctly executed at block height " $upgradeHeight
echo "the last btc header height is" $btcHeaderTipAfterUpgrade
echo "the number of finality providers increased from" $fpsLengthBeforeUpgrade " to " $fpsLengthAfterUpgrade