#!/bin/bash -eux

echo "Create $NUM_FINALITY_PROVIDERS Bitcoin finality providers"

declare -a btcPks=()

for idx in $(seq 0 $((NUM_FINALITY_PROVIDERS-1))); do
    # skips the "Warning: HMAC key not configured. Authentication will not be enabled." with awk
    btcPk=$(docker exec eotsmanager /bin/sh -c "
        /bin/eotsd keys add finality-provider$idx --keyring-backend=test --rpc-client "0.0.0.0:15813" --output=json | awk '/^\{/ {p=1} p' | jq -r '.pubkey_hex'
    ")
    btcPks+=("$btcPk")
    docker exec finality-provider$idx /bin/sh -c "
        /bin/fpd cfp --key-name finality-provider$idx \
            --chain-id chain-test \
            --eots-pk $btcPk \
            --commission-rate 0.05 \
            --commission-max-change-rate 0.05 \
            --commission-max-rate 0.1 \
            --moniker \"Finality Provider $idx\" | head -n -1 | jq -r .finality_provider.btc_pk_hex
    "
done

# Restart the finality provider containers so that key creation command above
# takes effect and finality provider is start communication with the chain.
echo "Restarting finality provider containers..."
for idx in $(seq 0 $((NUM_FINALITY_PROVIDERS-1))); do
    echo "Restarting finality-provider$idx"
    docker restart finality-provider$idx
done
echo "All finality provider containers restarted"


echo "Created $NUM_FINALITY_PROVIDERS Bitcoin finality providers"
echo "Finality provider btc pks" ${btcPks[@]}

echo "Make a delegation to each of the finality providers from a dedicated BTC address"
sleep 10

# Get the available BTC addresses for delegations
delAddrs=($(docker exec btc-staker /bin/sh -c '/bin/stakercli dn list-outputs | jq -r ".outputs[].address" | sort | uniq'))
echo "Delegators Addrs bond vars" $delAddrs

i=0
declare -a txHashes=()
for btcPk in ${btcPks[@]}
do
    # Let `X=NUM_FINALITY_PROVIDERS`
    # For the first X - 1 requests, we select a staking period of 500 BTC
    # blocks. The Xth request will last only for 10 BTC blocks, so that we can
    # showcase the reclamation of expired BTC funds afterwards.
    if [ $((i % $NUM_FINALITY_PROVIDERS)) -eq $((NUM_FINALITY_PROVIDERS -1)) ];
    then
        stakingTime=10
    else
        stakingTime=500
    fi

    echo "Delegating 1 million Satoshis from BTC address ${delAddrs[i]} to Finality Provider with Bitcoin public key $btcPk for $stakingTime BTC blocks";

    btcTxHash=$(docker exec btc-staker /bin/sh -c \
        "/bin/stakercli dn stake --staker-address ${delAddrs[i]} --staking-amount 1000000 --finality-providers-pks $btcPk --staking-time $stakingTime | jq -r '.tx_hash'")
    echo "Delegation was successful; staking tx hash is $btcTxHash"
    txHashes+=("$btcTxHash")  # Store the tx hash in the array
    i=$((i+1))
done

echo "Made a delegation to each of the finality providers"

echo "Wait a few minutes for the delegations to become active..."
while true; do
    allDelegationsActive=$(docker exec finality-provider0 /bin/sh -c \
        'fpd ls | jq ".finality_providers[].last_voted_height != null"')

    if [[ $allDelegationsActive == *"false"* ]]
    then
        sleep 10
    else
        echo "All delegations have become active"
        break
    fi
done

echo "Attack Babylon by submitting a conflicting finality signature for a finality provider"
# Select the first Finality Provider
attackerBtcPk=$(echo ${btcPks[@]}  | cut -d " " -f 1)
attackHeight=$(docker exec finality-provider0 /bin/sh -c '/bin/fpd ls | jq -r ".finality_providers[].last_voted_height" | head -n 1')
# fpd unsafe-add-finality-sig now requires the block app hash; fetch it from Babylon
attackAppHash=$(docker exec babylondnode0 /bin/sh -c "curl -s localhost:26657/block?height=${attackHeight} | jq -r .result.block.header.app_hash")

# Execute the attack for the first height that the finality provider voted
docker exec finality-provider0 /bin/sh -c \
    "/bin/fpd unsafe-add-finality-sig $attackerBtcPk $attackHeight --app-hash ${attackAppHash} --daemon-address 127.0.0.1:12581 --check-double-sign=false"

echo "Finality Provider with Bitcoin public key $attackerBtcPk submitted a conflicting finality signature for Babylon height $attackHeight; the Finality Provider's private BTC key has been extracted and the Finality Provider will now be slashed"

echo "Wait a few minutes for the last, shortest BTC delegation (10 BTC blocks) to expire..."
sleep 10

echo "Withdraw the expired staked BTC funds (staking tx hash: $btcTxHash)"
docker exec btc-staker /bin/sh -c \
    "/bin/stakercli dn ust --staking-transaction-hash $btcTxHash"

echo "Unbond staked BTC tokens (staking tx hash: ${txHashes[1]}"
docker exec btc-staker /bin/sh -c \
        "/bin/stakercli dn unbond --staking-transaction-hash ${txHashes[1]}"

echo "Wait for the unbond transaction to expire"
sleep 180

echo "Withdraw the expired staked BTC funds from unbonding (staking tx hash: ${txHashes[1]}"
docker exec btc-staker /bin/sh -c \
        "/bin/stakercli dn unstake --staking-transaction-hash ${txHashes[1]}"
