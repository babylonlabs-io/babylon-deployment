#!/bin/bash -eu

# USAGE:
# ./bitcoind-btc-base-header.sh

# Creates the base btc header from a regtest bitcoind chain

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# These options can be overridden by env
CHAIN_DIR="${CHAIN_DIR:-$CWD/../data}"
BTC_HOME="${BTC_HOME:-$CHAIN_DIR/bitcoind}"
EXPORT_TO="${EXPORT_TO:-$CHAIN_DIR/outputs/btc-base-header.json}"

if ! command -v bitcoin-cli &> /dev/null
then
  echo "⚠️ bitcoin-cli command could not be found!"
  echo "Install it by checking https://bitcoin.org/en/full-node"
  exit 1
fi

flagDataDir="-datadir=$BTC_HOME"

btcBlockZeroHash=$(bitcoin-cli $flagDataDir getblockhash 0)
btcBlockZeroHeader=$(bitcoin-cli $flagDataDir getblockheader $btcBlockZeroHash false)

echo "{
  \"header\": \"$btcBlockZeroHeader\",
  \"hash\": \"$btcBlockZeroHash\",
  \"height\": \"0\",
  \"work\": \"2\"
}" > $EXPORT_TO
