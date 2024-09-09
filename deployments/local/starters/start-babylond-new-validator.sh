#!/bin/bash -euxx

# USAGE:
# ./start-babylond-new-validator.sh <option of full path to babylond>

# Creates a new node with a brand new validator with an chain that it is already
# running.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

NODE_BIN="${1:-$CWD/../../../babylon/build/babylond}"
STOP="${STOP:-$CWD/../stop}"

CHAIN_ID="${CHAIN_ID:-test-1}"
DATA_DIR="${DATA_DIR:-$CWD/../data}"

LOG_LEVEL="${LOG_LEVEL:-info}"
SCALE_FACTOR="${SCALE_FACTOR:-000000}"

hdir="$DATA_DIR/$CHAIN_ID"

nodeNum=$(ls $hdir/ | wc -l)

# Default 1 account keys + 1 user key with no special grants
VAL_KEY="val$nodeNum"
VAL_MNEMONIC=$(babylond keys mnemonic)

USER_KEY="user$nodeNum"
USER_MNEMONIC=$(babylond keys mnemonic)

NEWLINE=$'\n'


if ! command -v jq &> /dev/null
then
  echo "⚠️ jq command could not be found!"
  echo "Install it by checking https://stedolan.github.io/jq/download/"
  exit 1
fi

echo "--- Chain ID = $CHAIN_ID"
echo "--- Chain Dir = $DATA_DIR"
echo "--- Coin Denom = $DENOM"

if [ ! -f $NODE_BIN ]; then
  echo "$NODE_BIN does not exists. build it first with $~ make"
  exit 1
fi

# Folder for node
nodeDir="$hdir/n$nodeNum"

# Home flag for folder
home="--home $nodeDir"

# Config directories for node
cfgDir="$nodeDir/config"

# Config files for nodes
cfg="$cfgDir/config.toml"

# App config file for node
app="$cfgDir/app.toml"

# Process id of node 0
pid="$nodeDir/pid"

# Folder for node
n0dir="$hdir/n0"

# Home flag for folder
home0="--home $n0dir"

# Common flags
kbt="--keyring-backend test"
cid="--chain-id $CHAIN_ID"

$NODE_BIN $home $cid init n$nodeNum &>/dev/null

# copy genesis from node zero
echo "--- Copy genesis from previous node..."
cp $hdir/n0/config/genesis.json $cfgDir/genesis.json


echo "--- Validating genesis..."
$NODE_BIN $home validate-genesis

# This is needed to avoid using same ports for each node

nodeNumTimesTen=$(($nodeNum * 10))
nodeNumTimes100=$(($nodeNum * 100))

portNumber=$((26657 + $nodeNumTimesTen))
portNumberPlus=$(($portNumber + 1))

proffAddrPort=$((6060 + $nodeNum))

apiAddr=$((1317 + $nodeNumTimes100))

echo "--- Modifying config..."

# Use perl for cross-platform compatibility
# Example usage: perl -i -pe 's/^param = ".*?"/param = "100"/' config.toml
perl -i -pe 's|addr_book_strict = true|addr_book_strict = false|g' $cfg
perl -i -pe 's|external_address = ""|external_address = "tcp://127.0.0.1:'$portNumber'"|g' $cfg
perl -i -pe 's|"tcp://127.0.0.1:26657"|"tcp://0.0.0.0:'$portNumber'"|g' $cfg
perl -i -pe 's|"tcp://0.0.0.0:26656"|"tcp://0.0.0.0:'$portNumberPlus'"|g' $cfg
perl -i -pe 's|"localhost:6060"|"localhost:'$proffAddrPort'"|g' $cfg
perl -i -pe 's|allow_duplicate_ip = false|allow_duplicate_ip = true|g' $cfg
perl -i -pe 's|log_level = "info"|log_level = "'$LOG_LEVEL'"|g' $cfg
perl -i -pe 's|timeout_commit = ".*?"|timeout_commit = "5s"|g' $cfg

perl -i -pe 's|"tcp://0.0.0.0:1317"|"tcp://0.0.0.0:'$apiAddr'"|g' $app
perl -i -pe 's|"0.0.0.0:9090"|"0.0.0.0:909'$nodeNum'"|g' $app
perl -i -pe 's|minimum-gas-prices = ""|minimum-gas-prices = "0.05uquid"|g' $app

echo "--- Importing keys..."
echo "$VAL_MNEMONIC$NEWLINE"
yes "$VAL_MNEMONIC$NEWLINE" | $NODE_BIN $home keys add $VAL_KEY $kbt --recover
yes "$USER_MNEMONIC$NEWLINE" | $NODE_BIN $home keys add $USER_KEY $kbt --recover

echo "--- Modifying app..."
perl -i -pe 's|minimum-gas-prices = ""|minimum-gas-prices = "0.05uquid"|g' $app

peer0="$($NODE_BIN tendermint show-node-id $home0 --log_level info)\@127.0.0.1:26656"
perl -i -pe 's|persistent_peers = ""|persistent_peers = "'$peer0'"|g' $cfg

log_path=$hdir.n$nodeNum.log

$NODE_BIN $home start --api.enable true --grpc.address="0.0.0.0:909$nodeNum" --grpc-web.enable=false --log_level trace --trace > $log_path 2>&1 &

# Gets the node pid
echo $! > $pid

# Start the instance
echo "--- Starting node..."

# Adds 5 sec to create the log and makes it easier to debug it on CI

sleep 5
cat $log_path

echo "Creating a new validator from CLI"

echo "Sending funds from n0 to n$nodeNum"

newValAddr=$($NODE_BIN keys show $VAL_KEY $home $kbt -a)

$NODE_BIN tx bank send user $newValAddr 10000$SCALE_FACTOR$DENOM  $kbt $home0 $cid -y -b sync

pubkey=$($NODE_BIN tendermint show-validator $home)

commission="--commission-max-change-rate=0.01 --commission-max-rate=1.0 --commission-rate=0.07 --min-self-delegation 10"
$NODE_BIN tx stakegauge create-validator $kbt $home $cid -y --from $VAL_KEY --amount 1000$SCALE_FACTOR$DENOM --pubkey $pubkey $commission -b sync

echo
echo "Logs:"
echo "  * tail -f $log_path"
echo
echo "Env for easy access:"
echo "export H1='--home $nodeDir'"
echo
echo "Command Line Access:"
echo "  * $NODE_BIN --home $nodeDir status"