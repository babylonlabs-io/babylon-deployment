#!/bin/bash -eu

# USAGE:
# ./gov-prop-software-upgrade.sh <option of full path to babylond>

# Creates an gov prop to software upgrade and votes YES from validator.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

NODE_BIN="${1:-$CWD/../../../babylon/build/babylond}"
SOFTWARE_UPGRADE_FILE="${SOFTWARE_UPGRADE_FILE:-$CWD/props/signet-launch.json}"
STOP="${STOP:-$CWD/../stop}"

CHAIN_ID="${CHAIN_ID:-test-1}"
DATA_DIR="${DATA_DIR:-$CWD/../data}"
CHAIN_DIR="${CHAIN_DIR:-$DATA_DIR/babylon}"

if [ ! -f $NODE_BIN ]; then
  echo "$NODE_BIN does not exists. build it first with $~ make"
  exit 1
fi

hdir="$CHAIN_DIR/$CHAIN_ID"

# Folder for node
n0dir="$hdir/n0"

# Home flag for folder
home0="--home $n0dir"

# Common flags
kbt="--keyring-backend test"
cid="--chain-id $CHAIN_ID"

VAL0_ADDR=$($NODE_BIN $home0 keys show val -a $kbt --bech val)

UPGRADE_BLOCK_HEIGHT=`$NODE_BIN status | jq ".sync_info.latest_block_height | tonumber | . + 6"`
echo "upgrade block height: $UPGRADE_BLOCK_HEIGHT"

echo "Send gov proposal to upgrade to '$SOFTWARE_UPGRADE_FILE'"

# Sets the height and proposer to msg
echo $(cat $SOFTWARE_UPGRADE_FILE | jq ".messages[0].plan.height = $UPGRADE_BLOCK_HEIGHT" $SOFTWARE_UPGRADE_FILE) > $SOFTWARE_UPGRADE_FILE
echo $(cat $SOFTWARE_UPGRADE_FILE | jq ".proposer = \"$VAL0_ADDR\"" $SOFTWARE_UPGRADE_FILE | jq) > $SOFTWARE_UPGRADE_FILE

govPropOut=$($NODE_BIN tx gov submit-proposal $SOFTWARE_UPGRADE_FILE $home0 --from val $kbt $cid --yes --output json --fees 1000ubbn)

# Debug
# echo $govPropOut
# txHash=$(echo $govPropOut | jq -r '.txhash')
# echo "txHash" $txHash

sleep 6 # waits for a block

propID=$($NODE_BIN q gov proposals -o json | jq -r '.proposals[-1].id')
echo "Prop ID: $propID"

$NODE_BIN tx gov vote $propID --from val $kbt yes $home0 $cid --yes

echo "..."
echo "Finish voting in the proposal"
echo "..."

