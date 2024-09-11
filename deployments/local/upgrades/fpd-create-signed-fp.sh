#!/bin/bash -eux

# USAGE:
# ./fpd-create-signed-fp.sh

# Creates a signed finality provider MsgCreateFinalityProvider.
CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../../..}"

FPD_BUILD="${FPD_BUILD:-$BBN_DEPLOYMENTS/finality-provider/build}"
EOTS_BIN="${EOTS_BIN:-$FPD_BUILD/eotsd}"
FPD_BIN="${FPD_BIN:-$FPD_BUILD/fpd}"
CLEANUP="${CLEANUP:-1}"
START="${START:-1}" # defines if it should start the eotsd and fpd process
CHAIN_ID="${CHAIN_ID:-test-1}"

DATA_DIR="${DATA_DIR:-$CWD/../data}"
nodeNum=$(ls $DATA_DIR/fpd/ | wc -l)

FPD_HOME="${FPD_HOME:-$DATA_DIR/fpd/fp-$nodeNum}"
EOTS_HOME="${EOTS_HOME:-$FPD_HOME/eotsd}"

homeF="--home $FPD_HOME"
eotsdHomeF="--home $EOTS_HOME"
fpName="fp-name-$nodeNum"

outdir="$FPD_HOME/out"
OUTPUT_SIGNED_MSG="${OUTPUT_SIGNED_MSG:-$outdir/msg-signed.json}"

kbt="--keyring-backend test"
eotsdKeyF="--key-name $fpName"

. $CWD/../helpers.sh

checkFpd
cleanUp $CLEANUP $FPD_HOME/*.pid $FPD_HOME

mkdir -p $outdir

# Adds new key for the finality provider
$FPD_BIN keys add $fpName $homeF $kbt > $outdir/keys-add-keys-finality-provider.txt
fpAddr=$($FPD_BIN keys show $fpName $homeF $kbt -a)

echo "new FP addr:" $fpAddr

# Creates eotsd keys, update the config and generates PoP
eotsdCfg="$EOTS_HOME/eotsd.conf"
$EOTS_BIN init $eotsdHomeF
metricsPort=$((2113 + $nodeNum))
rpcListenerPort=$((12582 + $nodeNum))

perl -i -pe 's|Port = 2113|Port = '$metricsPort'|g' $eotsdCfg
perl -i -pe 's|RpcListener = 127.0.0.1:12582|RpcListener = 127.0.0.1:'$rpcListenerPort'|g' $eotsdCfg

$EOTS_BIN keys add $eotsdHomeF $kbt $eotsdKeyF > $outdir/keys-add-keys-eotsd.txt

popOut=$outdir/pop-export.json
$EOTS_BIN pop-export $fpAddr $eotsdHomeF $kbt $eotsdKeyF --output json > $popOut

btcPKHex=$(cat $popOut | jq '.pub_key_hex' -r)
popHex=$(cat $popOut | jq '.pop_hex' -r)

outputCreatedMsgPath="$outdir/msg-unsigned.json"
$FPD_BIN tx create-finality-provider $btcPKHex $popHex \
  $homeF $kbt --from $fpName --chain-id $CHAIN_ID \
  --generate-only --gas-prices 10ubbn --moniker nick-$fpName --security-contact $fpName@email.com \
  --website http://$fpName.com.br --details "best-$fpName" --commission-rate "0.05" --output json | jq > $outputCreatedMsgPath

$FPD_BIN tx sign $outputCreatedMsgPath $homeF $kbt \
  --from $fpName --offline --account-number 0 --sequence 0 | jq > $OUTPUT_SIGNED_MSG


if [[ "$START" == 1 || "$START" == "1" ]]; then
  $EOTS_BIN start $eotsdHomeF >> $EOTS_HOME/eots-start.log &
  echo $! > $EOTS_HOME/eots.pid
fi