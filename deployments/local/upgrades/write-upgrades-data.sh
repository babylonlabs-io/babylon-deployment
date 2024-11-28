#!/bin/bash -eux

# USAGE:
# ./write-upgrades-data.sh

# Calls all the scripts to write the upgrade data.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
DATA_DIR="${DATA_DIR:-$CWD/../data}"
OUTPUTS_DIR="${OUTPUTS_DIR:-$DATA_DIR/outputs}"
SIGNED_FPD_MSGS_PATH="${SIGNED_FPD_MSGS_PATH:-$OUTPUTS_DIR/fps}"

# Writes all the btc headers.
$CWD/write-upgrade-btc-headers.sh

$CWD/write-upgrade-btc-staking-params.sh
$CWD/write-upgrade-tokens-distribution.sh
