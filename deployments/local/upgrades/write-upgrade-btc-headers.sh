#!/bin/bash -eu

# USAGE:
# ./write-upgrade-btc-headers.sh

# Exports all headers from block height 1 to bitcoind tip block and writes
# it to the golang file where it contains all the upgrades

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../../..}"
BABYLON_PATH="${BABYLON_PATH:-$BBN_DEPLOYMENTS/babylon}"
GO_BTC_HEADERS_PATH="${GO_BTC_HEADERS_PATH:-$BABYLON_PATH/app/upgrades/signetlaunch/data_btc_headers.go}"
SID_BIN="${SID_BIN:-$BBN_DEPLOYMENTS/staking-indexer/build/sid}"

CHAIN_ID="${CHAIN_ID:-test-1}"
CHAIN_DIR="${CHAIN_DIR:-$CWD/../data}"
SID_HOME="${SID_HOME:-$CHAIN_DIR/staking-indexer}"

DATA_OUTPUTS="${DATA_OUTPUTS:-$CHAIN_DIR/outputs}"
EXPORT_TO="${EXPORT_TO:-$DATA_OUTPUTS/btc-headers.json}"

hdir="$CHAIN_DIR/$CHAIN_ID"
homeF="--home $SID_HOME"

. $CWD/../helpers.sh
mkdir -p $DATA_OUTPUTS

btcBlockTipHeight=$(getBtcTipHeight)

# export the btc headers to a file
$SID_BIN btc-headers 1 $btcBlockTipHeight $homeF --output $EXPORT_TO
btcHeadersJson=$(cat $EXPORT_TO)

# writes the headers to babylon as go file
echo "package signetlaunch

const NewBtcHeadersStr = \`$btcHeadersJson\`" > $GO_BTC_HEADERS_PATH
