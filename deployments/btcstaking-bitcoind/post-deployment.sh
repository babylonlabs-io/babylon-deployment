#!/bin/bash -eux

echo "Creating keyrings and sending funds to Babylon Node Consumers"

[[ "$(uname)" == "Linux" ]] && chown -R 1138:1138 .testnets/eotsmanager

sleep 15
docker exec babylondnode0 /bin/sh -c '
    BTC_STAKER_ADDR=$(/bin/babylond --home /babylondhome/.tmpdir keys add \
        btc-staker --output json --keyring-backend test | jq -r .address) && \
    /bin/babylond --home /babylondhome tx bank send test-spending-key \
        ${BTC_STAKER_ADDR} 100000000ubbn --fees 600000ubbn -y \
        --chain-id chain-test --keyring-backend test
'
mkdir -p .testnets/btc-staker/keyring-test
mv .testnets/node0/babylond/.tmpdir/keyring-test/* .testnets/btc-staker/keyring-test
[[ "$(uname)" == "Linux" ]] && chown -R 1138:1138 .testnets/btc-staker

sleep 10

# For each num finality provider it should create a new path and
# use a different docker container
for idx in $(seq 0 $((NUM_FINALITY_PROVIDERS-1))); do
  docker exec babylondnode0 /bin/sh -c '
      FINALITY_PROVIDER_ADDR=$(/bin/babylond --home /babylondhome/.tmpdir keys add \
          finality-provider'$idx' --output json --keyring-backend test | jq -r .address) && \
      /bin/babylond --home /babylondhome tx bank send test-spending-key \
          ${FINALITY_PROVIDER_ADDR} 100000000ubbn --fees 600000ubbn -y \
          --chain-id chain-test --keyring-backend test
  '
  mkdir -p .testnets/finality-provider$idx/keyring-test
  mv .testnets/node0/babylond/.tmpdir/keyring-test/* .testnets/finality-provider$idx/keyring-test
  [[ "$(uname)" == "Linux" ]] && chown -R 1138:1138 .testnets/finality-provider$idx

  sleep 10
done

docker exec babylondnode0 /bin/sh -c '
    VIGILANTE_ADDR=$(/bin/babylond --home /babylondhome/.tmpdir keys add \
        vigilante --output json --keyring-backend test | jq -r .address) && \
    /bin/babylond --home /babylondhome tx bank send test-spending-key \
        ${VIGILANTE_ADDR} 100000000ubbn --fees 600000ubbn -y \
        --chain-id chain-test --keyring-backend test
'
mkdir -p .testnets/vigilante/keyring-test .testnets/vigilante/bbnconfig
mv .testnets/node0/babylond/.tmpdir/keyring-test/* .testnets/vigilante/keyring-test
cp .testnets/node0/babylond/config/genesis.json .testnets/vigilante/bbnconfig
[[ "$(uname)" == "Linux" ]] && chown -R 1138:1138 .testnets/vigilante

sleep 10
mkdir -p .testnets/node0/babylond/.tmpdir/keyring-test
cp .testnets/covenant-emulator/keyring-test/* .testnets/node0/babylond/.tmpdir/keyring-test/
docker exec babylondnode0 /bin/sh -c '
    COVENANT_ADDR=$(/bin/babylond --home /babylondhome/.tmpdir keys show covenant \
        --output json --keyring-backend test | jq -r .address) && \
    /bin/babylond --home /babylondhome tx bank send test-spending-key \
        ${COVENANT_ADDR} 100000000ubbn --fees 600000ubbn -y \
        --chain-id chain-test --keyring-backend test
'
[[ "$(uname)" == "Linux" ]] && chown -R 1138:1138 .testnets/covenant-emulator

echo "Created keyrings and sent funds"
