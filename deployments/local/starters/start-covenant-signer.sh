#!/bin/bash -eux

# USAGE:
# ./start-covenant-signer.sh

# it starts the covenant signer and creates the key with bitcoin

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../../..}"
COVENANT_SIGNER_BIN="${COVENANT_SIGNER_BIN:-$BBN_DEPLOYMENTS/covenant-signer/build/covenant-signer}"

DATA_DIR="${DATA_DIR:-$CWD/../data}"
COVENANT_SIGNER_HOME="${COVENANT_SIGNER_HOME:-$DATA_DIR/covenant-signer}"
GLOBAL_PARAMS_PATH="${GLOBAL_PARAMS_PATH:-$COVENANT_SIGNER_HOME/global-params.json}"
SETUP="${SETUP:-1}"
CLEANUP="${CLEANUP:-1}"

. $CWD/../helpers.sh
checkCovenantSigner

if [[ "$SETUP" == 1 || "$SETUP" == "1" ]]; then
  CLEANUP=$CLEANUP $CWD/setup-covenant-signer.sh
fi

pidPath=$COVENANT_SIGNER_HOME/pid
logsdir="$COVENANT_SIGNER_HOME/logs"
mkdir -p $pidPath
mkdir -p $logsdir

configPath="$COVENANT_SIGNER_HOME/config.toml"
covenantSignerWalletName="covenant-signer"

$COVENANT_SIGNER_BIN start --config $configPath --params $GLOBAL_PARAMS_PATH > $logsdir/daemon.log 2>&1 &
echo $! > $pidPath/$covenantSignerWalletName.pid
sleep 2 # waits for the daemon to load.
