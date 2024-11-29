#!/bin/bash -eu

# USAGE:
# ./start-btc-staker.sh

# Starts an btc staker.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../../..}"

BTC_STAKER_BUILD="${BTC_STAKER_BUILD:-$BBN_DEPLOYMENTS/btc-staker/build}"
STAKERD_BIN="${STAKERD_BIN:-$BTC_STAKER_BUILD/stakerd}"

DATA_DIR="${DATA_DIR:-$CWD/../data}"
BTC_STAKER_HOME="${BTC_STAKER_HOME:-$DATA_DIR/btc-staker}"
CLEANUP="${CLEANUP:-1}"

pidPath=$BTC_STAKER_HOME/pid

. $CWD/../helpers.sh

checkStakerd
cleanUp $CLEANUP $pidPath/*.pid  $BTC_STAKER_HOME

stakercliDirHome=$BTC_STAKER_HOME/stakecli
stakercliConfigFile=$stakercliDirHome/config.conf
stakercliLogsDir=$stakercliDirHome/logs

mkdir -p $pidPath
mkdir -p $stakercliLogsDir

# starts the staker daemon
$STAKERD_BIN --configfile=$stakercliConfigFile > $stakercliLogsDir/daemon.log 2>&1 &
echo $! > $pidPath/stakerd.pid
sleep 5 # waits for the daemon to load.
