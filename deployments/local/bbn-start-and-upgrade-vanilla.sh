#!/bin/bash -eu

# USAGE:
# ./bbn-start-and-upgrade-vanilla.sh

# Runs the vanilla upgrade '-'

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"
CHAIN_DIR="${CHAIN_DIR:-$CWD/data}"
STARTERS="${STARTERS:-$CWD/starters}"
UPGRADES="${STARTERS:-$CWD/upgrades}"
STOP="${STOP:-$CWD/stop}"

VIGILANTE_HOME="${VIGILANTE_HOME:-$CHAIN_DIR/vigilante}"
COVD_HOME="${COVD_HOME:-$CHAIN_DIR/covd}"
CHAIN_ID_PHASE1="${CHAIN_ID_PHASE1:-test-1}"
NODE_BIN="${1:-$CWD/../../babylon/build/babylond}"
CLEANUP="${CLEANUP:-1}"

# TODO: should build the babylond at the expected version by calling make there and going to upgrade version
# Start single node
# Gov prop
# Stop
# build version to upgrade to
# start
# verify if it all went success

$STARTERS/start-babylond-single-node.sh
sleep 10
$UPGRADES/upgrade-single-node.sh
