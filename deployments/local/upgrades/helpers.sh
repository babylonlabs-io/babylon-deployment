#!/bin/bash -eu

# USAGE:
# ./helpers.sh <option of full path to babylond>

# Contains diff functions to help other scripts

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BABYLON_PATH="${BABYLON_PATH:-$CWD/../../../babylon}"
NODE_BIN="${1:-$BABYLON_PATH/build/babylond}"

if [ ! -f $NODE_BIN ]; then
  echo "$NODE_BIN does not exists. build it first with $~ make"
  exit 1
fi

waitForBlock() {
  BLOCK_HEIGHT=$1

  BLOCK_HEIGHT_TO_WAIT=$BLOCK_HEIGHT
  CUR_BLOCK_HEIGHT=0
  while [ $CUR_BLOCK_HEIGHT -lt $BLOCK_HEIGHT_TO_WAIT ]
  do
    CUR_BLOCK_HEIGHT=`$NODE_BIN status | jq ".sync_info.latest_block_height | tonumber"`
    echo "Current block height $CUR_BLOCK_HEIGHT, waiting to reach $BLOCK_HEIGHT_TO_WAIT"
    sleep 3
  done
}

upgradeApplied() {
  SOFTWARE_UPGRADE_FILE=$1

  upgadeBlockHeight=$(cat "$SOFTWARE_UPGRADE_FILE" | jq ".messages[0].plan.height" -r)
  upgradeName=$(cat "$SOFTWARE_UPGRADE_FILE" | jq ".messages[0].plan.name" -r)
  upgradeAppliedAtHeight=$($NODE_BIN q upgrade applied $upgradeName --output json | jq .height -r)

  if ! [[ "$upgadeBlockHeight" -eq $upgradeAppliedAtHeight ]]; then
    echo "Upgrade should have applied at $upgadeBlockHeight, but it was applied at $upgradeAppliedAtHeight"
    exit 1
  fi

  echo "$upgradeName applied with success!"
}