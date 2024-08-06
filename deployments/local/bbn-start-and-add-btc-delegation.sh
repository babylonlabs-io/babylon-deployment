#!/bin/bash -eu

# USAGE:
# ./bbn-start-stop-exportgen-start.sh

# Starts all the process necessary to have a babylon chain running with active btc delegation.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"

CHAIN_DIR="${CHAIN_DIR:-$CWD/data}"
STARTERS="${STARTERS:-$CWD/starters}"
STOP="${STOP:-$CWD/stop}"
CLEANUP="${CLEANUP:-1}"
COVD_HOME="${COVD_HOME:-$CHAIN_DIR/covd}"

# Cleans everything
if [[ "$CLEANUP" == 1 || "$CLEANUP" == "1" ]]; then
  $STOP/kill-all-process.sh

  rm -rf $CHAIN_DIR
  echo "Removed $CHAIN_DIR"
fi

# setup covd
CHAIN_DIR=$CHAIN_DIR $STARTERS/setup-covd.sh

# Starts BTC
CHAIN_DIR=$CHAIN_DIR $STARTERS/start-bitcoind.sh
sleep 2

# Starts the blockchain
covdPKs=$COVD_HOME/pks.json
CHAIN_DIR=$CHAIN_DIR COVENANT_QUORUM=1 COVENANT_PK_FILE=$covdPKs $STARTERS/start-babylond-single-node.sh
sleep 6 # wait a few seconds for the node start building blocks

# Start Covenant
CLEANUP=0 SETUP=0 $STARTERS/start-covd.sh

# Start Vigilante
CLEANUP=1 CHAIN_DIR=$CHAIN_DIR $STARTERS/start-vigilante.sh

# Start EOTS
CHAIN_DIR=$CHAIN_DIR $STARTERS/start-eots.sh

# sleeps here, because covd and fpd need funds and execute an tx bank send from user
# to avoid acc sequence errors, just wait until produces a block.
sleep 2

# Start FPD
CHAIN_DIR=$CHAIN_DIR $STARTERS/start-fpd.sh

sleep 12 # waits for fdp to send some txs

# Start BTC Staker and stakes to btc
CHAIN_DIR=$CHAIN_DIR $STARTERS/start-btc-staker.sh
