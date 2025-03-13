#!/bin/bash -eux

# USAGE:
# ./vesting-periodic.sh <option of full path to babylond>

# From a already running chain creates a new vesting account with
# staking delegation

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

NODE_BIN="${1:-$CWD/../../../babylon/build/babylond}"

CHAIN_ID="${CHAIN_ID:-test-1}"
DATA_DIR="${DATA_DIR:-$CWD/../data}"
CHAIN_DIR="${CHAIN_DIR:-$DATA_DIR/babylon}"

. $CWD/../helpers.sh $NODE_BIN
checkBabylond

echo "--- Chain ID = $CHAIN_ID"
echo "--- Chain Dir = $CHAIN_DIR"
VAL0_KEY="val"

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
fees="--fees 10000ubbn"
gasp="--gas-prices 1ubbn"

USER_KEY="user"

. $CWD/../helpers.sh $NODE_BIN

nodeNum=$(ls $n0dir/keyring-test/ | wc -l | jq -r)
vestName="vestingtest$nodeNum"
$NODE_BIN keys add $vestName $kbt $home0

vestAddr=$($NODE_BIN $home0 keys show $vestName -a $kbt)

currentTime=$(date +%s)
one_year=36000000
ten_min=600
new_timestamp=$((currentTime + $ten_min))

periodicVestingFile=$CWD/props/periodic-vesting.json

echo "vesting spendable balances"
$NODE_BIN q bank spendable-balances $vestAddr --output json | jq

jq '.start_time='$new_timestamp'' \
  $periodicVestingFile > $periodicVestingFile.temp && mv $periodicVestingFile.temp $periodicVestingFile


$NODE_BIN tx vesting create-periodic-vesting-account $vestAddr $periodicVestingFile --from $USER_KEY --fees 400000ubbn $kbt $cid $home0 --yes

waitForOneBlock

VAL0_ADDR=$($NODE_BIN $home0 keys show $VAL0_KEY -a $kbt --bech val)
valAddr=$($NODE_BIN $home0 keys show $VAL0_KEY -a $kbt)

echo "valAddr" $valAddr ", VAL0_ADDR" $VAL0_ADDR

$NODE_BIN q bank spendable-balances $vestAddr --output json | jq

echo "valAddr" $valAddr " is giving a fee grant to vestAddr " $vestAddr

$NODE_BIN tx feegrant grant $valAddr $vestAddr $kbt $cid $home0 $gasp --from val --yes


waitForOneBlock

$NODE_BIN tx epoching delegate $VAL0_ADDR 10ubbn $kbt $cid $home0 --from $vestAddr --yes $fees --fee-granter $valAddr

$NODE_BIN q bank spendable-balances $vestAddr --output json | jq

$NODE_BIN q staking delegations $vestAddr --output json | jq

waitForBlocks 3

# $NODE_BIN q bank spendable-balances $vestAddr --output json | jq

$NODE_BIN q staking delegations $vestAddr --output json | jq

# sleep 6

# $NODE_BIN tx bank send $vestAddr $valAddr 500000ubbn $kbt $cid $home0 --yes $fees --fee-granter $valAddr
