#!/bin/bash -eu

# USAGE:
# ./start-bitcoind.sh

# Starts an bitcoind BTC regtest chain with address and blocks

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# These options can be overridden by env
CHAIN_DIR="${CHAIN_DIR:-$CWD/../data}"
BTC_HOME="${BTC_HOME:-$CHAIN_DIR/bitcoind}"
CLEANUP="${CLEANUP:-1}"
STOP="${STOP:-$CWD/../stop}"

echo "--- Chain Dir = $CHAIN_DIR"
echo "--- BTC HOME = $BTC_HOME"

if [[ "$CLEANUP" == 1 || "$CLEANUP" == "1" ]]; then
  PATH_OF_PIDS=$BTC_HOME/pid/*.pid $STOP/kill-process.sh
  sleep 3 # takes some time to kill the process and start again...

  rm -rf $BTC_HOME
  echo "Removed $BTC_HOME"
fi

btcpidPath="$BTC_HOME/pid"
bitcoindpid="$btcpidPath/bitcoind.pid"
genblockspid="$btcpidPath/genblocks.pid"

configPath=$BTC_HOME/bitcoin.conf
btcLogs="$BTC_HOME/logs"

mkdir -p $BTC_HOME
mkdir -p $btcLogs
mkdir -p $btcpidPath


# Write the config file
echo "
# testnet-box functionality
regtest=1
dnsseed=0
upnp=0

# always run a server, even with bitcoin-qt
server=1

[regtest]
# listen on different ports than default testnet
port=19000
rpcport=19001

zmqpubrawtx=tcp://127.0.0.1:28332
zmqpubrawtxlock=tcp://127.0.0.1:28332
zmqpubhashblock=tcp://127.0.0.1:28332
zmqpubrawblock=tcp://127.0.0.1:28332

deprecatedrpc=create_bdb
fallbackfee=0.01
# enable SSL for RPC server
#rpcssl=1

# enable to allow non-localhost RPC connections
# recommended to change to a subnet, such as your LAN
#rpcallowip=0.0.0.0/0
#rpcallowip=::/0

rpcuser=rpcuser
rpcpassword=rpcpass
" > $configPath

if ! command -v bitcoind &> /dev/null
then
  echo "⚠️ bitcoind command could not be found!"
  echo "Install it by checking https://bitcoin.org/en/full-node"
  exit 1
fi


if ! command -v jq &> /dev/null
then
  echo "⚠️ jq command could not be found!"
  echo "Install it by checking https://stedolan.github.io/jq/download/"
  exit 1
fi


walletName="btcWalletName"
flagDataDir="-datadir=$BTC_HOME"
flagRpc="-rpcwallet=$walletName"

gen_blocks () {
  echo "1 block generated each 8s"

  while true; do
    bitcoin-cli $flagDataDir $flagRpc -generate 1 > /dev/null 2>&1
    sleep 8
  done
}


bitcoind $flagDataDir > $btcLogs/bitcoind-start.log 2>&1 &
echo $! > $bitcoindpid

sleep 1

bitcoin-cli $flagDataDir -named createwallet wallet_name=$walletName passphrase=walletpass

bitcoin-cli $flagDataDir $flagRpc -generate 200

# keeps mining 1 block each 8 sec.
gen_blocks &
echo $! > $genblockspid