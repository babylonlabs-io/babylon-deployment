#!/bin/bash -eux

# USAGE:
# ./write-upgrades-data.sh

# Calls both btc headers and signed finality providers script to write
# the upgrade data.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
DATA_DIR="${DATA_DIR:-$CWD/../data}"
OUTPUTS_DIR="${OUTPUTS_DIR:-$DATA_DIR/outputs}"
SIGNED_FPD_MSGS_PATH="${SIGNED_FPD_MSGS_PATH:-$OUTPUTS_DIR/fps}"

# Writes all the btc headers.
$CWD/write-upgrade-btc-headers.sh

# All the fpd signed messages should be created prior to the upgrade and just pass to the write upgrades
SIGNED_MSGS_PATH=$SIGNED_FPD_MSGS_PATH $CWD/write-upgrade-signed-fps.sh

$CWD/write-upgrade-btc-staking-params.sh
$CWD/write-upgrade-tokens-distribution.sh
