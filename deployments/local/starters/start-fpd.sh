#!/bin/bash -eux

# USAGE:
# ./start-fpd.sh

# it starts the finality provider for single node chain and validator
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
SETUP="${SETUP:-1}"
KILL_FIRST="${KILL_FIRST:-0}"
REGISTER="${REGISTER:-1}"

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


if [[ "$SETUP" == 1 || "$SETUP" == "1" ]]; then
  FPD_HOME=$FPD_HOME CLEANUP=$CLEANUP CHAIN_ID=$CHAIN_ID CHAIN_DIR=$CHAIN_DIR $CWD/setup-fpd.sh
fi

checkFpd

if [[ "$KILL_FIRST" == 1 || "$KILL_FIRST" == "1" ]]; then
  PATH_OF_PIDS=$FPD_HOME/*.pid $STOP/kill-process.sh
fi

logNum=$(ls $logdir/ | wc -l)

# Starts the finality provider daemon
$FPD_BIN start --rpc-listener $listenAddr $homeF > $logdir/fpd-start-$logNum.log 2>&1 &
echo $! > $FPD_HOME/fpd.pid
sleep 2

if [[ "$REGISTER" == 1 || "$REGISTER" == "1" ]]; then
  eotsPk=$(cat $EOTS_HOME/out/keys-add-eots-key.json | jq -r '.pubkey_hex' )

  # Transfer funds to the fp acc created
  fpBbnAddr=$($BBN_BIN $homeF keys show $fpKeyName -a $kbt)
  $BBN_BIN tx bank send user $fpBbnAddr 100000000ubbn $homeN0 $kbt $cid $gasp -y

  waitForOneBlock

  # Creates the finality provider and stores it into the database and eots
  createFPFileIn=$outdir/create-finality-provider-in.json

  echo "{
    \"keyName\": \"$fpKeyName\",
    \"chainID\": \"$CHAIN_ID\",
    \"passphrase\": \"\",
    \"commissionRate\": \"0.05\",
    \"commissionMaxRate\": \"0.09\",
    \"commissionMaxChangeRate\": \"0.01\",
    \"moniker\": \"fpd-monikey\",
    \"identity\": \"\",
    \"website\": \"\",
    \"securityContract\": \"\",
    \"details\": \"\",
    \"eotsPK\": \"$eotsPk\"
  }" > $createFPFileIn

  createFPFileOut=$outdir/create-finality-provider-out.json
  $FPD_BIN create-finality-provider --from-file $createFPFileIn $dAddr > $createFPFileOut
fi

