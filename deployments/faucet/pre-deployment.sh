#!/bin/sh

# Create new directory that will hold node and services' configuration
mkdir -p .testnets && chmod o+w .testnets
docker run --rm -v $(pwd)/.testnets:/data babylonlabs/babylond:v1.0.0-rc.3 \
   babylond testnet --v 2 -o /data \
   --starting-ip-address 192.168.10.2 --keyring-backend=test \
   --chain-id chain-test --epoch-interval 10 \
   --btc-finalization-timeout 2 --btc-confirmation-depth 1 \
   --minimum-gas-prices 1ubbn \
   --btc-base-header 0100000000000000000000000000000000000000000000000000000000000000000000003ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4adae5494dffff7f2002000000 \
   --btc-network regtest --additional-sender-account \
   --slashing-pk-script "76a914010101010101010101010101010101010101010188ac" \
   --slashing-rate 0.1 \
   --min-staking-time-blocks 10 \
   --min-commission-rate 0.05 \
   --unbonding-time 3 \
   --covenant-quorum 1 \
   --covenant-pks "2d4ccbe538f846a750d82a77cd742895e51afcf23d86d05004a356b783902748" # should be updated if `covenant-keyring` dir is changed`

# Create separate subpaths for each component and copy relevant configuration
mkdir -p .testnets/faucet
cp artifacts/faucet-config.yml .testnets/faucet/config.yml
