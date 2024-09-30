#!/bin/bash -eu

# USAGE:
# ./start-babylond-new-validator.sh <option of full path to babylond>

# Creates a new node with a brand new validator with an chain that it is already
# running.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

NODE_BIN="${1:-$CWD/../../../babylon/build/babylond}"
STOP="${STOP:-$CWD/../stop}"

CHAIN_ID="${CHAIN_ID:-test-1}"
DATA_DIR="${DATA_DIR:-$CWD/../data}"
CHAIN_DIR="${CHAIN_DIR:-$DATA_DIR/babylon}"

DENOM="${DENOM:-ubbn}"
LOG_LEVEL="${LOG_LEVEL:-info}"
SCALE_FACTOR="${SCALE_FACTOR:-000000}"

. $CWD/../helpers.sh $NODE_BIN

checkBabylond
checkJq

hdir="$CHAIN_DIR/$CHAIN_ID"

nodeNum=$(ls $hdir/ | wc -l)

# Default 1 account keys + 1 user key with no special grants
VAL_KEY="val$nodeNum"
VAL_MNEMONIC=$(babylond keys mnemonic)

USER_KEY="user$nodeNum"
USER_MNEMONIC=$(babylond keys mnemonic)

NEWLINE=$'\n'

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

# TODO: Verify why our genesis is invalid - https://github.com/babylonlabs-io/babylon/issues/63
# echo "--- Validating genesis..."
# $NODE_BIN $home validate-genesis

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

echo "--- Modifying app..."
perl -i -pe 's|"tcp://0.0.0.0:1317"|"tcp://0.0.0.0:'$apiAddr'"|g' $app
perl -i -pe 's|"0.0.0.0:9090"|"0.0.0.0:909'$nodeNum'"|g' $app
perl -i -pe 's|minimum-gas-prices = ""|minimum-gas-prices = "1'$DENOM'"|g' $app

echo "--- Importing keys..."
echo "$VAL_MNEMONIC$NEWLINE"
yes "$VAL_MNEMONIC$NEWLINE" | $NODE_BIN $home keys add $VAL_KEY $kbt --recover
yes "$USER_MNEMONIC$NEWLINE" | $NODE_BIN $home keys add $USER_KEY $kbt --recover

$NODE_BIN $home create-bls-key $($NODE_BIN $home keys show $VAL_KEY -a $kbt)

peer0="$($NODE_BIN tendermint show-node-id $home0 --log_level info)\@127.0.0.1:26656"
perl -i -pe 's|persistent_peers = ""|persistent_peers = "'$peer0'"|g' $cfg

SETUP=0 NODE_DIR=$nodeDir $CWD/start-babylond-single-node.sh $NODE_BIN

sleep 5
echo "Creating a new validator from CLI"
echo "Sending funds from n0 to n$nodeNum"

newValAddr=$($NODE_BIN keys show $VAL_KEY $home $kbt -a)

$NODE_BIN tx bank send user $newValAddr 10000$SCALE_FACTOR$DENOM $kbt $home0 $cid -y -b sync > /tmp/dev

sleep 6 # wait for a block

pubkey=$($NODE_BIN tendermint show-validator $home)

createValJSON=$nodeDir/create-val-params.json

echo "{
  \"pubkey\": $pubkey,
  \"amount\": \"100000000$DENOM\",
  \"moniker\": \"$VAL_KEY\",
  \"identity\": \"optional identity signature (ex. UPort or Keybase)\",
  \"website\": \"validator (optional) website\",
  \"security\": \"validator (optional) security contact email\",
  \"details\": \"validator (optional) details\",
  \"commission-rate\": \"0.1\",
  \"commission-max-rate\": \"0.2\",
  \"commission-max-change-rate\": \"0.01\",
  \"min-self-delegation\": \"10\"
}" | jq > $createValJSON

$NODE_BIN tx checkpointing create-validator $createValJSON $kbt $home $cid -y --from $VAL_KEY -b sync > /tmp/dev

echo "$VAL_KEY created, wait for the end of epoch to changes to take effect"
