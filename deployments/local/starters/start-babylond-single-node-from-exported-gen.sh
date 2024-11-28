#!/bin/bash -eux

# USAGE:
# ./single-node-from-exported-gen.sh <option of full path to babylond>

# Starts an babylon chain getting the data from an exported genesis.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

NODE_BIN="${1:-$CWD/../../babylon/build/babylond}"

CHAIN_ID="${CHAIN_ID:-test-2}"
DATA_DIR="${DATA_DIR:-$CWD/../data}"
CHAIN_DIR="${CHAIN_DIR:-$DATA_DIR/babylon}"

EXPORTED_GEN_FILE="${EXPORTED_GEN_FILE:-$CHAIN_DIR/test-1/n0/config/genesis.exported.json}"

echo "--- Chain ID = $CHAIN_ID"
echo "--- Chain Dir = $DATA_DIR"

. $CWD/../helpers.sh $NODE_BIN

checkBabylond
checkJq

hdir="$CHAIN_DIR/$CHAIN_ID"

# Folder for node
n0dir="$hdir/n0"

# Home flag for folder
home0="--home $n0dir"
n0cfgDir="$n0dir/config"

# Process id of node 0
n0pid="$hdir/n0.pid"

CHAIN_ID=$CHAIN_ID CHAIN_DIR=$CHAIN_DIR $CWD/setup-babylond-single-node.sh

newGen=$n0cfgDir/genesis.json
tmpGen=$n0cfgDir/tmp_genesis.json
inputFile=$n0cfgDir/input.json

# TODO: create func
# Replaces values in genesis
cat $EXPORTED_GEN_FILE | jq .app_state.btclightclient.btc_headers > $inputFile
jq '.app_state.btclightclient.btc_headers = input' $newGen $inputFile > $tmpGen
mv $tmpGen $newGen

cat $EXPORTED_GEN_FILE | jq .app_state.btcstaking.finality_providers > $inputFile
jq '.app_state.btcstaking.finality_providers = input' $newGen $inputFile > $tmpGen
mv $tmpGen $newGen

cat $EXPORTED_GEN_FILE | jq .app_state.btcstaking.btc_delegations > $inputFile
jq '.app_state.btcstaking.btc_delegations = input' $newGen $inputFile > $tmpGen
mv $tmpGen $newGen

cat $EXPORTED_GEN_FILE | jq .app_state.btcstaking.params > $inputFile
jq '.app_state.btcstaking.params = input' $newGen $inputFile > $tmpGen
mv $tmpGen $newGen

# start the node with the modified genesis
CHAIN_ID=$CHAIN_ID CHAIN_DIR=$CHAIN_DIR $CWD/start-babylond-single-node.sh
