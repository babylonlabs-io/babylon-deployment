#!/bin/bash -eu

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
CREATE_KEYS="${CREATE_KEYS:-1}"

. $CWD/../helpers.sh
checkJq
COVD_BIN=$COVD_BIN checkCovd
cleanUp $CLEANUP $COVD_HOME/*.pid $COVD_HOME

homeF="--home $COVD_HOME"
keyName="covenant"

cfg="$COVD_HOME/covd.conf"

$COVD_BIN init $homeF

perl -i -pe 's|ChainID = chain-test|ChainID = "'$CHAIN_ID'"|g' $cfg
perl -i -pe 's|Key = covenant-key|Key = "'$keyName'"|g' $cfg
perl -i -pe 's|GasPrices = 0.01ubbn|GasPrices = 1ubbn|g' $cfg
perl -i -pe 's|GasAdjustment = 1.2|GasAdjustment = 2|g' $cfg
perl -i -pe 's|Port = 2112|Port = 2115|g' $cfg # any other available port.

if [[ "$CREATE_KEYS" == 1 || "$CREATE_KEYS" == "1" ]]; then
  covdPubFile=$COVD_HOME/keyring-test/$keyName.pubkey.json
  covdPKs=$COVD_HOME/pks.json

  covenantPubKey=$($COVD_BIN create-key --key-name $keyName --chain-id $CHAIN_ID $homeF | jq -r)
  echo $covenantPubKey > $covdPubFile

  convenantPk=$(cat $covdPubFile | jq .[] | jq --slurp '.[1]')
  echo "[$convenantPk]" > $covdPKs
fi
