#!/bin/bash -eu

# USAGE:
# ./upgrade-single-node.sh $NODE_BIN

# Runs a gov prop update, voting and waits to reach the upgrade heigth
# kills the previous babylond pid, build the babylon at the expected version
# starts from the new one that has the new version.
# It also rollsback the git version to the previous one.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BABYLON_PATH="${BABYLON_PATH:-$CWD/../../../babylon}"
NODE_BIN="${1:-$BABYLON_PATH/build/babylond}"
BABYLON_VERSION_WITH_UPGRADE="${BABYLON_VERSION_WITH_UPGRADE:-main}"
PRE_BUILD_UPGRADE_SCRIPT="${PRE_BUILD_UPGRADE_SCRIPT:-""}"

SOFTWARE_UPGRADE_FILE="${SOFTWARE_UPGRADE_FILE:-$CWD/props/signet-launch.json}"
STOP="${STOP:-$CWD/../stop}"
STARTERS="${STARTERS:-$CWD/../starters}"

CHAIN_ID="${CHAIN_ID:-test-1}"
DATA_DIR="${DATA_DIR:-$CWD/../data}"
CHAIN_DIR="${CHAIN_DIR:-$DATA_DIR/babylon}"

# Load funcs, cheks babylond exists
. $CWD/../helpers.sh $NODE_BIN

hdir="$CHAIN_DIR/$CHAIN_ID"

# Folder for node
n0dir="$hdir/n0"

# Home flag for folder
home0="--home $n0dir"

# Process id of node 0
n0pid="$n0dir/*.pid"
log_path=$n0dir/start.v2.log

# Common flags
kbt="--keyring-backend test"
cid="--chain-id $CHAIN_ID"

echo "running gov prop for file" $SOFTWARE_UPGRADE_FILE
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

if [ ${#PRE_BUILD_UPGRADE_SCRIPT} -gt 1 ]; then
  echo "$PRE_BUILD_UPGRADE_SCRIPT is set, runnig script"
  bash $PRE_BUILD_UPGRADE_SCRIPT
fi

# build new version with upgrade 'e2e' build tag is necessary for now
BUILD_TAGS="e2e" make build

# go back to old path
cd -

# start the chain again
NODE_LOG_PATH=$log_path SETUP=0 $STARTERS/start-babylond-single-node.sh

# git checkout to previous version
cd $BABYLON_PATH
git stash
git checkout $oldBabylonBranch
cd -

# wait for upgrade to apply and start
sleep 10

upgradeApplied $SOFTWARE_UPGRADE_FILE