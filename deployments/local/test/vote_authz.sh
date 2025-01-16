#!/bin/bash -eux

# USAGE:
# ./vote_authz.sh <option of full path to babylond>

# From a already running chain creates a new proposal to vote and
# uses another account to vote on behalf of you

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

NODE_BIN="${1:-$CWD/../../../babylon/build/babylond}"

CHAIN_ID="${CHAIN_ID:-test-1}"
DATA_DIR="${DATA_DIR:-$CWD/../data}"
CHAIN_DIR="${CHAIN_DIR:-$DATA_DIR/babylon}"
SOFTWARE_UPGRADE_FILE="${SOFTWARE_UPGRADE_FILE:-$CWD/../upgrades/props/v1.json}"
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
accVoterWithStakerFunds="voter$nodeNum"

$NODE_BIN keys add $accStaker $kbt $home0
$NODE_BIN keys add $accVoterWithStakerFunds $kbt $home0

stakerAddr=$($NODE_BIN $home0 keys show $accStaker -a $kbt)
voterWithStakerFundsAddr=$($NODE_BIN $home0 keys show $accVoterWithStakerFunds -a $kbt)

amountBbn="10000000ubbn"

$NODE_BIN $home0 tx bank send $USER_KEY $stakerAddr $amountBbn $kbt $cid $gasp $home0 -y
$NODE_BIN $home0 tx bank send $VAL0_KEY $voterWithStakerFundsAddr "200000ubbn" $kbt $cid $gasp $home0 -y

waitForOneBlock

$NODE_BIN tx gov submit-proposal $SOFTWARE_UPGRADE_FILE $home0 --from $USER_KEY $kbt $cid $gasp --yes --output json

waitForOneBlock

proposals=$($NODE_BIN q gov proposals -o json | jq)
# echo "proposals" $(echo $proposals | jq)

propID=$(echo $proposals | jq -r '.proposals[-1].id')
echo "Prop ID: $propID"

echo "Generates the vote transaction from " $accStaker

outVoteTx=$($NODE_BIN tx gov vote $propID yes --from $accStaker $kbt $cid $gasp $home0 -y --generate-only)

outputVoteTxFile=$outdir/generated-vote-$accStaker.json

echo $outVoteTx > $outputVoteTxFile
echo "Out voting transaction" $outVoteTx

$NODE_BIN tx authz grant $voterWithStakerFundsAddr "generic" --msg-type "/cosmos.gov.v1.MsgVote" --from $accStaker $kbt $cid $gasp $home0 -y

waitForOneBlock

$NODE_BIN tx authz exec $outputVoteTxFile --from $accVoterWithStakerFunds $kbt $cid $gasp $home0 -y

$NODE_BIN tx gov vote $propID yes --from $VAL0_KEY $kbt $cid $gasp $home0 -y

waitForOneBlock

$NODE_BIN q gov votes $propID -o json | jq
