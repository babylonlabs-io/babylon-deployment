#!/bin/bash -eux

# USAGE:
# ./write-upgrades-data.sh

# Calls both btc headers and signed finality providers script to write
# the upgrade data.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
DATA_DIR="${DATA_DIR:-$CWD/../data}"
OUTPUTS_DIR="${OUTPUTS_DIR:-$DATA_DIR/outputs}"
NUMBER_FPS_SIGNED="${NUMBER_FPS_SIGNED:-2}"

# Writes all the btc headers.
$CWD/write-upgrade-btc-headers.sh

fpdOut=$OUTPUTS_DIR/fps
mkdir -p $fpdOut

# Creates all the signed msgs and concatenate
for i in $(seq 1 $NUMBER_FPS_SIGNED); do
  fpNum=$(ls $DATA_DIR/fpd/ | wc -l)
  echo "creating fp number $fpNum"
  OUTPUT_SIGNED_MSG=$fpdOut/fp-$fpNum-signed-create-msg.json $CWD/fpd-create-signed-fp.sh
done

SIGNED_MSGS_PATH=$fpdOut $CWD/write-upgrade-signed-fps.sh
