#!/bin/bash -eux

# USAGE:
# ./btc-staker-start-and-stake.sh

# Starts an btc staker and sends stake tx to btc.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../../..}"

BTC_STAKER_BUILD="${BTC_STAKER_BUILD:-$BBN_DEPLOYMENTS/btc-staker/build}"
STAKERCLI_BIN="${STAKERCLI_BIN:-$BTC_STAKER_BUILD/stakercli}"

DATA_DIR="${DATA_DIR:-$CWD/../data}"
BTC_HOME="${BTC_HOME:-$DATA_DIR/bitcoind}"
BTC_STAKER_HOME="${BTC_STAKER_HOME:-$DATA_DIR/btc-staker}"
CLEANUP="${CLEANUP:-1}"

. $CWD/../helpers.sh

checkStakercli
checkStakerd
checkBitcoind

stakercliDirHome=$BTC_STAKER_HOME/stakecli
stakercliOutputDir=$stakercliDirHome/output

btcWalletNameWithFunds="btcWalletName"
DATA_DIR=$DATA_DIR BTC_STAKER_HOME=$BTC_STAKER_HOME CLEANUP=$CLEANUP BTC_WALLET_NAME=$btcWalletNameWithFunds $CWD/setup-btc-staker.sh
DATA_DIR=$DATA_DIR BTC_STAKER_HOME=$BTC_STAKER_HOME CLEANUP=0 $CWD/start-btc-staker.sh

mkdir -p $stakercliOutputDir

finalityProviderBTCPubKey=$($STAKERCLI_BIN daemon babylon-finality-providers | jq .finality_providers[0].bitcoin_public_Key -r)
echo $finalityProviderBTCPubKey > $stakercliOutputDir/fpbtc.pub.key

stakerBTCAddrListOutput=$($STAKERCLI_BIN daemon list-outputs | jq .outputs[-1].address -r)
echo $stakerBTCAddrListOutput > $stakercliOutputDir/list.output.last.addr

# Creates the btc delegation
$STAKERCLI_BIN daemon stake --staker-address $stakerBTCAddrListOutput --staking-amount 1000000 \
  --finality-providers-pks $finalityProviderBTCPubKey --staking-time 10000 > $stakercliOutputDir/btc-staking-tx.json

# Generate a few blocks to confirm the tx.
flagDataDir="-datadir=$BTC_HOME"
flagRpc="-rpcwallet=$btcWalletNameWithFunds"

bitcoin-cli $flagDataDir $flagRpc -generate 40
