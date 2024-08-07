#!/bin/bash -eu

# USAGE:
# ./setup-staking-indexer.sh

# it setups the staking indexer init config to connect to bitcoind regtest

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../../..}"
SID_BIN="${SID_BIN:-$BBN_DEPLOYMENTS/staking-indexer/build/sid}"
STOP="${STOP:-$CWD/../stop}"

CHAIN_ID="${CHAIN_ID:-test-1}"
CHAIN_DIR="${CHAIN_DIR:-$CWD/../data}"
SID_HOME="${SID_HOME:-$CHAIN_DIR/staking-indexer}"
CLEANUP="${CLEANUP:-1}"

if [ ! -f $SID_BIN ]; then
  echo "$SID_BIN does not exists. build it first with $~ make"
  exit 1
fi

homeF="--home $SID_HOME"

cfg="$SID_HOME/sid.conf"

if [[ "$CLEANUP" == 1 || "$CLEANUP" == "1" ]]; then
  PATH_OF_PIDS=$SID_HOME/*.pid $STOP/kill-process.sh

  rm -rf $SID_HOME
  echo "Removed $SID_HOME"
fi

$SID_BIN init $homeF

# [Application Options]
perl -i -pe 's|BitcoinNetwork = signet|BitcoinNetwork = regtest|g' $cfg

# [btcconfig]
perl -i -pe 's|RPCHost = 127.0.0.1:38332|RPCHost = 127.0.0.1:19001|g' $cfg
perl -i -pe 's|RPCUser = user|RPCUser = rpcuser|g' $cfg
perl -i -pe 's|RPCPass = pass|RPCPass = rpcpass|g' $cfg
