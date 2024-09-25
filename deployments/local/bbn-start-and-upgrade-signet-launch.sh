#!/bin/bash -eux

# USAGE:
# ./bbn-start-and-upgrade-signet-launch.sh

# Runs the signet launch upgrade '-'
# It adds new btc headers to the running chain

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"

NODE_BIN="${1:-$CWD/../../babylon/build/babylond}"

STARTERS="${STARTERS:-$CWD/starters}"
UPGRADES="${UPGRADES:-$CWD/upgrades}"

DATA_DIR="${DATA_DIR:-$CWD/data}"
DATA_OUTPUTS="${DATA_OUTPUTS:-$DATA_DIR/outputs}"
BTC_BASE_HEADER_FILE="${BTC_BASE_HEADER_FILE:-$DATA_OUTPUTS/btc-base-header.json}"
CHAIN_DIR="${CHAIN_DIR:-$DATA_DIR/babylon}"
NUMBER_FPS_SIGNED="${NUMBER_FPS_SIGNED:-1}"
CHAIN_ID="${CHAIN_ID:-test-1}"
OUTPUTS_DIR="${OUTPUTS_DIR:-$DATA_DIR/outputs}"

fpdOut=$OUTPUTS_DIR/fps
n0dir="$CHAIN_DIR/$CHAIN_ID/n0"
cid="--chain-id $CHAIN_ID"
kbt="--keyring-backend test"

. $CWD/helpers.sh $NODE_BIN
mkdir -p $DATA_OUTPUTS
mkdir -p $fpdOut
mkdir -p $DATA_DIR/fpd

# Start bitcoind
$STARTERS/start-bitcoind.sh
sleep 2

# Setup covd without start to get the covenant pub key to btc staking before babylon chain launches
$STARTERS/setup-covd.sh

# Creates all the finality providers signed msgs and concatenate
for i in $(seq 1 $NUMBER_FPS_SIGNED); do
  fpNum=$(ls $DATA_DIR/fpd/ | wc -l)
  echo "creating fp number $fpNum"
  OUTPUT_SIGNED_MSG=$fpdOut/fp-$fpNum-signed-create-msg.json $UPGRADES/fpd-create-signed-fp.sh
done

# Creates a BTC delegation tx in bitcoin without babylon
$UPGRADES/btcstaker-create-btc-delegation.sh

# writes block zero from BTC to babylon
writeBaseBtcHeaderFile $BTC_BASE_HEADER_FILE

# Setup and start single node with base btc header set
BTC_BASE_HEADER_FILE=$BTC_BASE_HEADER_FILE $STARTERS/start-babylond-single-node.sh

# wait for a block
sleep 6


# Send funds to new finality providers after the upgrade (it could be before as well)
fpNum=0
for fpHomePath in $DATA_DIR/fpd/*; do
  echo "sending bbn to fpd $fpNum"
  fpName="fp-name-$fpNum"

  fpAddr=$($NODE_BIN keys show $fpName --home $fpHomePath $kbt -a)
  # Send some funds to finality provider for him to be able to perform actions.
  $NODE_BIN tx bank send user $fpAddr 1000000ubbn --home $n0dir $kbt $cid -y -b sync > /tmp/dev
  fpNum=$(($fpNum + 1))
done

# Setups the staking indexer to write the btc headers into babylond upgrades
$STARTERS/setup-staking-indexer.sh

# collect info to check after upgrade
btcHeaderTipBeforeUpgrade=$($NODE_BIN q btclightclient tip -o json | jq .header.height -r)
fpsLengthBeforeUpgrade=$($NODE_BIN q btcstaking finality-providers --output json | jq '.finality_providers | length')

# Gov prop, waits for block, kill and reestart in the new version
SIGNED_FPD_MSGS_PATH=$fpdOut PRE_BUILD_UPGRADE_SCRIPT=$UPGRADES/write-upgrades-data.sh SOFTWARE_UPGRADE_FILE=$UPGRADES/props/signet-launch.json \
  BABYLON_VERSION_WITH_UPGRADE="main" $UPGRADES/upgrade-single-node.sh

# realize all checks, like if all the btc headers and fps were added '-'
upgradeHeight=$($NODE_BIN q upgrade applied signet-launch --output json | jq ".height" -r)
btcHeaderTipAfterUpgrade=$($NODE_BIN q btclightclient tip -o json | jq .header.height -r)
fpsLengthAfterUpgrade=$($NODE_BIN q btcstaking finality-providers --output json | jq '.finality_providers | length')

if ! [[ $btcHeaderTipAfterUpgrade -gt $btcHeaderTipBeforeUpgrade ]]; then
  echo "Upgrade should have applied a bunch of btc headers"
  exit 1
fi
if ! [[ $fpsLengthAfterUpgrade -gt $fpsLengthBeforeUpgrade ]]; then
  echo "Upgrade should have applied a bunch of finality providers"
  exit 1
fi

echo "Signet launch upgrade was correctly executed at block height " $upgradeHeight
echo "the last btc header height is" $btcHeaderTipAfterUpgrade
echo "the number of finality providers increased from" $fpsLengthBeforeUpgrade " to " $fpsLengthAfterUpgrade

# After upgrade is done, sends BTC delegation to babylond with inclusion proof
# babylond tx btcstaking create-btc-delegation [btc_pk] [pop_hex] [staking_tx_info] [fp_pk] [staking_time] [staking_value] \
# [slashing_tx] [delegator_slashing_sig] \
# [unbonding_tx] [unbonding_slashing_tx] [unbonding_time] [unbonding_value] [delegator_unbonding_slashing_sig] [flags]