#!/bin/bash -eux

# USAGE:
# ./write-upgrade-btc-headers.sh

# Exports all headers from block height 1 to bitcoind tip block and writes
# it to the golang file where it contains all the upgrades

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../../..}"
DATA_DIR="${DATA_DIR:-$CWD/../data}"
DATA_OUTPUTS="${DATA_OUTPUTS:-$DATA_DIR/outputs}"
GLOBAL_PARAMS_PATH="${GLOBAL_PARAMS_PATH:-$DATA_OUTPUTS/global_params.json}"


mkdir -p $DATA_OUTPUTS

defaultCovenantCommitteePks=$(cat $DATA_DIR/covd/pks.json | jq .[])
COVENANT_COMMITTEE_PKS="${COVENANT_COMMITTEE_PKS:-$defaultCovenantCommitteePks}"

# writes the headers to babylon as go file
echo "{
  \"versions\": [
    {
      \"version\": 0,
      \"activation_height\": 10,
      \"staking_cap\": 100000000000,
      \"tag\": \"01020304\",
      \"covenant_pks\": [
        $COVENANT_COMMITTEE_PKS
      ],
      \"covenant_quorum\": 1,
      \"unbonding_time\": 1008,
      \"unbonding_fee\": 64000,
      \"max_staking_amount\": 5000000,
      \"min_staking_amount\": 500000,
      \"max_staking_time\": 64000,
      \"min_staking_time\": 100,
      \"confirmation_depth\": 10
    }
  ]
}" > $GLOBAL_PARAMS_PATH
