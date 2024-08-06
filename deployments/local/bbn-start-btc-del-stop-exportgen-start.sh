#!/bin/bash -eu

# USAGE:
# ./bbn-start-btc-del-stop-exportgen-start.sh

# Starts all the processes necessary to have a btc delegation active, stops the
# chain process, export the genesis, setup a new chain with new chain id
# copy some data from the exported genesis into the new one and start a new chain
# with active btc delegations from start.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"
CHAIN_DIR="${CHAIN_DIR:-$CWD/data}"
STARTERS="${STARTERS:-$CWD/starters}"
STOP="${STOP:-$CWD/stop}"

VIGILANTE_HOME="${VIGILANTE_HOME:-$CHAIN_DIR/vigilante}"
COVD_HOME="${COVD_HOME:-$CHAIN_DIR/covd}"
CHAIN_ID_PHASE1="${CHAIN_ID_PHASE1:-test-1}"
NODE_BIN="${1:-$CWD/../../babylon/build/babylond}"
CLEANUP="${CLEANUP:-1}"

if [[ "$CLEANUP" == 1 || "$CLEANUP" == "1" ]]; then
  $STOP/kill-all-process.sh

  rm -rf $CHAIN_DIR
  echo "Removed $CHAIN_DIR"
fi

# Starts everything with btc delegation
$CWD/bbn-start-and-add-btc-delegation.sh

WAIT_UNTIL=1
amountActiveDels=0
while [ $amountActiveDels -lt $WAIT_UNTIL ]
do
  amountActiveDels="$($NODE_BIN q btcstaking btc-delegations active -o json | jq '.btc_delegations | length')"
  echo "Current active dels: $amountActiveDels, waiting to reach $WAIT_UNTIL"
  sleep 10
done

# Kills the running node
bbnChain1Dir="$CHAIN_DIR/$CHAIN_ID_PHASE1"
chain1N0Home="$bbnChain1Dir/n0"
PATH_OF_PIDS=$bbnChain1Dir/*.pid $STOP/kill-process.sh

sleep 5

exportedGenFile=$chain1N0Home/config/genesis.exported.json

# Export the genesis
$NODE_BIN --home $chain1N0Home export > $exportedGenFile

# Starts a new babylon chain with a new chain id
CHAIN_ID_PHASE2=test-2
CHAIN_ID=$CHAIN_ID_PHASE2 EXPORTED_GEN_FILE=$exportedGenFile $STARTERS/start-babylond-single-node-from-exported-gen.sh
sleep 7 # waits for node to fully start to query

WAIT_UNTIL=1
amountActiveDels=0
while [ $amountActiveDels -lt $WAIT_UNTIL ]
do
  amountActiveDels="$($NODE_BIN q btcstaking btc-delegations active -o json | jq '.btc_delegations | length')"
  echo "Current active dels: $amountActiveDels, waiting to reach $WAIT_UNTIL"
  sleep 10
done
echo "FINALLY STARTED CHAIN 2 WITH BTC DELS"