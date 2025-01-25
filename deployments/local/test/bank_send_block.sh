#!/bin/bash -eux

# USAGE:
# ./bank_send_block.sh <option of full path to babylond>

# From a already running chain creates a new proposal to block
# the send functionality of a coin

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

NODE_BIN="${1:-$CWD/../../../babylon/build/babylond}"

CHAIN_ID="${CHAIN_ID:-test-1}"
DATA_DIR="${DATA_DIR:-$CWD/../data}"
CHAIN_DIR="${CHAIN_DIR:-$DATA_DIR/babylon}"
PROP_FILE="${PROP_FILE:-$CWD/props/block-send-ubbn.json}"
outdir="$DATA_DIR/out"

. $CWD/../helpers.sh $NODE_BIN
checkBabylond

echo "--- Chain ID = $CHAIN_ID"
echo "--- Chain Dir = $CHAIN_DIR"
VAL0_KEY="val"
USER_KEY="user"

mkdir -p $outdir

hdir="$CHAIN_DIR/$CHAIN_ID"

# Folder for node
n0dir="$hdir/n0"

# Home flag for folder
home0="--home $n0dir"

# Config directories for node
n0cfgDir="$n0dir/config"

# Config files for nodes
n0cfg="$n0cfgDir/config.toml"

# App config file for node
n0app="$n0cfgDir/app.toml"

# Common flags
kbt="--keyring-backend test"
cid="--chain-id $CHAIN_ID"
gasp="--gas-prices 1ubbn"


nodeNum=$(ls $n0dir/keyring-test/ | wc -l | jq -r)
accStaker="accStaker$nodeNum"

$NODE_BIN keys add $accStaker $kbt $home0

stakerAddr=$($NODE_BIN $home0 keys show $accStaker -a $kbt)

amountBbn="10000000ubbn"

waitForOneBlock

# Here it verifies if the bank send works properly
$NODE_BIN $home0 tx bank send $VAL0_KEY $stakerAddr $amountBbn $kbt $cid $gasp $home0 -y

$NODE_BIN q bank send-enabled -o json | jq

waitForOneBlock

$NODE_BIN tx gov submit-proposal $PROP_FILE $home0 --from $USER_KEY $kbt $cid $gasp --yes --output json

waitForOneBlock

proposals=$($NODE_BIN q gov proposals -o json | jq)

propID=$(echo $proposals | jq -r '.proposals[-1].id')
echo "Prop ID: $propID"

echo "Generates the vote transaction from val and " $USER_KEY

$NODE_BIN tx gov vote $propID --from val $kbt yes $home0 $cid --yes $gasp
$NODE_BIN tx gov vote $propID --from $USER_KEY yes $home0 $kbt $cid $gasp --yes

waitForBlocks 5

$NODE_BIN q bank send-enabled -o json | jq

echo "balances " $stakerAddr " before failing tx bank send"

$NODE_BIN q bank balances $stakerAddr -o json | jq

# Should fail to send again
txHashFailedSend=$($NODE_BIN $home0 tx bank send $USER_KEY $stakerAddr $amountBbn $kbt $cid $gasp $home0 -y -o json | jq -r '.txhash')

waitForOneBlock

echo "balances " $stakerAddr " after failing tx bank send"

$NODE_BIN q bank balances $stakerAddr -o json | jq

$NODE_BIN q tx --type hash $txHashFailedSend -o json | jq '.raw_log'