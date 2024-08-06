#!/bin/bash -eu

# USAGE:
# ./upgrade-single-node.sh $NODE_BIN softwareUpgradeName

# Runs a gov prop update, voting and waits to reach the upgrade heigth
# kills the previous babylond pid, build the babylon at the expected version
# starts from the new one that has the new version.
# It also rollsback the git version to the previous one.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BABYLON_PATH="${BABYLON_PATH:-$CWD/../../../babylon}"
NODE_BIN="${1:-$BABYLON_PATH/build/babylond}"
BABYLON_VERSION_WITH_UPGRADE="${BABYLON_VERSION_WITH_UPGRADE:-dev}"

SOFTWARE_UPGRADE_FILE="${2:-$CWD/props/vanilla.json}"
STOP="${STOP:-$CWD/../stop}"
STARTERS="${STARTERS:-$CWD/../starters}"

CHAIN_ID="${CHAIN_ID:-test-1}"
CHAIN_DIR="${CHAIN_DIR:-$CWD/../data}"

# Load funcs
. $CWD/../helpers.sh $NODE_BIN

if [ ! -f $NODE_BIN ]; then
  echo "$NODE_BIN does not exists. build it first with $~ make"
  exit 1
fi

hdir="$CHAIN_DIR/$CHAIN_ID"

# Folder for node
n0dir="$hdir/n0"

# Home flag for folder
home0="--home $n0dir"

# Process id of node 0
n0pid="$hdir/n0.pid"
log_path=$hdir/n0.v2.log

# Common flags
kbt="--keyring-backend test"
cid="--chain-id $CHAIN_ID"

SOFTWARE_UPGRADE_FILE=$SOFTWARE_UPGRADE_FILE $CWD/gov-prop-software-upgrade.sh $NODE_BIN

UPGRADE_BLOCK_HEIGHT=$(cat "$SOFTWARE_UPGRADE_FILE" | jq ".messages[0].plan.height" -r)

echo "..."
echo "It will wait to reach the block height $UPGRADE_BLOCK_HEIGHT to upgrade"
echo "..."

waitForBlock $UPGRADE_BLOCK_HEIGHT

echo "Reached upgrade block height"
echo "Kill all the process '$NODE_BIN'"

PATH_OF_PIDS=$n0pid $STOP/kill-process.sh
sleep 5

# Rebuild babylond at version $BABYLON_VERSION_WITH_UPGRADE
cd $BABYLON_PATH

oldBabylonBranch=$(git branch --show-current)
git checkout $BABYLON_VERSION_WITH_UPGRADE

# build new version with upgrade 'e2e' build tag is necessary for now
BUILD_TAGS="e2e" make build

# go back to old path
cd -

# start the chain again
SETUP=0 $STARTERS/start-babylond-single-node.sh

# git checkout to previous version
cd $BABYLON_PATH
git checkout $oldBabylonBranch
cd -

# wait for upgrade to apply and start
sleep 10

upgradeApplied $SOFTWARE_UPGRADE_FILE