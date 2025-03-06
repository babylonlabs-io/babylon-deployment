#!/bin/bash -eu

# USAGE:
# ./setup-covenant-signer.sh

# it setups the covenant signer init files for single node chain

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../../..}"
COVENANT_SIGNER_BIN="${COVENANT_SIGNER_BIN:-$BBN_DEPLOYMENTS/covenant-emulator/build/covenant-signer}"

CHAIN_ID="${CHAIN_ID:-test-1}"
DATA_DIR="${DATA_DIR:-$CWD/../data}"
COVENANT_SIGNER_HOME="${COVENANT_SIGNER_HOME:-$DATA_DIR/covenant-signer}"
COVD_KEY_NAME="${COVD_KEY_NAME:-"covenant"}"
COVD_KEY_DIRECTORY="${COVD_KEY_DIRECTORY:-$DATA_DIR/covd}"
CLEANUP="${CLEANUP:-1}"
CREATE_KEYS="${CREATE_KEYS:-1}"

. $CWD/../helpers.sh
checkCovenantSigner
checkJq
COVENANT_SIGNER_BIN=$COVENANT_SIGNER_BIN checkCovd
cleanUp $CLEANUP $COVENANT_SIGNER_HOME/*.pid $COVENANT_SIGNER_HOME

cfg="$COVENANT_SIGNER_HOME/config.toml"

$COVENANT_SIGNER_BIN dump-cfg --config $cfg

perl -i -pe 's|chain-id = ""|chain-id = "'$CHAIN_ID'"|g' $cfg
perl -i -pe 's|key-name = ""|key-name = "'$COVD_KEY_NAME'"|g' $cfg
perl -i -pe 's|keyring-backend = ""|keyring-backend = "test"|g' $cfg
perl -i -pe 's|key-directory = ""|key-directory = "'$COVD_KEY_DIRECTORY'"|g' $cfg
