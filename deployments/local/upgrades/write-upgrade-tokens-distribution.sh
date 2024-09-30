#!/bin/bash -eu

# USAGE:
# ./write-upgrade-tokens-distribution.sh

# Set to an empty token distribution the golang data file of upgrade.
# TODO: set covenant signers, BTC delegators and finality providers to receive funds from gov mod addr.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../../..}"
BABYLON_PATH="${BABYLON_PATH:-$BBN_DEPLOYMENTS/babylon}"
GO_TOKENS_DISTRIBUTION_PATH="${GO_TOKENS_DISTRIBUTION_PATH:-$BABYLON_PATH/app/upgrades/v1/data_token_distribution.go}"


# writes the tokens distribution empty to babylon as go file
echo "package v1

const TokensDistribution = \`{
  \"token_distribution\": []
}\`
" > $GO_TOKENS_DISTRIBUTION_PATH
