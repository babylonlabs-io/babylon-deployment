#!/bin/bash -eu

# USAGE:
# ./start-bitcoind.sh

# Starts an bitcoind BTC regtest chain with address and blocks

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# These options can be overridden by env
DATA_DIR="${DATA_DIR:-$CWD/../data}"
BTC_HOME="${BTC_HOME:-$DATA_DIR/bitcoind}"
CLEANUP="${CLEANUP:-1}"
STOP="${STOP:-$CWD/../stop}"

. $CWD/../helpers.sh
checkJq
checkBitcoind
cleanUp $CLEANUP $BTC_HOME/pid/*.pid $BTC_HOME

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

txindex=1

# enable to allow non-localhost RPC connections
# recommended to change to a subnet, such as your LAN
#rpcallowip=0.0.0.0/0
#rpcallowip=::/0

rpcuser=rpcuser
rpcpassword=rpcpass
" > $configPath

walletName="btcWalletName"
flagDataDir="-datadir=$BTC_HOME"
rpcWalletFlag="-rpcwallet=$walletName"


bitcoind $flagDataDir > $btcLogs/bitcoind-start.log 2>&1 &
echo $! > $bitcoindpid

sleep 1

bitcoin-cli $flagDataDir -named createwallet descriptors=true wallet_name=$walletName passphrase=walletpass

bitcoin-cli $flagDataDir $rpcWalletFlag -generate 150

# keeps mining 1 block each 8 sec.
genBlocksForever &
echo $! > $genblockspid