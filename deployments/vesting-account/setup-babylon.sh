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
  # sed -i 's/"epoch_interval": "400"/"epoch_interval": "10"/g' $CHAINDIR/$CHAINID/node0/$BINARY/config/genesis.json
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
  # sed -i '' 's/"epoch_interval": "400"/"epoch_interval": "10"/g' $CHAINDIR/$CHAINID/node0/$BINARY/config/genesis.json
  sed -i '' 's/"secret"/"mnemonic"/g' $CHAINDIR/$CHAINID/key_seed.json
fi

# Start the node
echo "start a Babylon node"
$BINARY_OLD --home $CHAINDIR/$CHAINID/node0/$BINARY start --pruning=nothing --grpc-web.enable=false --grpc.address="0.0.0.0:$GRPCPORT" >$CHAINDIR/$CHAINID.log 2>&1 &

# Wait for the node to start
sleep 10

# Submit a software upgrade proposal
echo "Submitting a software upgrade proposal..."

UPGRADE_NAME=vanilla
UPGRADE_HEIGHT=50

$BINARY_OLD --home $CHAINDIR/$CHAINID/node0/$BINARY tx upgrade software-upgrade $UPGRADE_NAME --title "TEST UPGRADE" --summary "SUMMARY" --upgrade-height $UPGRADE_HEIGHT --upgrade-info "PROPOSE TO UPGRADE TO $UPGRADE_NAME!" --deposit 10000$DENOM --from test-spending-key $KEYRING --chain-id $CHAINID --no-validate --fees 2000$BASEDENOM --yes

# Wait for the proposal to be included in a block
sleep 10

# Validator votes for the proposal
echo "Voting for the software upgrade proposal..."
$BINARY_OLD --home $CHAINDIR/$CHAINID/node0/$BINARY tx gov vote 1 yes --from node0 $KEYRING --chain-id $CHAINID --fees 2000$BASEDENOM --yes

# Wait for the voting period to end
sleep 10

# Check proposal status
while true; do
  status=$(babylond q gov proposal 1 --output json | jq '.proposal.status')
  if [ $status -lt 3 ]; then
    echo "Proposal has not been passed"
    sleep 5
  else
    echo "Proposal has been passed!"
    break
  fi
done

echo "Simulating waiting until the upgrade height..."
sleep 30

# At upgrade height, the node should halt. Restart the node with the new binary (assume the binary is updated)
echo "kill $BINARY_OLD..."
killall $BINARY

sleep 5

# Assume the new binary is in place
echo "start $BINARY_NEW..."
$BINARY_NEW --home $CHAINDIR/$CHAINID/node0/$BINARY start --pruning=nothing --grpc-web.enable=false --grpc.address="0.0.0.0:$GRPCPORT" >$CHAINDIR/$CHAINID.log 2>&1 &

# Monitor the node log for successful upgrade
tail -f $CHAINDIR/$CHAINID.log | while read LOGLINE; do
  [[ "${LOGLINE}" == *"applying upgrade"*"$UPGRADE_NAME"* ]] && pkill -P $$ tail
done

echo "Software upgrade to $UPGRADE_NAME completed successfully."
