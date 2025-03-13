#!/bin/bash -eux


CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"
UPGRADES="${UPGRADES:-$CWD/../upgrades}"

$CWD/../bbn-start-and-add-btc-delegation.sh

# upgrade babylon