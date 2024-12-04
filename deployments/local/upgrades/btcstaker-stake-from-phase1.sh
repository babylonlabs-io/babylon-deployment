#!/bin/bash -eu

# USAGE:
# ./btcstaker-stake-from-phase1.sh

# Migrates a phase1 BTC staking tx to a BTC delegation in babylon.
CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../../..}"

BTC_STAKER_BUILD="${BTC_STAKER_BUILD:-$BBN_DEPLOYMENTS/btc-staker/build}"
STAKERCLI_BIN="${STAKERCLI_BIN:-$BTC_STAKER_BUILD/stakercli}"
CLEANUP="${CLEANUP:-1}"

DATA_DIR="${DATA_DIR:-$CWD/../data}"

BTC_STAKER_HOME="${BTC_STAKER_HOME:-$DATA_DIR/btc-staker}"
DATA_OUTPUTS="${DATA_OUTPUTS:-$DATA_DIR/outputs}"
GLOBAL_PARAMS_PATH="${GLOBAL_PARAMS_PATH:-$DATA_OUTPUTS/global_params.json}"

defaultCovenantCommitteePks=$(cat $DATA_DIR/covd/pks.json | jq -r .[])
COVENANT_COMMITTEE_PKS="${COVENANT_COMMITTEE_PKS:-$defaultCovenantCommitteePks}"

btcStakerWalletName="btc-staker"

# . $CWD/../helpers.sh
# cleanUp $CLEANUP $BTC_STAKER_HOME/*.pid $BTC_STAKER_HOME

stakerAddr=$(cat $BTC_STAKER_HOME/out/$btcStakerWalletName.address)
stakingTxHash=$(cat $BTC_STAKER_HOME/out/sendrawtransaction.txt)

$STAKERCLI_BIN daemon stake-from-phase1 $GLOBAL_PARAMS_PATH --staking-transaction-hash $stakingTxHash --staker-address $stakerAddr --tx-inclusion-height 100