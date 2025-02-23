#!/bin/bash -eu

# USAGE:
# ./bbn-start-and-add-btc-delegation.sh

# Starts all the process necessary to have a babylon chain running with active btc delegation.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"

DATA_DIR="${DATA_DIR:-$CWD/data}"
DATA_OUTPUTS="${DATA_OUTPUTS:-$DATA_DIR/outputs}"
STARTERS="${STARTERS:-$CWD/starters}"
STOP="${STOP:-$CWD/stop}"
CLEANUP="${CLEANUP:-1}"
COVD_HOME="${COVD_HOME:-$DATA_DIR/covd}"
BTC_BASE_HEADER_FILE="${BTC_BASE_HEADER_FILE:-$DATA_OUTPUTS/btc-base-header.json}"

. $CWD/helpers.sh

# Cleans everything
if [[ "$CLEANUP" == 1 || "$CLEANUP" == "1" ]]; then
  $STOP/kill-all-process.sh

  rm -rf $DATA_DIR
  echo "Removed $DATA_DIR"
fi

mkdir -p $DATA_OUTPUTS

# setup covd
DATA_DIR=$DATA_DIR $STARTERS/setup-covd.sh

$STARTERS/start-covenant-signer.sh

# Starts BTC
DATA_DIR=$DATA_DIR $STARTERS/start-bitcoind.sh
sleep 2

writeBaseBtcHeaderFile $BTC_BASE_HEADER_FILE

# Starts the blockchain
covdPKs=$COVD_HOME/pks.json
BTC_BASE_HEADER_FILE=$BTC_BASE_HEADER_FILE DATA_DIR=$DATA_DIR COVENANT_QUORUM=1 COVENANT_PK_FILE=$covdPKs $STARTERS/start-babylond-single-node.sh
sleep 6 # wait a few seconds for the node start building blocks

# Start Covenant
CLEANUP=0 SETUP=0 $STARTERS/start-covd.sh

# Start Vigilante
CLEANUP=1 DATA_DIR=$DATA_DIR $STARTERS/start-vigilante.sh

# Start EOTS
DATA_DIR=$DATA_DIR $STARTERS/start-eots.sh

# sleeps here, because covd and fpd need funds and execute an tx bank send from user
# to avoid acc sequence errors, just wait until produces a block.
sleep 2

# Start FPD
DATA_DIR=$DATA_DIR $STARTERS/start-fpd.sh

sleep 15 # waits for fdp to send some txs

# Start BTC Staker and stakes to btc
DATA_DIR=$DATA_DIR $STARTERS/btc-staker-start-and-stake.sh

sleep 10

genBTCBlocks 30

