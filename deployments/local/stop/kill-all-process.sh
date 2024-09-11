#!/bin/bash

# USAGE:
# ./kill-all-process.sh

# Kill all the process stored in the PID paths of possible generated processes in DATA_DIR

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"
DATA_DIR="${DATA_DIR:-$CWD/../data}"
CHAIN_DIR="${CHAIN_DIR:-$DATA_DIR/babylon}"
BTC_HOME="${BTC_HOME:-$DATA_DIR/btc}"
BTC_BITCOIND_HOME="${BTC_BITCOIND_HOME:-$DATA_DIR/bitcoind}"
VIGILANTE_HOME="${VIGILANTE_HOME:-$DATA_DIR/vigilante}"
COVD_HOME="${COVD_HOME:-$DATA_DIR/covd}"
EOTS_HOME="${EOTS_HOME:-$DATA_DIR/eots}"
FPD_HOME="${FPD_HOME:-$DATA_DIR/fpd}"
BTC_STAKER_HOME="${BTC_STAKER_HOME:-$DATA_DIR/btc-staker}"

PATH_OF_PIDS=$CHAIN_DIR/*/*/*.pid $CWD/kill-process.sh
PATH_OF_PIDS=$VIGILANTE_HOME/pid/*.pid $CWD/kill-process.sh
PATH_OF_PIDS=$BTC_HOME/pid/*.pid $CWD/kill-process.sh
PATH_OF_PIDS=$BTC_BITCOIND_HOME/pid/*.pid $CWD/kill-process.sh
PATH_OF_PIDS=$COVD_HOME/*.pid $CWD/kill-process.sh
PATH_OF_PIDS=$EOTS_HOME/*.pid $CWD/kill-process.sh
PATH_OF_PIDS=$FPD_HOME/*/*.pid $CWD/kill-process.sh
PATH_OF_PIDS=$FPD_HOME/*/*/*.pid $CWD/kill-process.sh # eotsd inside fpd
PATH_OF_PIDS=$BTC_STAKER_HOME/pid/*.pid $CWD/kill-process.sh