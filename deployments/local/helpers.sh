#!/bin/bash -eu

# USAGE:
# ./helpers.sh <option of full path to babylond>

# Contains diff functions to help other scripts

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

BABYLON_PATH="${BABYLON_PATH:-$SCRIPT_DIR/../../../babylon}"
NODE_BIN="${1:-$BABYLON_PATH/build/babylond}"

DATA_DIR="${DATA_DIR:-$SCRIPT_DIR/../data}"
BTC_HOME="${BTC_HOME:-$DATA_DIR/bitcoind}"
STOP="${STOP:-$SCRIPT_DIR/stop}"

FPD_BIN="${FPD_BIN:-$SCRIPT_DIR/../../../finality-provider/build/fpd}"

# general usage flags
flagBtcDataDir="-datadir=$BTC_HOME"


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

writeBaseBtcHeaderFile() {
  EXPORT_TO=$1

  btcBlockZeroHash=$(bitcoin-cli $flagBtcDataDir getblockhash 0)
  btcBlockZeroHeader=$(bitcoin-cli $flagBtcDataDir getblockheader $btcBlockZeroHash false)

  echo "{
    \"header\": \"$btcBlockZeroHeader\",
    \"hash\": \"$btcBlockZeroHash\",
    \"height\": \"0\",
    \"work\": \"2\"
  }" > $EXPORT_TO
}

cleanUp() {
  CLEANUP=$1
  PATH_OF_PIDS=$2
  DIR_TO_REMOVE=$3

  if [[ "$CLEANUP" == 1 || "$CLEANUP" == "1" ]]; then
    PATH_OF_PIDS=$PATH_OF_PIDS $STOP/kill-process.sh

    rm -rf $DIR_TO_REMOVE
    echo "Removed $DIR_TO_REMOVE"
  fi
}

getBtcTipHeight() {
  btcBlockTipHash=$(bitcoin-cli $flagBtcDataDir getbestblockhash)
  btcBlockTipHeight=$(bitcoin-cli $flagBtcDataDir getblockheader $btcBlockTipHash | jq .height)
  echo $btcBlockTipHeight
}


checkBabylond() {
  if [ ! -f $NODE_BIN ]; then
    echo "$NODE_BIN does not exists. build it first with $~ make"
    exit 1
  fi
}

checkFpd() {
  if [ ! -f $FPD_BIN ]; then
    echo "$FPD_BIN does not exists. build it first with $~ make"
    exit 1
  fi
}

checkBitcoinCLI() {
  if ! command -v bitcoin-cli &> /dev/null
  then
    echo "⚠️ bitcoin-cli command could not be found!"
    echo "Install it by checking https://bitcoin.org/en/full-node"
    exit 1
  fi
}

checkBitcoind() {
  if ! command -v bitcoind &> /dev/null
  then
    echo "⚠️ bitcoind command could not be found!"
    echo "Install it by checking https://bitcoin.org/en/full-node"
    exit 1
  fi
}

checkJq() {
  if ! command -v jq &> /dev/null
  then
    echo "⚠️ jq command could not be found!"
    echo "Install it by checking https://stedolan.github.io/jq/download/"
    exit 1
  fi
}
