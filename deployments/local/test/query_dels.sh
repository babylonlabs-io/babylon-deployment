#!/bin/bash -eu

# USAGE:
# ./query_dels.sh <option of full path to babylond>

# From a already running chain queries the delegations

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

NODE_BIN="${1:-/Users/rafilx/projects/github.com/babylonlabs-io/babylon/build/babylond}"

CHAIN_ID="${CHAIN_ID:-test-1}"
DATA_DIR="${DATA_DIR:-$CWD/../data}"
CHAIN_DIR="${CHAIN_DIR:-$DATA_DIR/babylon}"
DENOM="${DENOM:-ubbn}"
BTC_BASE_HEADER_FILE="${BTC_BASE_HEADER_FILE:-""}"
COVENANT_PK_FILE="${COVENANT_PK_FILE:-""}"
COVENANT_QUORUM="${COVENANT_QUORUM:-3}"
SETUP="${SETUP:-1}"

# Folder for node
NODE_DIR="${NODE_DIR:-$CHAIN_DIR/$CHAIN_ID/n0}"
NODE_LOG_PATH="${NODE_LOG_PATH:-$NODE_DIR/start.log}"

. $CWD/../helpers.sh $NODE_BIN
checkBabylond

echo "--- Chain ID = $CHAIN_ID"
echo "--- Chain Dir = $CHAIN_DIR"
echo "--- Coin Denom = $DENOM"
VAL0_KEY="val"

hdir="$CHAIN_DIR/$CHAIN_ID"
# Home flag for folder
home0="--home $NODE_DIR"

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

USER_KEY="user"

# nodeNum=$(ls $n0dir/keyring-test/ | wc -l | jq -r)
# vestName="vestingtest$nodeNum"
# $NODE_BIN keys add $vestName $kbt $home0

# vestAddr=$($NODE_BIN $home0 keys show $vestName -a $kbt)

# currentTime=$(date +%s)
# new_timestamp=$((currentTime + 36000000))

# if it sends a tx it fails
# $NODE_BIN tx bank send val $vestAddr 20ubbn --from val $kbt $cid $home0 --yes --fees 10000ubbn
# raw_log: 'failed to execute message; message index: 0: account bbn1ag8rmewtyaglnucz9gygv4rktl077k6fdevl74
#   already exists: invalid request'
# sleep 10




first=$($NODE_BIN q btcstaking btc-delegations active -o json --limit 10000 | jq)
nextKey=$(echo $first | jq -r .pagination.next_key)
oldLen=$(echo $first | jq '.btc_delegations | length')
newLen=$(($oldLen-$oldLen))

echo "old len" $oldLen
echo "new len" $newLen
echo "start while"
while [ "$oldLen" -ne "$newLen" ];  do
  oldLen=$(($newLen))
  rest=$($NODE_BIN q btcstaking btc-delegations active -o json --page-key $nextKey --limit 10000 | jq)
  nextKey=$(echo $rest | jq -r .pagination.next_key)
  count=$(echo $rest | jq '.btc_delegations | length')

  newLen=$(($count + $oldLen))
  echo "count" $count
  echo "old len" $oldLen
  echo "new len" $newLen
done

  echo "old len" $oldLen
  echo "new len" $newLen