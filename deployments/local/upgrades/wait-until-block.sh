#!/bin/bash -eu

# USAGE:
# ./wait-until-block.sh <option of full path to babylond>

# Waits until a specific block height

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

NODE_BIN="${1:-$CWD/../../../babylon/build/babylond}"

if [ ! -f $NODE_BIN ]; then
  echo "$NODE_BIN does not exists. build it first with $~ make"
  exit 1
fi

defaultBlockToWait=$($NODE_BIN status | jq ".sync_info.latest_block_height | tonumber | . + 12")
BLOCK_HEIGHT="${BLOCK_HEIGHT:-$defaultBlockToWait}"

BLOCK_HEIGHT_TO_WAIT=$BLOCK_HEIGHT
CUR_BLOCK_HEIGHT=0
while [ $CUR_BLOCK_HEIGHT -lt $BLOCK_HEIGHT_TO_WAIT ]
do
  CUR_BLOCK_HEIGHT=`$NODE_BIN status | jq ".sync_info.latest_block_height | tonumber"`
  echo "Current block height $CUR_BLOCK_HEIGHT, waiting to reach $BLOCK_HEIGHT_TO_WAIT"
  sleep 3
done
