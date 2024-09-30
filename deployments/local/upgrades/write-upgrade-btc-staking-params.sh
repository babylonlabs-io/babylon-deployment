#!/bin/bash -eu

# USAGE:
# ./write-upgrade-btc-staking-params.sh

# Writes the new btc staking parameters to the babylon golang file to be build for the upgrade.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../../..}"
BABYLON_PATH="${BABYLON_PATH:-$BBN_DEPLOYMENTS/babylon}"
GO_BTC_STAKING_PARAMS_PATH="${GO_BTC_STAKING_PARAMS_PATH:-$BABYLON_PATH/app/upgrades/v1/btcstaking_params.go}"

DATA_DIR="${DATA_DIR:-$CWD/../data}"

defaultCovenantCommitteePks=$(cat $DATA_DIR/covd/pks.json | jq .[])
COVENANT_COMMITTEE_PKS="${COVENANT_COMMITTEE_PKS:-$defaultCovenantCommitteePks}"

# writes the btc staking parameters to babylon as go file
echo "package v1

const BtcStakingParamStr = \`
	{
  \"covenant_pks\": [
    $COVENANT_COMMITTEE_PKS
  ],
  \"covenant_quorum\": 1,
  \"min_staking_value_sat\": \"1000\",
  \"max_staking_value_sat\": \"10000000000\",
  \"min_staking_time_blocks\": 10,
  \"max_staking_time_blocks\": 65535,
  \"slashing_pk_script\": \"dqkUAQEBAQEBAQEBAQEBAQEBAQEBAQGIrA==\",
  \"min_slashing_tx_fee_sat\": \"1000\",
  \"slashing_rate\": \"0.100000000000000000\",
  \"min_unbonding_time_blocks\": 0,
  \"unbonding_fee_sat\": \"1000\",
  \"min_commission_rate\": \"0.03\",
  \"max_active_finality_providers\": 100
}\`
" > $GO_BTC_STAKING_PARAMS_PATH
