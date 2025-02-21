#!/bin/bash -eux

# USAGE:
# ./start-covenant-signer.sh

# it starts the covenant signer for single node chain

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../../..}"
COVENANT_SIGNER_BIN="${COVENANT_SIGNER_BIN:-$BBN_DEPLOYMENTS/covenant-emulator/build/covenant-signer}"

DATA_DIR="${DATA_DIR:-$CWD/../data}"
COVENANT_SIGNER_HOME="${COVENANT_SIGNER_HOME:-$DATA_DIR/covenant-signer}"

CLEANUP="${CLEANUP:-1}"
SETUP="${SETUP:-1}"

. $CWD/../helpers.sh
checkCovenantSigner

homeF="--home $COVENANT_SIGNER_HOME"
confF="--config $COVENANT_SIGNER_HOME/config.toml"

cleanUp $CLEANUP $COVENANT_SIGNER_HOME/*.pid $COVENANT_SIGNER_HOME

if [[ "$SETUP" == 1 || "$SETUP" == "1" ]]; then
  $CWD/setup-covenant-signer.sh
fi

# Start Covenant signer
$COVENANT_SIGNER_BIN start $confF > $COVENANT_SIGNER_HOME/covenant-signer-start.log 2>&1 &
echo $! > $COVENANT_SIGNER_HOME/covenant-signer.pid

sleep 1

curl -X POST http://127.0.0.1:9791/v1/unlock -d '{"passphrase": ""}'
