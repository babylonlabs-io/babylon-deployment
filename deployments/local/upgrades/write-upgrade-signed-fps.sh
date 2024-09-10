#!/bin/bash -eu

# USAGE:
# ./write-upgrade-signed-fps.sh

# Reads all the json files inside a path and cocatenates all of the signed MsgCreateFinalityProvider
# msgs and writes it in a go file as expected by babylon to compile and run the upgrade.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../../..}"
BABYLON_PATH="${BABYLON_PATH:-$BBN_DEPLOYMENTS/babylon}"
SIGNED_MSGS_PATH="${SIGNED_MSGS_PATH:-$BBN_DEPLOYMENTS/networks/bbn-1/finality-providers/msgs}"
GO_SIGNED_FPS_PATH="${GO_SIGNED_FPS_PATH:-$BABYLON_PATH/app/upgrades/signetlaunch/data_signed_fps.go}"

DATA_DIR="${DATA_DIR:-$CWD/../data}"

OUTPUTS_DIR="${OUTPUTS_DIR:-$DATA_DIR/outputs}"
EXPORT_TO="${EXPORT_TO:-$OUTPUTS_DIR/signed-fps.json}"

mkdir -p $OUTPUTS_DIR

concatenatedSignedMsgs=$(jq -s 'map(.)' $SIGNED_MSGS_PATH/*)

# export the concatenated signed finality providers to a file
echo "{ \"signed_txs_create_fp\": $concatenatedSignedMsgs}" | jq > $EXPORT_TO

fpsSignedJson=$(cat $EXPORT_TO)

# writes the signed msg create finality providers to babylon as go file
echo "package signetlaunch

const SignedFPsStr = \`$fpsSignedJson\`" > $GO_SIGNED_FPS_PATH
