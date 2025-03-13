#!/bin/bash -eux

# USAGE:
# ./setup-fpd.sh

# it setups the finality provider for single node chain and validator
CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../../..}"

FPD_BUILD="${FPD_BUILD:-$BBN_DEPLOYMENTS/finality-provider/build}"
FPD_BIN="${FPD_BIN:-$FPD_BUILD/fpd}"
STOP="${STOP:-$CWD/../stop}"

BABYLOND_DIR="${BABYLOND_DIR:-$BBN_DEPLOYMENTS/babylon}"
BBN_BIN="${BBN_BIN:-$BABYLOND_DIR/build/babylond}"

CHAIN_ID="${CHAIN_ID:-test-1}"
DATA_DIR="${DATA_DIR:-$CWD/../data}"
CHAIN_DIR="${CHAIN_DIR:-$DATA_DIR/babylon}"
FPD_HOME="${FPD_HOME:-$DATA_DIR/fpd/fp-0}"
EOTS_HOME="${EOTS_HOME:-$DATA_DIR/eots}"
CLEANUP="${CLEANUP:-1}"

n0dir="$DATA_DIR/$CHAIN_ID/n0"
listenAddr="127.0.0.1:12583"

homeF="--home $FPD_HOME"
cid="--chain-id $CHAIN_ID"
dAddr="--daemon-address $listenAddr"
cfg="$FPD_HOME/fpd.conf"
outdir="$FPD_HOME/out"
logdir="$FPD_HOME/logs"
fpKeyName="keys-finality-provider"

# babylon node Home flag for folder
n0dir="$CHAIN_DIR/$CHAIN_ID/n0"
homeN0="--home $n0dir"
kbt="--keyring-backend test"
gasp="--gas-prices 1ubbn"

. $CWD/../helpers.sh

if [[ "$CLEANUP" == 1 || "$CLEANUP" == "1" ]]; then
  PATH_OF_PIDS=$FPD_HOME/*.pid $STOP/kill-process.sh

  rm -rf $FPD_HOME
  echo "Removed $FPD_HOME"
fi

checkFpd

mkdir -p $outdir
mkdir -p $logdir

# Creates and modifies config
$FPD_BIN init $homeF --force

perl -i -pe 's|DBPath = '$HOME'/.fpd/data|DBPath = "'$FPD_HOME/data'"|g' $cfg
perl -i -pe 's|ChainID = chain-test|ChainID = "'$CHAIN_ID'"|g' $cfg
perl -i -pe 's|BitcoinNetwork = signet|BitcoinNetwork = regtest|g' $cfg
perl -i -pe 's|Port = 2112|Port = 2734|g' $cfg
perl -i -pe 's|RPCListener = 127.0.0.1:12581|RPCListener = "'$listenAddr'"|g' $cfg
perl -i -pe 's|Key = finality-provider|Key = "'$fpKeyName'"|g' $cfg
perl -i -pe 's|RandomnessCommitInterval = 30s|RandomnessCommitInterval = 5s|g' $cfg
perl -i -pe 's|TimestampingDelayBlocks = 6000|TimestampingDelayBlocks = 3|g' $cfg

# Adds new key for the finality provider
$FPD_BIN keys add $fpKeyName $homeF $kbt > $outdir/keys-add-keys-finality-provider.txt
