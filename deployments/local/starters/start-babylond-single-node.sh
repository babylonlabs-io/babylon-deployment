#!/bin/bash -eu

# USAGE:
# ./start-babylond-single-node.sh <option of full path to babylond>

# Starts an babylon chain with only a single node chain.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

NODE_BIN="${1:-$CWD/../../../babylon/build/babylond}"

CHAIN_ID="${CHAIN_ID:-test-1}"
CHAIN_DIR="${CHAIN_DIR:-$CWD/../data}"
DENOM="${DENOM:-ubbn}"
BTC_BASE_HEADER_FILE="${BTC_BASE_HEADER_FILE:-""}"
COVENANT_PK_FILE="${COVENANT_PK_FILE:-""}"
COVENANT_QUORUM="${COVENANT_QUORUM:-3}"

echo "--- Chain ID = $CHAIN_ID"
echo "--- Chain Dir = $CHAIN_DIR"
echo "--- Coin Denom = $DENOM"

if [ ! -f $NODE_BIN ]; then
  echo "$NODE_BIN does not exists. build it first with $~ make"
  exit 1
fi

hdir="$CHAIN_DIR/$CHAIN_ID"

# Folder for node
n0dir="$hdir/n0"

# Home flag for folder
home0="--home $n0dir"

# Process id of node 0
n0pid="$hdir/n0.pid"

BTC_BASE_HEADER_FILE=$BTC_BASE_HEADER_FILE COVENANT_PK_FILE=$COVENANT_PK_FILE COVENANT_QUORUM=$COVENANT_QUORUM CHAIN_ID=$CHAIN_ID CHAIN_DIR=$CHAIN_DIR DENOM=$DENOM $CWD/setup-babylond-single-node.sh

log_path=$hdir/n0.log

$NODE_BIN $home0 start --api.enable true --grpc.address="0.0.0.0:9090" --api.enabled-unsafe-cors --grpc-web.enable=true --log_level info > $log_path 2>&1 &

# Gets the node pid
echo $! > $n0pid

# Start the instance
echo "--- Starting node..."
echo
echo "Logs:"
echo "  * tail -f $log_path"
echo
echo "Env for easy access:"
echo "export H1='--home $n0dir'"
echo
echo "Command Line Access:"
echo "  * $NODE_BIN --home $n0dir status"
