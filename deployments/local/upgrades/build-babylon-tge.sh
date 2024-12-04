#!/bin/bash -eu

# USAGE:
# ./build-babylon-tge

# builds the babylond at the tge version

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BABYLON_PATH="${BABYLON_PATH:-$CWD/../../../babylon}"
NODE_BIN="${1:-$BABYLON_PATH/build/babylond}"
TGE_VERSION="${TGE_VERSION:-v0.9.1}"
PRE_BUILD_SCRIPT="${PRE_BUILD_SCRIPT:-""}"

STOP="${STOP:-$CWD/../stop}"
STARTERS="${STARTERS:-$CWD/../starters}"

CHAIN_ID="${CHAIN_ID:-test-1}"
DATA_DIR="${DATA_DIR:-$CWD/../data}"
CHAIN_DIR="${CHAIN_DIR:-$DATA_DIR/babylon}"

# Load funcs, cheks babylond exists
. $CWD/../helpers.sh $NODE_BIN

# Build babylond at version $TGE_VERSION
cd $BABYLON_PATH

oldBabylonBranch=$(git branch --show-current)
git checkout $TGE_VERSION

if [ ${#PRE_BUILD_SCRIPT} -gt 1 ]; then
  echo "$PRE_BUILD_SCRIPT is set, runnig script"
  bash $PRE_BUILD_SCRIPT
fi

make build