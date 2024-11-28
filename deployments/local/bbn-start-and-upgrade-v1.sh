#!/bin/bash -eux

# USAGE:
# ./bbn-start-and-upgrade-v1.sh

# Runs the v1 upgrade '-'
# It adds new btc headers, fps to the running chain

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"

NODE_BIN="${1:-$CWD/../../babylon/build/babylond}"

STARTERS="${STARTERS:-$CWD/starters}"
UPGRADES="${UPGRADES:-$CWD/upgrades}"

DATA_DIR="${DATA_DIR:-$CWD/data}"
DATA_OUTPUTS="${DATA_OUTPUTS:-$DATA_DIR/outputs}"
BTC_BASE_HEADER_FILE="${BTC_BASE_HEADER_FILE:-$DATA_OUTPUTS/btc-base-header.json}"
CHAIN_DIR="${CHAIN_DIR:-$DATA_DIR/babylon}"
NUMBER_FPS="${NUMBER_FPS:-1}"
CHAIN_ID="${CHAIN_ID:-test-1}"
OUTPUTS_DIR="${OUTPUTS_DIR:-$DATA_DIR/outputs}"

fpdOut=$OUTPUTS_DIR/fps
n0dir="$CHAIN_DIR/$CHAIN_ID/n0"
cid="--chain-id $CHAIN_ID"
kbt="--keyring-backend test"
gasp="--gas-prices 1ubbn"

. $CWD/helpers.sh $NODE_BIN
mkdir -p $DATA_OUTPUTS
mkdir -p $fpdOut
mkdir -p $DATA_DIR/fpd

# Start bitcoind
$STARTERS/start-bitcoind.sh
sleep 2

# Setup covd without start to get the covenant pub key to btc staking before babylon chain launches
$STARTERS/setup-covd.sh

# Creates all the finality providers signed msgs and concatenatek
for i in $(seq 1 $NUMBER_FPS); do
  fpNum=$(ls $DATA_DIR/fpd/ | wc -l)
  echo "creating fp number $fpNum"
  $UPGRADES/fpd-eots-create-keys.sh
done

# Setups the conveant signer that generates the pub key for covenant_pks in global params
$STARTERS/setup-covenant-signer.sh

# Writes the global params
$UPGRADES/write-global-params.sh

# With the global params written, starts the covenant-signer
GLOBAL_PARAMS_PATH=$DATA_OUTPUTS/global_params.json CLEANUP=0 SETUP=0 $STARTERS/start-covenant-signer.sh

# Creates a BTC delegation tx in bitcoin without babylon
$UPGRADES/btcstaker-create-btc-delegation-global-params.sh

# writes block zero from BTC to babylon
writeBaseBtcHeaderFile $BTC_BASE_HEADER_FILE

# Builds babylond at tge version
$UPGRADES/build-babylon-tge.sh

# Setup and start single node with base btc header set
BTC_BASE_HEADER_FILE=$BTC_BASE_HEADER_FILE IS_TGE=1 $STARTERS/start-babylond-single-node.sh

# wait for a block
sleep 6

# Send funds to new finality providers before the upgrade
fpNum=0
for fpHomePath in $DATA_DIR/fpd/*; do
  echo "sending bbn to fpd $fpNum"
  fpName="fp-name-$fpNum"

  fpAddr=$($NODE_BIN keys show $fpName --home $fpHomePath $kbt -a)
  # Send some funds to finality provider for him to be able to perform actions.
  $NODE_BIN tx bank send user $fpAddr 1000000ubbn --home $n0dir $kbt $cid -y -b sync $gasp > /tmp/dev
  fpNum=$(($fpNum + 1))
done

# Setups the staking indexer to write the btc headers into babylond upgrades
$STARTERS/setup-staking-indexer.sh

# Migrate covenant-signer to covenant-emulator https://babylonlabs.atlassian.net/wiki/spaces/BABYLON/pages/82182253/Covenant+Keys+Transitions+from+Phase-1+to+phase-2+WIP
# and pass correct covenant pub key to the write of upgrade data.


# collect info to check after upgrade
btcHeaderTipBeforeUpgrade=$($NODE_BIN q btclightclient tip -o json | jq .header.height -r)
fpsLengthBeforeUpgrade=$($NODE_BIN q btcstaking finality-providers --output json | jq '.finality_providers | length')

# Gov prop, waits for block, kill and reestart in the new version
SIGNED_FPD_MSGS_PATH=$fpdOut PRE_BUILD_UPGRADE_SCRIPT=$UPGRADES/write-upgrades-data.sh SOFTWARE_UPGRADE_FILE=$UPGRADES/props/v1.json \
  BABYLON_VERSION_WITH_UPGRADE="main" $UPGRADES/upgrade-single-node.sh

# realize all checks, like if all the btc headers and fps were added '-'
upgradeHeight=$($NODE_BIN q upgrade applied v1 --output json | jq ".height" -r)
btcHeaderTipAfterUpgrade=$($NODE_BIN q btclightclient tip -o json | jq .header.height -r)


if ! [[ $btcHeaderTipAfterUpgrade -gt $btcHeaderTipBeforeUpgrade ]]; then
  echo "Upgrade should have applied a bunch of btc headers"
  exit 1
fi

echo "V1 upgrade was correctly executed at block height " $upgradeHeight
echo "the last btc header height is" $btcHeaderTipAfterUpgrade

# Register finality providers into babylon
fpNodeNum=0
for fpHomePath in $DATA_DIR/fpd/*; do
  echo "creating FP $fpNodeNum"
  NODE_NUM=$fpNodeNum $UPGRADES/fpd-register-finality-provider.sh
  fpNodeNum=$(($fpNodeNum + 1))
done

sleep 6 # waits for one block

fpsAfterCreation=$($NODE_BIN q btcstaking finality-providers --output json | jq '.finality_providers | length')
if ! [[ $fpsAfterCreation -gt $fpsLengthBeforeUpgrade ]]; then
  echo "Upgrade should have applied a bunch of finality providers"
  exit 1
fi

echo "the number of finality providers should have increased from" $fpsLengthBeforeUpgrade " to " $fpsAfterCreation
# The finality provider will not send finality votes until the finality.params.finality_activation_height is reached

# After upgrade is done, sends BTC delegation to babylond with inclusion proof
# Start btc-staker

CLEANUP=0 $STARTERS/setup-btc-staker.sh
CLEANUP=0 $STARTERS/start-btc-staker.sh

# babylond tx btcstaking create-btc-delegation [btc_pk] [pop_hex] [staking_tx_info] [fp_pk] [staking_time] [staking_value] \
# [slashing_tx] [delegator_slashing_sig] \
# [unbonding_tx] [unbonding_slashing_tx] [unbonding_time] [unbonding_value] [delegator_unbonding_slashing_sig] [flags]
