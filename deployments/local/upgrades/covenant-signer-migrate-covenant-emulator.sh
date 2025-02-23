#!/bin/bash -eu

# USAGE:
# ./covenant-signer-migrate-covenant-emulator.sh

# Migrates the covenant signer pk to import inside the covenant emulator
CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../../..}"

BABYLOND_DIR="${BABYLOND_DIR:-$BBN_DEPLOYMENTS/babylon}"
BBN_BIN="${BBN_BIN:-$BABYLOND_DIR/build/babylond}"

COVENANT_SIGNER_IN_COVD_BIN="${COVENANT_SIGNER_IN_COVD_BIN:-$BBN_DEPLOYMENTS/covenant-emulator/covenant-signer/build/covenant-signer}"

CHAIN_ID="${CHAIN_ID:-test-1}"
DATA_DIR="${DATA_DIR:-$CWD/../data}"

DATA_OUTPUTS="${DATA_OUTPUTS:-$DATA_DIR/outputs}"

BTC_HOME="${BTC_HOME:-$DATA_DIR/bitcoind}"
COVENANT_SIGNER_HOME="${COVENANT_SIGNER_HOME:-$DATA_DIR/covenant-signer-phase-1}"
COVD_HOME="${COVD_HOME:-$DATA_DIR/covd}"
COVD_BIN="${COVD_BIN:-$BBN_DEPLOYMENTS/covenant-emulator/build/covd}"

covenantSignerWalletName="covenant-signer"
defaultCovenantSignerAddr=$(cat $COVENANT_SIGNER_HOME/out/$covenantSignerWalletName.btc.address)
COVENANT_SIGNER_ADDR="${COVENANT_SIGNER_ADDR:-$defaultCovenantSignerAddr}"

BTC_STAKER_HOME="${BTC_STAKER_HOME:-$DATA_DIR/btc-staker}"

btcDataDirF="-datadir=$BTC_HOME"

covenantSignerHdkeypath=$(bitcoin-cli $btcDataDirF -rpcwallet=$covenantSignerWalletName getaddressinfo $COVENANT_SIGNER_ADDR | jq -r .hdkeypath)
echo $covenantSignerHdkeypath > $DATA_OUTPUTS/$covenantSignerWalletName.bitcoin.hdkeypath

covenantSignerHdkeypathParsed=$(echo "$covenantSignerHdkeypath" | sed -E 's|m/||; s|/[0-9]+$|/*|')

bitcoin-cli $btcDataDirF -rpcwallet=$covenantSignerWalletName walletpassphrase "walletpass" 160
covenantSignerDescriptors=$(bitcoin-cli $btcDataDirF -rpcwallet=$covenantSignerWalletName listdescriptors true)

descriptorsFile=$DATA_OUTPUTS/$covenantSignerWalletName.descriptors.json
echo $covenantSignerDescriptors > $descriptorsFile

descriptorsCovenantSigner=$(jq -r '.descriptors[] | select(.desc | contains("'$covenantSignerHdkeypathParsed'")) | .desc' $descriptorsFile)

# Remove the outer quotes and the leading 'wpkh(' and trailing ')'
temp="${descriptorsCovenantSigner//\'/}"         # Remove single quotes
temp="${temp#wpkh(}"       # Remove the leading 'wpkh('
temp="${temp%)#*}"         # Remove the trailing ')#plq5we6k'

# Extract only the part before the first '/'
covenantSignerMasterPrivateKey="${temp%%/*}"

# covenantSignerMasterPrivateKey=$(echo "$descriptorsCovenantSigner" | sed -n "s/.*(\(tprv8[^\)]+\)).*/\1/p")
echo $covenantSignerMasterPrivateKey > $DATA_OUTPUTS/$covenantSignerWalletName.master.privatekey

derivedKeysFilePath=$DATA_OUTPUTS/$covenantSignerWalletName.derivedkeys
# m/84h/1h/0h/0/0 to 84h/1h/0h/0/0
expectedFormatHdPath="${covenantSignerHdkeypath#m/}"
covenantSignerDerivedKeys=$($COVENANT_SIGNER_IN_COVD_BIN derive-child-key $covenantSignerMasterPrivateKey $expectedFormatHdPath)
echo $covenantSignerDerivedKeys > $derivedKeysFilePath

covenantSignerPrivateKey=$(grep -oP 'Derived private key: \K[0-9a-f]{64}' $derivedKeysFilePath)

covenantEmulatorKeyName=covenant-from-signer
# Imports from the private key into covenant-emulator (covd) setup
$BBN_BIN keys import-hex $covenantEmulatorKeyName $covenantSignerPrivateKey --keyring-backend test --home $COVD_HOME

covdPubFile=$COVD_HOME/keyring-test/$covenantEmulatorKeyName.pubkey.json
covdPKs=$COVD_HOME/pks.json

covenantPubKey=$($COVD_BIN show-key --key-name $covenantEmulatorKeyName --keyring-backend test --home $COVD_HOME --chain-id $CHAIN_ID | jq -r)
echo $covenantPubKey > $covdPubFile

convenantPk=$(cat $covdPubFile | jq .[] | jq --slurp '.[1]')
echo "[$convenantPk]" > $covdPKs
