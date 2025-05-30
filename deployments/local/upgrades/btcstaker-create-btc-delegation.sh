#!/bin/bash -eu

# USAGE:
# ./btcstaker-create-btc-delegation.sh

# Creates a BTC delegation directly to bitcoin without babylonchain running.
CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../../..}"

BTC_STAKER_BUILD="${BTC_STAKER_BUILD:-$BBN_DEPLOYMENTS/btc-staker/build}"
STAKERCLI_BIN="${STAKERCLI_BIN:-$BTC_STAKER_BUILD/stakercli}"
CLEANUP="${CLEANUP:-1}"
CHAIN_ID="${CHAIN_ID:-test-1}"

DATA_DIR="${DATA_DIR:-$CWD/../data}"
BTC_STAKER_HOME="${BTC_STAKER_HOME:-$DATA_DIR/btc-staker}"
BTC_HOME="${BTC_HOME:-$DATA_DIR/bitcoind}"

defaultCovenantCommitteePks=$(cat $DATA_DIR/covd/pks.json | jq -r .[])
COVENANT_COMMITTEE_PKS="${COVENANT_COMMITTEE_PKS:-$defaultCovenantCommitteePks}"

defaultFinalityProviderPk=$(cat $DATA_DIR/fpd/fp-0/out/eotsd-keys-add.json | jq -r .pubkey_hex)
FP_EOTS_PK="${FP_EOTS_PK:-$defaultFinalityProviderPk}"

btcDataDirF="-datadir=$BTC_HOME"
btcStakerWalletName="btc-staker"
btcWalletNameWithFunds="btcWalletName"
passphraseFlag="passphrase=walletpass"

. $CWD/../helpers.sh
cleanUp $CLEANUP $BTC_STAKER_HOME/*.pid $BTC_STAKER_HOME

outdir="$BTC_STAKER_HOME/out"
mkdir -p $outdir

bitcoin-cli $btcDataDirF -named createwallet descriptors=true wallet_name=$btcStakerWalletName $passphraseFlag
btcStakerNewAddr=$(bitcoin-cli $btcDataDirF -rpcwallet=$btcStakerWalletName getnewaddress)

echo $btcStakerNewAddr > $outdir/$btcStakerWalletName.address

# opens the btc wallet to send transactions
bitcoin-cli $btcDataDirF -rpcwallet=$btcWalletNameWithFunds walletpassphrase walletpass 100000000
# sends 12 btc to new address
bitcoin-cli $btcDataDirF -rpcwallet=$btcWalletNameWithFunds sendtoaddress $btcStakerNewAddr 12
# creates 15 btc blocks to give height deep enough
bitcoin-cli $btcDataDirF -rpcwallet=$btcWalletNameWithFunds -generate 15

stakerBtcPubKey=$(bitcoin-cli $btcDataDirF -rpcwallet=$btcStakerWalletName getaddressinfo $btcStakerNewAddr | jq -r '.pubkey[2:]')

# stake 0.1 BTC, for 52560 btc blocks
# tag is inside genesis.btccheckpoint.params.checkpoint_tag
$STAKERCLI_BIN transaction create-phase1-staking-transaction --staker-pk $stakerBtcPubKey --finality-provider-pk $FP_EOTS_PK \
  --staking-amount 10000000 --staking-time 52560 --tag 01020304 --covenant-quorum 1 --covenant-committee-pks $COVENANT_COMMITTEE_PKS \
  --network regtest > $outdir/create-phase1-staking-transaction.json

stakingTxHex=$(cat $outdir/create-phase1-staking-transaction.json | jq -r .staking_tx_hex)

# open and fund the tx
bitcoin-cli $btcDataDirF -rpcwallet=$btcStakerWalletName walletpassphrase walletpass 100000000
bitcoin-cli $btcDataDirF -rpcwallet=$btcStakerWalletName fundrawtransaction $stakingTxHex > $outdir/fundrawtransaction.json
fundedTxHex=$(cat $outdir/fundrawtransaction.json | jq -r .hex)

bitcoin-cli $btcDataDirF -rpcwallet=$btcStakerWalletName signrawtransactionwithwallet $fundedTxHex > $outdir/signrawtransactionwithwallet.json
signedTxHex=$(cat $outdir/signrawtransactionwithwallet.json | jq -r .hex)

bitcoin-cli $btcDataDirF sendrawtransaction $signedTxHex > $outdir/sendrawtransaction.txt
# creates 10 btc blocks to give height deep enough
bitcoin-cli $btcDataDirF -rpcwallet=$btcWalletNameWithFunds -generate 10