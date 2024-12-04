#!/bin/bash -eu

# USAGE:
# ./setup-covenant-signer.sh

# it setups the covenant signer config and creates the key with bitcoin

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../../..}"
COVENANT_SIGNER_BIN="${COVENANT_SIGNER_BIN:-$BBN_DEPLOYMENTS/covenant-signer/build/covenant-signer}"

DATA_DIR="${DATA_DIR:-$CWD/../data}"
BTC_HOME="${BTC_HOME:-$DATA_DIR/bitcoind}"
COVENANT_SIGNER_HOME="${COVENANT_SIGNER_HOME:-$DATA_DIR/covenant-signer}"
CLEANUP="${CLEANUP:-1}"

. $CWD/../helpers.sh
checkJq
checkBitcoinCLI
checkCovenantSigner

pidPath=$COVENANT_SIGNER_HOME/pid
cleanUp $CLEANUP $pidPath/*.pid $COVENANT_SIGNER_HOME

outdir="$COVENANT_SIGNER_HOME/out"
logsdir="$COVENANT_SIGNER_HOME/logs"
mkdir -p $pidPath
mkdir -p $outdir
mkdir -p $logsdir

configPath="$COVENANT_SIGNER_HOME/config.toml"
globalParamsPath="$COVENANT_SIGNER_HOME/global-params.json"
covenantSignerPks=$COVENANT_SIGNER_HOME/pks.json
btcDataDirF="-datadir=$BTC_HOME"
btcWalletNameWithFunds="btcWalletName"
covenantSignerWalletName="covenant-signer"
passphraseFlag="passphrase=walletpass"

bitcoin-cli $btcDataDirF -named createwallet descriptors=true wallet_name=$covenantSignerWalletName $passphraseFlag
covenantSignerNewAddr=$(bitcoin-cli $btcDataDirF -rpcwallet=$covenantSignerWalletName getnewaddress)

echo $covenantSignerNewAddr > $outdir/$covenantSignerWalletName.btc.address

covenantSignerPubkeyOutFile=$outdir/$covenantSignerWalletName.btc.pubkey
covenantSignerPubKey=$(bitcoin-cli $btcDataDirF -rpcwallet=$covenantSignerWalletName getaddressinfo $covenantSignerNewAddr | jq -r .pubkey)
echo $covenantSignerPubKey > $covenantSignerPubkeyOutFile

# pub-key, jq does not like -
# convenantPkToGlobalParams=$(cat $covenantSignerPubkeyOutFile | jq .[] | jq --slurp '.[1]')
echo "[\"$covenantSignerPubKey\"]" > $covenantSignerPks

# opens the btc wallet to send transactions
bitcoin-cli $btcDataDirF -rpcwallet=$btcWalletNameWithFunds walletpassphrase walletpass 100000000
# sends 12 btc to new address
bitcoin-cli $btcDataDirF -rpcwallet=$btcWalletNameWithFunds sendtoaddress $covenantSignerNewAddr 12
# creates 15 btc blocks to give height deep enough
bitcoin-cli $btcDataDirF -rpcwallet=$btcWalletNameWithFunds -generate 15

# handles the covenant signer config creation
$COVENANT_SIGNER_BIN dump-cfg --config $configPath
