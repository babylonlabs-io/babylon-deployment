#!/usr/bin/env bash
set -e

# Create bitcoin data directory and initialize bitcoin configuration file.
mkdir -p "$BITCOIN_DATA"
echo "# Enable regtest mode.
regtest=1

# Accept command line and JSON-RPC commands
server=1

# RPC user and password.
rpcuser=$RPC_USER
rpcpassword=$RPC_PASS

# ZMQ notification options.
# Enable publish hash block and tx sequence
zmqpubsequence=tcp://*:$ZMQ_SEQUENCE_PORT
# Enable publishing of raw block hex.
zmqpubrawblock=tcp://*:$ZMQ_RAWBLOCK_PORT
# Enable publishing of raw transaction.
zmqpubrawtx=tcp://*:$ZMQ_RAWTR_PORT

txindex=1
deprecatedrpc=create_bdb

# Fallback fee
fallbackfee=0.00001

# Allow all IPs to access the RPC server.
[regtest]
rpcbind=0.0.0.0
rpcallowip=0.0.0.0/0
" > "$BITCOIN_CONF"

GENERATE_STAKER_MULTISIG="${GENERATE_STAKER_MULTISIG:=true}"
STAKER_CONF_PATH="${STAKER_CONF_PATH:=/home/btcstaker/.stakerd/stakerd.conf}"
STAKER_MULTISIG_WALLET_NAME="${STAKER_MULTISIG_WALLET_NAME:=btcstaker-multisig}"
STAKER_MULTISIG_KEYS_COUNT="${STAKER_MULTISIG_KEYS_COUNT:=3}"
STAKER_MULTISIG_THRESHOLD="${STAKER_MULTISIG_THRESHOLD:=2}"

GENERATE_STAKER_WALLET="${GENERATE_STAKER_WALLET:=true}"
echo "Starting bitcoind..."
bitcoind  -regtest -datadir="$BITCOIN_DATA" -conf="$BITCOIN_CONF" -daemon
# Allow some time for bitcoind to start
sleep 3
echo "Creating a wallet..."
bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" createwallet "$WALLET_NAME" false false "$WALLET_PASS" false false
echo "Generating 110 blocks for the first coinbases to mature..."
bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" -generate 110

if [[ "$GENERATE_STAKER_WALLET" == "true" ]]; then
  echo "Creating a wallet and $BTCSTAKER_WALLET_ADDR_COUNT addresses for btcstaker..."
  bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" createwallet "$BTCSTAKER_WALLET_NAME" false false "$WALLET_PASS" false false

  BTCSTAKER_ADDRS=()
  for i in `seq 0 1 $((BTCSTAKER_WALLET_ADDR_COUNT - 1))`
  do
    BTCSTAKER_ADDRS+=($(bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$BTCSTAKER_WALLET_NAME" getnewaddress))
  done

  # Generate a UTXO for each btc-staker address
  bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" walletpassphrase "$WALLET_PASS" 1
  for addr in "${BTCSTAKER_ADDRS[@]}"
  do
    bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" sendtoaddress "$addr" 10
  done

  # Allow some time for the wallet to catch up.
  sleep 5

  echo "Checking balance..."
  bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" getbalance
fi

if [[ "$GENERATE_STAKER_MULTISIG" == "true" ]]; then
  if [[ ! -f "$STAKER_CONF_PATH" ]]; then
    echo "Staker config not found at $STAKER_CONF_PATH, skipping multisig key injection"
    ls -la "$(dirname "$STAKER_CONF_PATH")" || true
  fi

  echo "Creating a multisig wallet ($STAKER_MULTISIG_WALLET_NAME) with $STAKER_MULTISIG_KEYS_COUNT keys for btc-staker..."
  bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" createwallet "$STAKER_MULTISIG_WALLET_NAME" false false "$WALLET_PASS" false false
  bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$STAKER_MULTISIG_WALLET_NAME" walletpassphrase "$WALLET_PASS" 60

  MULTISIG_WIFS=()
  MULTISIG_ADDRS=()
  for i in $(seq 1 1 "$STAKER_MULTISIG_KEYS_COUNT"); do
    addr=$(bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$STAKER_MULTISIG_WALLET_NAME" getnewaddress)
    MULTISIG_ADDRS+=("$addr")
    wif=$(bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$STAKER_MULTISIG_WALLET_NAME" dumpprivkey "$addr")
    MULTISIG_WIFS+=("$wif")
  done

  # Fund each multisig address from the main wallet to mirror btcstaker funding.
  bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" walletpassphrase "$WALLET_PASS" 1
  for addr in "${MULTISIG_ADDRS[@]}"; do
    bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" sendtoaddress "$addr" 10
  done
  sleep 5

  wifs_csv=$(IFS=,; echo "${MULTISIG_WIFS[*]}")
  awk -v wifs="$wifs_csv" -v threshold="$STAKER_MULTISIG_THRESHOLD" '
    /^[[:space:]]*StakerKeyWIFs[[:space:]]*=/ {
      print "StakerKeyWIFs = " wifs
      foundW=1
      next
    }
    /^[[:space:]]*StakerThreshold[[:space:]]*=/ {
      print "StakerThreshold = " threshold
      foundT=1
      next
    }
    { print }
    END {
      if (foundW != 1) {
        print "StakerKeyWIFs = " wifs
      }
      if (foundT != 1) {
        print "StakerThreshold = " threshold
      }
    }
  ' "$STAKER_CONF_PATH" > "${STAKER_CONF_PATH}.tmp" && mv "${STAKER_CONF_PATH}.tmp" "$STAKER_CONF_PATH"
  echo "Injected ${#MULTISIG_WIFS[@]} staker multisig keys and threshold ${STAKER_MULTISIG_THRESHOLD} into $STAKER_CONF_PATH"
fi

echo "Generating a block every ${GENERATE_INTERVAL_SECS} seconds."
echo "Press [CTRL+C] to stop..."
while true
do
  bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" -generate 1
  if [[ "$GENERATE_STAKER_WALLET" == "true" ]]; then
    echo "Periodically send funds to btcstaker addresses..."
    bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" walletpassphrase "$WALLET_PASS" 10
    for addr in "${BTCSTAKER_ADDRS[@]}"
    do
      bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" sendtoaddress "$addr" 10
    done
  fi
  sleep "${GENERATE_INTERVAL_SECS}"
done
