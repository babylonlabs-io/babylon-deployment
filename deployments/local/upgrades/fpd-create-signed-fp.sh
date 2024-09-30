#!/bin/bash -eu

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
logdir="$FPD_HOME/logs"
OUTPUT_SIGNED_MSG="${OUTPUT_SIGNED_MSG:-$outdir/msg-signed.json}"

cid="--chain-id $CHAIN_ID"
kbt="--keyring-backend test"
gasp="--gas-prices 1ubbn"
keyNameF="--key-name $fpName"

. $CWD/../helpers.sh

checkFpd
cleanUp $CLEANUP $FPD_HOME/*.pid $FPD_HOME

mkdir -p $outdir
mkdir -p $logdir

# Adds new key for the finality provider
$FPD_BIN keys add $fpName $homeF $kbt > $outdir/keys-add-keys-finality-provider.txt
fpAddr=$($FPD_BIN keys show $fpName $homeF $kbt -a)

echo "new FP addr:" $fpAddr

# Creates eotsd keys, update the config and generates PoP
eotsdCfg="$EOTS_HOME/eotsd.conf"
$EOTS_BIN init $eotsdHomeF
metricsPort=$((2113 + $nodeNum))
eotsdRpcListenerPort=$((12582 + $nodeNum))
eotsdRpcListenerAddr=127.0.0.1:$eotsdRpcListenerPort

perl -i -pe 's|Port = 2113|Port = '$metricsPort'|g' $eotsdCfg
perl -i -pe 's|RpcListener = 127.0.0.1:12582|RpcListener = '$eotsdRpcListenerAddr'|g' $eotsdCfg

$EOTS_BIN keys add $eotsdHomeF $kbt $keyNameF > $outdir/keys-add-keys-eotsd.txt

popOut=$outdir/pop-export.json
$EOTS_BIN pop-export $fpAddr $eotsdHomeF $kbt $keyNameF --output json > $popOut

btcPKHex=$(cat $popOut | jq '.pub_key_hex' -r)
popHex=$(cat $popOut | jq '.pop_hex' -r)

outputCreatedMsgPath="$outdir/msg-unsigned.json"
moniker="nick-$fpName"
$FPD_BIN tx create-finality-provider $btcPKHex $popHex \
  $homeF $kbt --from $fpName --chain-id $CHAIN_ID \
  --generate-only $gasp --moniker $moniker --security-contact $fpName@email.com \
  --website http://$fpName.com.br --details "best-$fpName" --commission-rate "0.05" --output json | jq > $outputCreatedMsgPath

echo "Generated file " $outputCreatedMsgPath

$FPD_BIN tx sign $outputCreatedMsgPath $homeF $kbt --from $fpName --offline --account-number 0 --sequence 0 | jq > $OUTPUT_SIGNED_MSG

if [[ "$START" == 1 || "$START" == "1" ]]; then
  echo "starting the finality provider"
  $EOTS_BIN start $eotsdHomeF >> $EOTS_HOME/eots-start.log &
  echo $! > $EOTS_HOME/eots.pid

  # only creates and modify config if starts to demonstrate it can be done
  # after the keys creation
  $FPD_BIN init $homeF --force # creates the fpd config

  # update the config as needed
  fpdCfg="$FPD_HOME/fpd.conf"
  metricsPort=$((2132 + $nodeNum))

  fpdListenPort=$((12783 + $nodeNum))
  fpdListenAddr="127.0.0.1:$fpdListenPort"

  perl -i -pe 's|DBPath = '$HOME'/.fpd/data|DBPath = "'$FPD_HOME/data'"|g' $fpdCfg
  perl -i -pe 's|ChainID = chain-test|ChainID = "'$CHAIN_ID'"|g' $fpdCfg
  perl -i -pe 's|GasPrices = 0.002ubbn|GasPrices = 1ubbn|g' $fpdCfg
  perl -i -pe 's|Key = finality-provider|Key = '$fpName'|g' $fpdCfg
  perl -i -pe 's|BitcoinNetwork = signet|BitcoinNetwork = simnet|g' $fpdCfg
  perl -i -pe 's|LogLevel = info|LogLevel = debug|g' $fpdCfg
  perl -i -pe 's|Port = 2112|Port = '$metricsPort'|g' $fpdCfg
  perl -i -pe 's|RpcListener = 127.0.0.1:12581|RpcListener = '$fpdListenAddr'|g' $fpdCfg
  perl -i -pe 's|EOTSManagerAddress = 127.0.0.1:12582|EOTSManagerAddress = '$eotsdRpcListenerAddr'|g' $fpdCfg

  $FPD_BIN start --rpc-listener $fpdListenAddr $homeF > $logdir/fpd-start.log 2>&1 &
  echo $! > $FPD_HOME/fpd.pid
  sleep 5 # wait a few secs to setup and starts to listen

  createFPFile=$outdir/create-finality-provider.json
  $FPD_BIN create-finality-provider --eots-pk $btcPKHex $keyNameF $cid $homeF \
    --daemon-address $fpdListenAddr --moniker $moniker > $createFPFile
fi