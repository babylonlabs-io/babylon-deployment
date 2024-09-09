#!/bin/bash -eux

# USAGE:
# ./start-babylond-single-node.sh <option of full path to babylond>

# Starts an babylon chain with only a single node chain.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

NODE_BIN="${1:-$CWD/../../../babylon/build/babylond}"

CHAIN_ID="${CHAIN_ID:-test-1}"
DATA_DIR="${DATA_DIR:-$CWD/../data}"
CHAIN_DIR="${CHAIN_DIR:-$DATA_DIR/babylon}"
DENOM="${DENOM:-ubbn}"
BTC_BASE_HEADER_FILE="${BTC_BASE_HEADER_FILE:-""}"
COVENANT_PK_FILE="${COVENANT_PK_FILE:-""}"
COVENANT_QUORUM="${COVENANT_QUORUM:-3}"
SETUP="${SETUP:-1}"

hdir="$CHAIN_DIR/$CHAIN_ID"

# Folder for node
n0dir="$hdir/n0"

NODE_LOG_PATH="${NODE_LOG_PATH:-$n0dir/start.log}"

echo "--- Chain ID = $CHAIN_ID"
echo "--- Chain Dir = $CHAIN_DIR"
echo "--- Coin Denom = $DENOM"

if [ ! -f $NODE_BIN ]; then
  echo "$NODE_BIN does not exists. build it first with $~ make"
  exit 1
fi

# Home flag for folder
home0="--home $n0dir"

# Process id of node 0
n0pid="$n0dir/start.pid"

if [[ "$SETUP" == 1 || "$SETUP" == "1" ]]; then
  BTC_BASE_HEADER_FILE=$BTC_BASE_HEADER_FILE COVENANT_PK_FILE=$COVENANT_PK_FILE COVENANT_QUORUM=$COVENANT_QUORUM CHAIN_ID=$CHAIN_ID CHAIN_DIR=$CHAIN_DIR DENOM=$DENOM $CWD/setup-babylond-single-node.sh
fi

$NODE_BIN $home0 start --api.enable true --grpc.address="0.0.0.0:9090" --api.enabled-unsafe-cors --grpc-web.enable=true --log_level info > $NODE_LOG_PATH 2>&1 &
echo $! > $n0pid

# Start the instance
echo "--- Starting node..."
echo
echo "Logs:"
echo "  * tail -f $NODE_LOG_PATH"
echo
echo "Env for easy access:"
echo "export H1='--home $n0dir'"
echo
echo "Command Line Access:"
echo "  * $NODE_BIN --home $n0dir status"
