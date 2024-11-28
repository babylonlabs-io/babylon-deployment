#!/bin/bash -eux

# USAGE:
# ./fpd-register-finality-provider.sh

# Register a new finality provider using the fpd.
CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../../..}"

FPD_BUILD="${FPD_BUILD:-$BBN_DEPLOYMENTS/finality-provider/build}"
FPD_BIN="${FPD_BIN:-$FPD_BUILD/fpd}"
NODE_NUM="${NODE_NUM:-0}"
DATA_DIR="${DATA_DIR:-$CWD/../data}"
FPD_HOME="${FPD_HOME:-$DATA_DIR/fpd/fp-$NODE_NUM}"

outdir="$FPD_HOME/out"

keysOut=$outdir/eotsd-keys-add.json
defaultPkHex=$(cat $keysOut | jq '.pubkey_hex' -r)
EOTS_PK_HEX="${EOTS_PK_HEX:-$defaultPkHex}"

homeF="--home $FPD_HOME"

. $CWD/../helpers.sh
checkFpd

mkdir -p $outdir

fpdListenPort=$((12783 + $NODE_NUM))
fpdListenAddr="127.0.0.1:$fpdListenPort"

registerFPFile=$outdir/fpd-register-finality-provider.json
$FPD_BIN register-finality-provider $EOTS_PK_HEX $homeF --daemon-address $fpdListenAddr > $registerFPFile