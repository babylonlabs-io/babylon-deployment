#!/bin/bash -eu

# USAGE:
# ./btc-staker-start-and-stake.sh

# Starts an btc staker and sends stake tx to btc.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../../..}"

BTC_STAKER_BUILD="${BTC_STAKER_BUILD:-$BBN_DEPLOYMENTS/btc-staker/build}"
STAKERCLI_BIN="${STAKERCLI_BIN:-$BTC_STAKER_BUILD/stakercli}"

DATA_DIR="${DATA_DIR:-$CWD/../data}"
CHAIN_DIR="${CHAIN_DIR:-$DATA_DIR/babylon}"
CHAIN_ID="${CHAIN_ID:-test-1}"
BTC_STAKER_HOME="${BTC_STAKER_HOME:-$DATA_DIR/btc-staker}"
BTC_WALLET_NAME="${BTC_WALLET_NAME:-"btc-staker"}"
KEYRING_BACKEND="${KEYRING_BACKEND:-"test"}"
CLEANUP="${CLEANUP:-1}"

pidPath=$BTC_STAKER_HOME/pid

. $CWD/../helpers.sh

checkStakercli
cleanUp $CLEANUP $pidPath/*.pid  $BTC_STAKER_HOME

stakercliDirHome=$BTC_STAKER_HOME/stakecli
stakercliConfigFile=$stakercliDirHome/config.conf
stakercliDataDir=$stakercliDirHome/data
stakercliLogsDir=$stakercliDirHome/logs
stakercliDBDir=$stakercliDirHome/db

BTC_STAKER_KEY="btc-staker"

n0dir="$CHAIN_DIR/$CHAIN_ID/n0"

mkdir -p $stakercliLogsDir

$STAKERCLI_BIN admin dump-config --config-file-dir $stakercliConfigFile

#[Application Options]
perl -i -pe 's|StakerdDir = '$HOME'/.stakerd|StakerdDir = "'$stakercliDirHome'"|g' $stakercliConfigFile
perl -i -pe 's|ConfigFile = '$HOME'/.stakerd/stakerd.conf|ConfigFile = "'$stakercliConfigFile'"|g' $stakercliConfigFile
perl -i -pe 's|DataDir = '$HOME'/.stakerd/data|DataDir = "'$stakercliDataDir'"|g' $stakercliConfigFile
perl -i -pe 's|LogDir = '$HOME'/.stakerd/logs|LogDir = "'$stakercliLogsDir'"|g' $stakercliConfigFile
#[walletconfig]
perl -i -pe 's|WalletName = wallet|WalletName = "'$BTC_WALLET_NAME'"|g' $stakercliConfigFile
#[btcnodebackend]
perl -i -pe 's|Nodetype = btcd|Nodetype = bitcoind|g' $stakercliConfigFile
perl -i -pe 's|WalletType = btcwallet|WalletType = bitcoind|g' $stakercliConfigFile
#[walletconfig]
# perl -i -pe 's|WalletPass = walletpass|WalletPass =|g' $stakercliConfigFile
#[walletrpcconfig]
perl -i -pe 's|Host = localhost:18556|Host = 127.0.0.1:19001|g' $stakercliConfigFile
# perl -i -pe 's|DisableTls = true|DisableTls = false|g' $stakercliConfigFile
# perl -i -pe 's|RPCWalletCert =|RPCWalletCert = "'$btcWalletRpcCert'"|g' $stakercliConfigFile
# perl -i -pe 's|RawRPCWalletCert = "'$btcWalletRpcCert'"|RawRPCWalletCert =|g' $stakercliConfigFile
#[chain]
perl -i -pe 's|Network = testnet|Network = regtest|g' $stakercliConfigFile
#[btcd]
perl -i -pe 's|RPCHost = 127.0.0.1:18334|RPCHost = 127.0.0.1:18556|g' $stakercliConfigFile
perl -i -pe 's|RPCUser = user|RPCUser = rpcuser|g' $stakercliConfigFile
perl -i -pe 's|RPCPass = pass|RPCPass = rpcpass|g' $stakercliConfigFile
#[bitcoind]
perl -i -pe 's|RPCHost = 127.0.0.1:8334|RPCHost = 127.0.0.1:19001|g' $stakercliConfigFile
# perl -i -pe 's|RPCCert = '$HOME'/.btcd/rpc.cert|RPCCert = "'$btcRpcCert'"|g' $stakercliConfigFile
#[babylon]
perl -i -pe 's|Key = node0|Key = "'$BTC_STAKER_KEY'"|g' $stakercliConfigFile
perl -i -pe 's|ChainID = chain-test|ChainID = "'$CHAIN_ID'"|g' $stakercliConfigFile
perl -i -pe 's|KeyDirectory = '$HOME'/.stakerd|KeyDirectory = "'$n0dir'"|g' $stakercliConfigFile
perl -i -pe 's|KeyringBackend = file|KeyringBackend = '$KEYRING_BACKEND'|g' $stakercliConfigFile
#[dbconfig]
perl -i -pe 's|DBPath = '$HOME'/.stakerd/data|DBPath = "'$stakercliDBDir'"|g' $stakercliConfigFile
#[stakerconfig]
perl -i -pe 's|BabylonStallingInterval = 1m0s|BabylonStallingInterval = 40s|g' $stakercliConfigFile
