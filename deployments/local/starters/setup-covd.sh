#!/bin/bash -eux

# USAGE:
# ./setup-covd.sh

# it setups the covenant init files for single node chain

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../../..}"
COVD_BIN="${COVD_BIN:-$BBN_DEPLOYMENTS/covenant-emulator/build/covd}"
STOP="${STOP:-$CWD/../stop}"

CHAIN_ID="${CHAIN_ID:-test-1}"
DATA_DIR="${DATA_DIR:-$CWD/../data}"
COVD_HOME="${COVD_HOME:-$DATA_DIR/covd}"
CLEANUP="${CLEANUP:-1}"

if ! command -v jq &> /dev/null
then
  echo "⚠️ jq command could not be found!"
  echo "Install it by checking https://stedolan.github.io/jq/download/"
  exit 1
fi

if [ ! -f $COVD_BIN ]; then
  echo "$COVD_BIN does not exists. build it first with $~ make"
  exit 1
fi

homeF="--home $COVD_HOME"
keyName="covenant"

cfg="$COVD_HOME/covd.conf"
covdPubFile=$COVD_HOME/keyring-test/$keyName.pubkey.json
covdPKs=$COVD_HOME/pks.json

if [[ "$CLEANUP" == 1 || "$CLEANUP" == "1" ]]; then
  PATH_OF_PIDS=$COVD_HOME/*.pid $STOP/kill-process.sh

  rm -rf $COVD_HOME
  echo "Removed $COVD_HOME"
fi

$COVD_BIN init $homeF

perl -i -pe 's|ChainID = chain-test|ChainID = "'$CHAIN_ID'"|g' $cfg
perl -i -pe 's|Key = covenant-key|Key = "'$keyName'"|g' $cfg
perl -i -pe 's|Port = 2112|Port = 2115|g' $cfg # any other available port.

covenantPubKey=$($COVD_BIN create-key --key-name $keyName --chain-id $CHAIN_ID $homeF | jq -r)
echo $covenantPubKey > $covdPubFile

# pub-key, jq does not like -
convenantPk=$(cat $covdPubFile | jq .[] | jq --slurp '.[1]')
echo "[$convenantPk]" > $covdPKs