#!/bin/bash -eu

# USAGE:
# ./write-upgrade-allow-tx-hash-from-csv.sh

# Reads a CSV input file as:
# _id
# 5748f9a245ec52e04a312ec0433da7ecbb769af0a1dc6ae26ad34ed151a0e526
# 023c4d0fc8eeb2c90c65b533996fbc645278c7545900943094cb120e05061bfd
# 2734688f94c0eb49a298463f5a88619914db7688e6468bf275bb9cf8c343afff

# Outputs a json file compatible with the upgrade data app/upgrades/v1/testnet/allowed_staking_tx_hashes.go
CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

CSV_INPUT_FILE="${CSV_INPUT_FILE:-$CWD/inputs/testnet_cap1.csv}"

DATA_DIR="${DATA_DIR:-$CWD/../data}"
DATA_OUTPUTS="${DATA_OUTPUTS:-$DATA_DIR/outputs}"
JSON_OUTPUT_FILE="${JSON_OUTPUT_FILE:-$DATA_OUTPUTS/allow-list-staking-tx.json}"

# Read the CSV file, skipping the header and constructing JSON
{
    echo '{'
    echo '  "tx_hashes": ['
    # Read the CSV file line by line, starting after the header
    tail -n +2 "$CSV_INPUT_FILE" | awk '{ printf "    \"%s\",\n", $0 }' | sed '$s/,$//'
    echo '  ]'
    echo '}'
} > $JSON_OUTPUT_FILE

echo "JSON data saved to $JSON_OUTPUT_FILE"