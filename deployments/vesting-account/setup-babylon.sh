#!/bin/bash

display_usage() {
  echo "Missing $1 parameter. Please check if all parameters were specified."
  echo "Usage: setup-babylon.sh [CHAIN_ID] [CHAIN_DIR] [RPC_PORT] [P2P_PORT] [PROFILING_PORT] [GRPC_PORT]"
  echo "Example: setup-babylon.sh test-chain-id ./data 26657 26656 6060 9090"
  exit 1
}

BINARY=babylond

BINARY_OLD=./build/$BINARY
BINARY_NEW=./build/$BINARY-new

DENOM=bbn
BASEDENOM=ubbn
KEYRING=--keyring-backend="test"
SILENT=1

redirect() {
  if [ "$SILENT" -eq 1 ]; then
    "$@" >/dev/null 2>&1
  else
    "$@"
  fi
}

CHAINID=$1
CHAINDIR=$2
RPCPORT=$3
P2PPORT=$4
PROFPORT=$5
GRPCPORT=$6

if [ -z "$1" ]; then
  display_usage "[CHAIN_ID]"
fi

if [ -z "$2" ]; then
  display_usage "[CHAIN_DIR]"
fi

if [ -z "$3" ]; then
  display_usage "[RPC_PORT]"
fi

if [ -z "$4" ]; then
  display_usage "[P2P_PORT]"
fi

if [ -z "$5" ]; then
  display_usage "[PROFILING_PORT]"
fi

if [ -z "$6" ]; then
  display_usage "[GRPC_PORT]"
fi

# ensure the old binary exists
if ! command -v $BINARY_OLD &>/dev/null; then
  echo "$BINARY_OLD could not be found"
  exit
fi
# ensure the new binary exists
if ! command -v $BINARY_NEW &>/dev/null; then
  echo "$BINARY_NEW could not be found"
  exit
fi

# kill previous runs
echo "Killing $BINARY..."
killall $BINARY &>/dev/null

# Delete chain data from old runs
echo "Deleting $CHAINDIR/$CHAINID folders..."
rm -rf $CHAINDIR/$CHAINID &>/dev/null
rm $CHAINDIR/$CHAINID.log &>/dev/null

echo "Creating $BINARY instance: home=$CHAINDIR | chain-id=$CHAINID | p2p=:$P2PPORT | rpc=:$RPCPORT | profiling=:$PROFPORT | grpc=:$GRPCPORT"

# Add dir for chain, exit if error
if ! mkdir -p $CHAINDIR/$CHAINID 2>/dev/null; then
  echo "Failed to create chain folder. Aborting..."
  exit 1
fi

$BINARY_OLD testnet --v 1 --output-dir $CHAINDIR/$CHAINID --starting-ip-address 192.168.10.2 --keyring-backend test --chain-id $CHAINID --additional-sender-account true

# create a copy of the mnemonic for the relayer account
cp $CHAINDIR/$CHAINID/node0/$BINARY/additional_key_seed.json $CHAINDIR/$CHAINID/key_seed.json

# Check platform
platform='unknown'
unamestr=$(uname)
if [ "$unamestr" = 'Linux' ]; then
  platform='linux'
fi

# Set proper defaults and change ports (use a different sed for Mac or Linux)
echo "Change settings in config.toml and genesis.json files..."
if [ $platform = 'linux' ]; then
  sed -i 's#"tcp://0.0.0.0:26657"#"tcp://0.0.0.0:'"$RPCPORT"'"#g' $CHAINDIR/$CHAINID/node0/$BINARY/config/config.toml
  sed -i 's#"tcp://0.0.0.0:26656"#"tcp://0.0.0.0:'"$P2PPORT"'"#g' $CHAINDIR/$CHAINID/node0/$BINARY/config/config.toml
  sed -i 's#"localhost:6060"#"localhost:'"$PROFILINGPORT"'"#g' $CHAINDIR/$CHAINID/node0/$BINARY/config/config.toml
  sed -i 's/timeout_commit = "5s"/timeout_commit = "1s"/g' $CHAINDIR/$CHAINID/node0/$BINARY/config/config.toml
  sed -i 's/timeout_propose = "3s"/timeout_propose = "1s"/g' $CHAINDIR/$CHAINID/node0/$BINARY/config/config.toml
  sed -i 's/index_all_keys = false/index_all_keys = true/g' $CHAINDIR/$CHAINID/node0/$BINARY/config/config.toml
  sed -i 's/"bond_denom": "stake"/"bond_denom": "'"$DENOM"'"/g' $CHAINDIR/$CHAINID/node0/$BINARY/config/genesis.json
  sed -i 's/"voting_period": "172800s"/"voting_period": "20s"/g' $CHAINDIR/$CHAINID/node0/$BINARY/config/genesis.json
  sed -i 's/"expedited_voting_period": "86400s"/"expedited_voting_period": "10s"/g' $CHAINDIR/$CHAINID/node0/$BINARY/config/genesis.json
  sed -i 's/"epoch_interval": "400"/"epoch_interval": "20"/g' $CHAINDIR/$CHAINID/node0/$BINARY/config/genesis.json
  sed -i 's/"secret"/"mnemonic"/g' $CHAINDIR/$CHAINID/key_seed.json
else
  sed -i '' 's#"tcp://0.0.0.0:26657"#"tcp://0.0.0.0:'"$RPCPORT"'"#g' $CHAINDIR/$CHAINID/node0/$BINARY/config/config.toml
  sed -i '' 's#"tcp://0.0.0.0:26656"#"tcp://0.0.0.0:'"$P2PPORT"'"#g' $CHAINDIR/$CHAINID/node0/$BINARY/config/config.toml
  sed -i '' 's#"localhost:6060"#"localhost:'"$PROFILINGPORT"'"#g' $CHAINDIR/$CHAINID/node0/$BINARY/config/config.toml
  sed -i '' 's/timeout_commit = "5s"/timeout_commit = "1s"/g' $CHAINDIR/$CHAINID/node0/$BINARY/config/config.toml
  sed -i '' 's/timeout_propose = "3s"/timeout_propose = "1s"/g' $CHAINDIR/$CHAINID/node0/$BINARY/config/config.toml
  sed -i '' 's/index_all_keys = false/index_all_keys = true/g' $CHAINDIR/$CHAINID/node0/$BINARY/config/config.toml
  sed -i '' 's/"bond_denom": "stake"/"bond_denom": "'"$DENOM"'"/g' $CHAINDIR/$CHAINID/node0/$BINARY/config/genesis.json
  sed -i '' 's/"voting_period": "172800s"/"voting_period": "20s"/g' $CHAINDIR/$CHAINID/node0/$BINARY/config/genesis.json
  sed -i '' 's/"expedited_voting_period": "86400s"/"expedited_voting_period": "10s"/g' $CHAINDIR/$CHAINID/node0/$BINARY/config/genesis.json
  sed -i '' 's/"epoch_interval": "400"/"epoch_interval": "20"/g' $CHAINDIR/$CHAINID/node0/$BINARY/config/genesis.json
  sed -i '' 's/"secret"/"mnemonic"/g' $CHAINDIR/$CHAINID/key_seed.json
fi

# Start the node
echo "start a Babylon node"
$BINARY_OLD --home $CHAINDIR/$CHAINID/node0/$BINARY start --pruning=nothing --grpc-web.enable=false --grpc.address="0.0.0.0:$GRPCPORT" >$CHAINDIR/$CHAINID.log 2>&1 &

# Wait for the node to start
sleep 10

# Create a vesting account
echo "Creating a vesting account..."

# Get the address of the sender account (assuming it's the first account)
SENDER_ADDRESS=$($BINARY_OLD keys show -a node0 --keyring-backend test --home $CHAINDIR/$CHAINID/node0/$BINARY)

# Generate a new account for vesting
VESTING_ACCOUNT_NAME="vesting_account"
VESTING_ACCOUNT=$($BINARY_OLD keys add $VESTING_ACCOUNT_NAME --keyring-backend test --home $CHAINDIR/$CHAINID/node0/$BINARY --output json)
VESTING_ADDRESS=$(echo $VESTING_ACCOUNT | jq -r .address)

# Send 1bbn to the vesting account
echo "Sending 1bbn to the vesting account..."
$BINARY_OLD tx bank send \
  $SENDER_ADDRESS \
  $VESTING_ADDRESS \
  1000000ubbn \
  --chain-id $CHAINID \
  --keyring-backend test \
  --home $CHAINDIR/$CHAINID/node0/$BINARY \
  --fees 2ubbn \
  --yes

# Wait for the transaction to be processed
sleep 5

# Verify the balance of the vesting account
echo "Verifying the balance of the vesting account..."
$BINARY_OLD query bank balances $VESTING_ADDRESS \
  --chain-id $CHAINID \
  --node tcp://localhost:$RPCPORT

# Use the vesting.json file to create the periodic vesting account
$BINARY_OLD tx vesting create-periodic-vesting-account \
  $VESTING_ADDRESS \
  ./vesting.json \
  --from $SENDER_ADDRESS \
  --chain-id $CHAINID \
  --keyring-backend test \
  --home $CHAINDIR/$CHAINID/node0/$BINARY \
  --fees 2ubbn \
  --yes

echo "Vesting account created with address: $VESTING_ADDRESS"

# Stake 10 BBN for VESTING_ADDRESS to genesis validator
echo "Staking 10 BBN from vesting account to genesis validator..."

# Get the validator address (assuming it's the first validator in the active set)
VALIDATOR_ADDRESS=$($BINARY_OLD query staking validators --output json | jq -r '.validators[0].operator_address')

# Stake 10 BBN (10000000ubbn) from the vesting account to the validator
$BINARY_OLD tx epoching delegate $VALIDATOR_ADDRESS 10000000ubbn \
  --from $VESTING_ADDRESS \
  --chain-id $CHAINID \
  --keyring-backend test \
  --home $CHAINDIR/$CHAINID/node0/$BINARY \
  --fees 2ubbn \
  --yes

# Wait for the transaction to be processed
sleep 5

# Verify the delegation
echo "Verifying the delegation..."
$BINARY_OLD query staking delegations $VESTING_ADDRESS \
  --chain-id $CHAINID \
  --node tcp://localhost:$RPCPORT

echo "Staking completed for vesting account: $VESTING_ADDRESS"
