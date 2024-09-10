#!/bin/bash -eu

# USAGE:
# ./write-upgrades-data.sh

# Calls both btc headers and signed finality providers script to write
# the upgrade data.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

$CWD/write-upgrade-btc-headers.sh
$CWD/write-upgrade-signed-fps.sh
