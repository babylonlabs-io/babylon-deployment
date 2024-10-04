# BTC Staking deployment (BTC backend: bitcoind)

## Components

The to-be-deployed Babylon network that features Babylon's BTC Staking and BTC
Timestamping protocols comprises the following components:

- 2 **Babylon Finality Provider Nodes** running the base Tendermint consensus and producing
  Tendermint-confirmed Babylon blocks
- **Finality Provider** daemon: Hosts one or more Finality Providers which commit public
  randomness and submit finality signatures for Babylon blocks to Babylon
- **BTC Staker** daemon: Enables the staking of BTC tokens to PoS chains by
  locking BTC tokens on the BTC network and submitting a delegation to a
  dedicated Finality Provider; the daemon connects to a BTC wallet that manages
  multiple private/public keys and performs staking requests from BTC public
  keys to dedicated Finality Providers
- **BTC covenant emulation** daemon: Pre-signs the BTC slashing
  transaction to enforce that malicious stakers' stake will be sent to a
  pre-defined burn BTC address in case they attack Babylon
- **Vigilante Monitor** daemon: Detects attacks to Babylon and submits slashing
  transactions to the BTC network for the Finality Providers and the associated
  stakers
- **Vigilante Submitter** daemon: Aggregates and checkpoints Babylon epochs (a
  group of `X` Babylon blocks) to the BTC network
- **Vigilante Reporter** daemon: Keeps track of the BTC network's state in
  Babylon and detects Babylon checkpoints that have received a BTC timestamp
  (i.e. have been confirmed in BTC)
- A **BTC simnet** acting as the BTC network, operated through a bitcoind node

### Expected Docker state post-deployment

The following containers should be created as a result of the `make` command
that spins up the network:

```shell
[+] Running 13/13
✔ Network artifacts_localnet      Created                                                               0.2s
 ✔ Container babylondnode0        Started                                                               0.5s
 ✔ Container babylondnode1        Started                                                               0.6s
 ✔ Container bitcoindsim          Started                                                               0.5s
 ✔ Container vigilante-reporter   Started                                                               1.6s
 ✔ Container vigilante-submitter  Started                                                               1.2s
 ✔ Container finality-provider    Started                                                               1.0s
 ✔ Container vigilante-monitor    Started                                                               2.0s
 ✔ Container btc-staker           Started                                                               1.2s
 ✔ Container covenant             Started                                                               1.0s
```

## Inspecting the BTC Staking Protocol demo

Deploying the BTC Staking network through the `make` subcommand
`start-deployment-btcstaking-bitcoind-demo` leads to the execution of an
additional post-deployment [script](btcstaking-demo.sh) that showcases the
complete lifecycle of Babylon's BTC Staking protocol.

We will now analyze each step that is executed as part of the BTC
Staking showcasing script - more specifically, how it is performed and its
outcome for the Babylon and the BTC network respectively.

### Generating Finality Providers

Initially, 3 Finality Providers are created and registered on Babylon through the
Finality Provider daemon. For each Babylon block, the daemon will now check if
the Finality Providers have simnet BTC tokens staked to them. The Finality Providers that have
staked tokens can submit finality signatures.

Through the Finality Provider's daemon logs we can verify the above (only 1
Finality Provider is included in all the example outputs in this section for
simplicity):

```shell
$ docker logs -f finality-provider0
...
time="2023-08-18T10:28:37Z" level=debug msg="handling CreateFinality Provider request"
Generated mnemonic for key bbn-finality-provider1 is obtain decorate picnic social cheese wool swing smile dashi ncrease van quarter buyer maze moon glad level column metal bounce again usual monster vague
Generated mnemonic for key finality-provider1 is citizen chair sister suspect fashion opera token more drastic neutral service select wedding shuffle win juice educate cereal wink orchard stand hair click chat
time="2023-08-18T10:28:37Z" level=info msg="successfully created finality provider"
time="2023-08-18T10:28:37Z" level=debug msg="created finality provider" babylon_pub_key=0386b928eedab5e1f6dc7e4334651cca9c1f039589ac6fd14ece12df8e091a07d0 btc_pub_key=021083b0c28491e9660cd252afa9fd36431e93a86adf21801533f365de265de4ba
time="2023-08-18T10:28:38Z" level=info msg="successfully registered finality provider on babylon" bbnPk=0386b928eedab5e1f6dc7e4334651cca9c1f039589ac6fd14ece12df8e091a07d0 txHash=BCB758DAE8A469DAD77925FAFAC41BFAB950BBC5668B91CE90B5F21C751B6BBC
time="2023-08-18T10:28:38Z" level=info msg="Starting thread handling finality provider 0386b928eedab5e1f6dc7e4334651cca9c1f039589ac6fd14ece12df8e091a07d0"
...
```

As these Finality Providers don't have any BTC tokens staked to them, they cannot submit
finality signatures at this point:

```shell
$ docker logs -f finality-provider0
...
time="2023-08-18T10:28:44Z" level=debug msg="received a new block, the finality provider is going to vote" babylon_pk_hex=0386b928eedab5e1f6dc7e4334651cca9c1f039589ac6fd14ece12df8e091a07d0 block_height=5
time="2023-08-18T10:28:44Z" level=debug msg="the finality provider's voting power is 0, skip voting" block_height=5 btc_pk_hex=1083b0c28491e9660cd252afa9fd36431e93a86adf21801533f365de265de4ba
...
```

The Finality Providers are now periodically generating and submitting EOTS randomness to
Babylon:

```shell
$ docker logs -f finality-provider0
...
time="2023-08-18T10:28:44Z" level=info msg="successfully committed public randomness to Babylon" babylon_pk_hex=0386b928eedab5e1f6dc7e4334651cca9c1f039589ac6fd14ece12df8e091a07d0 btc_pk_hex=1083b0c28491e9660cd252afa9fd36431e93a86adf21801533f365de265de4ba last_committed_height=109 tx_hash=015216B602472E6F2BFBECEB40170D037AC4C3B1B795FC9CFB495A3A0416B3DB
...
```

### Staking BTC tokens

Next, one BTC staking request is sent to each Finality Provider through the BTC
Staker daemon. Each request originates from a different BTC public key, and
a 1-1 mapping between BTC public keys and Finality Providers is maintained.

Each request locks 1 million Satoshis from a simnet BTC address and stakes them
to the Finality Provider, for several simnet BTC blocks (specifically, 500 blocks
for the first 2 BTC public keys, and 10 blocks for the last BTC public key).

We can verify the BTC staking requests from the logs of the BTC Staker daemon;
for our example, we will include logs related to one of the staking requests.

```shell
$ docker logs -f btc-staker
...
time="2023-08-18T10:29:00Z" level=info msg="Created and signed staking transaction" btxTxHash=e5aac9570ec4d95a09d9653abc402af0f16570b0f15389aa40d13fa42f6b15cb fee="25000 sat/kb" stakerAddress=bcrt1q6hpknhql2u0fph778rpuqyqcj2hnz365myf5qy stakingAmount=1000000
time="2023-08-18T10:29:00Z" level=info msg="Received new staking request" btcTxHash=e5aac9570ec4d95a09d9653abc402af0f16570b0f15389aa40d13fa42f6b15cb currentBestBlockHeight=116
time="2023-08-18T10:29:00Z" level=info msg="Staking transaction successfully sent to BTC network. Waiting for confirmations" btcTxHash=e5aac9570ec4d95a09d9653abc402af0f16570b0f15389aa40d13fa42f6b15cb confLeft=1
time="2023-08-18T10:29:01Z" level=debug msg="Staking transaction received confirmation" btcTxHash=e5aac9570ec4d95a09d9653abc402af0f16570b0f15389aa40d13fa42f6b15cb confLeft=1
time="2023-08-18T10:29:11Z" level=debug msg="Staking transaction received confirmation" btcTxHash=e5aac9570ec4d95a09d9653abc402af0f16570b0f15389aa40d13fa42f6b15cb confLeft=0
time="2023-08-18T10:29:11Z" level=info msg="BTC transaction has been confirmed" blockHash=12bc4d7faceba664b63acf49b37a3f02e723b0fb591244cfdf4d1766cfb8c269 blockHeight=117 btcTxHash=e5aac9570ec4d95a09d9653abc402af0f16570b0f15389aa40d13fa42f6b15cb
time="2023-08-18T10:29:11Z" level=debug msg="Queuing delegation to be send to babylon" btcTxHash=e5aac9570ec4d95a09d9653abc402af0f16570b0f15389aa40d13fa42f6b15cb btcTxIdx=3 lenQueue=0 limit=100
time="2023-08-18T10:29:11Z" level=debug msg="Inclusion block not deep enough on Babylon btc light client. Scheduling request for re-delivery" btcBlockHash=12bc4d7faceba664b63acf49b37a3f02e723b0fb591244cfdf4d1766cfb8c269 btcTxHash=e5aac9570ec4d95a09d9653abc402af0f16570b0f15389aa40d13fa42f6b15cb depth=0 requiredDepth=1
time="2023-08-18T10:29:31Z" level=debug msg="Queuing delegation to be send to babylon" btcTxHash=e5aac9570ec4d95a09d9653abc402af0f16570b0f15389aa40d13fa42f6b15cb btcTxIdx=3 lenQueue=0 limit=100
time="2023-08-18T10:29:31Z" level=debug msg="Initiating delegation to babylon" btcTxHash=e5aac9570ec4d95a09d9653abc402af0f16570b0f15389aa40d13fa42f6b15cb stakerAddress=bcrt1q6hpknhql2u0fph778rpuqyqcj2hnz365myf5qy
time="2023-08-18T10:29:37Z" level=info msg="BTC transaction successfully sent to babylon as part of delegation" btcTxHash=e5aac9570ec4d95a09d9653abc402af0f16570b0f15389aa40d13fa42f6b15cb
...
```

The following events are occurring here:
- The BTC Staker daemon creates a BTC staking transaction, signs it
  and submits it to the BTC simnet
- The BTC Staker is monitoring the BTC simnet until the staking transaction
  receives `X` confirmations (in our case, `X = 2`)
- The BTC Staker creates and pre-signs a BTC slashing transaction, which will
  be sent to the BTC simnet in case the Finality Provider attacks Babylon
- The BTC Staker submits this transaction to Babylon, so that the covenant can
  pre-sign it too

The delegation has now been created, but is not activated yet. The last step
is for the covenant to also pre-sign the slashing BTC transaction.

Through the covenant daemon logs, we can inspect this event:

```shell
$ docker logs -f covenant
...
time="2023-08-18T10:29:42Z" level=info msg="successfully submit covenant sig over Bitcoin delegation to Babylon" delBtcPk=46748d01a2f00dfabf8be55031932c68dcea5636d47f9e2e3bdc29d36e8b440b txHash=959F16BA3A0D790E70CF486D48BFA3F8753E7A46EE2D79C97CF67D35711C7791 valBtcPubKey=1083b0c28491e9660cd252afa9fd36431e93a86adf21801533f365de265de4ba
...
```

The delegation is now active, and the Finality Provider that received it will be
eligible to submit finality signatures until the delegation expires (i.e. in 500
simnet BTC blocks). From Finality Provider daemon logs:

```shell
$ docker logs -f finality-provider0
...
time="2023-08-18T10:30:09Z" level=info msg="successfully submitted a finality signature to Babylon" babylon_pk_hex=0386b928eedab5e1f6dc7e4334651cca9c1f039589ac6fd14ece12df8e091a07d0 block_height=21 btc_pk_hex=1083b0c28491e9660cd252afa9fd36431e93a86adf21801533f365de265de4ba tx_hash=7BF8200BA71E640036141115AED2EE3D6E74682FDA72CD280722C0A2F06FE537
...
```

### Attacking Babylon and extracting BTC private key

Next, an attack to Babylon is initiated from one of the 3 Finality Providers.
As attack is defined as a Finality Provider submitting a finality signature for a
Babylon block at height X, while they have already submitted a finality
signature for a different (i.e. conflicting) Babylon block at the same height X.

When the Finality Provider attacks Babylon, its Bitcoin private key is extracted
and exposed. The corresponding output of the `make` command looks like the
following:

```shell
Attack Babylon by submitting a conflicting finality signature for a finality provider
{
    "tx_hash": "8F4951C848C59DF9C0EC95E42A3C690DDA8EF0B58DD10DF04038F8368BA8A098",
    "extracted_sk_hex": "1034f95e93f70904fcf59db6acfa8782d3803056ff786b732a73dc298b6ca77b",
    "local_sk_hex": "1034f95e93f70904fcf59db6acfa8782d3803056ff786b732a73dc298b6ca77b"
}
Finality Provider with Bitcoin public key 0386b928eedab5e1f6dc7e4334651cca9c1f039589ac6fd14ece12df8e091a07d0 submitted a conflicting finality signature for Babylon height 23; the Finality Provider's private BTC key has been extracted and the Finality Provider will now be slashed
```

Now that the Finality Provider's private key has been exposed, the only remaining
step is activating the BTC slashing transaction. This transaction will
transfer all the BTC tokens staked to this Finality Provider to a simnet BTC burn address
specified in Babylon's genesis file. The Vigilante Monitor daemon is responsible
for this, and through its logs we can inspect this event:

```shell
$ docker logs -f vigilante-monitor
...
time="2023-08-18T10:30:25Z" level=info msg="start slashing BTC finality provider 1083b0c28491e9660cd252afa9fd36431e93a86adf21801533f365de265de4ba" module=slasher
time="2023-08-18T10:30:25Z" level=debug msg="signed and assembled witness for slashing tx of BTC delegation 46748d01a2f00dfabf8be55031932c68dcea5636d47f9e2e3bdc29d36e8b440b under BTC finality provider 1083b0c28491e9660cd252afa9fd36431e93a86adf21801533f365de265de4ba" module=slasher
time="2023-08-18T10:30:25Z" level=info msg="successfully submitted slashing tx (txHash: 424f40e29703e010880138d08eaf0e0950fed954a383d4fe470eee20724cd6a7) for BTC delegation 46748d01a2f00dfabf8be55031932c68dcea5636d47f9e2e3bdc29d36e8b440b under BTC finality provider 1083b0c28491e9660cd252afa9fd36431e93a86adf21801533f365de265de4ba" module=slasher
...
```

### Withdraw expired staked BTC tokens

The last BTC staking request that was placed by the BTC Staker daemon had a
simnet BTC token time-lock of 10 BTC blocks. This is done on purpose, so that
the staking period expires quickly and the withdrawal of expired BTC staked
tokens can be demonstrated.

The final action of the showcasing script is to withdraw these BTC tokens.
The BTC Staker daemon submits a simnet BTC transaction to this end - we can
verify this through its logs:

```shell
$ docker logs -f btc-staker
...
time="2023-08-18T10:31:55Z" level=info msg="Successfully sent transaction spending staking output" destAddress=bcrt1qyrq6mayver4jj3rtluzjrz5338melpa57f35s0 fee="0.000025 BTC" spendTxHash=336b85d3d0b18dacdf962382714ab035d5d01e743d4d19678320e7ab272173d1 spendTxValue="0.009975 BTC" stakeValue="0.01 BTC" stakerAddress=bcrt1qyrq6mayver4jj3rtluzjrz5338melpa57f35s0
time="2023-08-18T10:32:24Z" level=info msg="BTC Staking transaction successfully spent and confirmed on BTC network" btcTxHash=223312387fa7d8448d642492d3fe3f1e2f9e23798b89ad13b6fc7ed74707e490
...
```

After the transaction is confirmed on BTC simnet, the withdrawal of the BTC
tokens is complete.

### Early unbond staked BTC tokens

In this scenario, we demonstrate early unbonding and withdrawal BTC tokens before the staking period elapses.
The script first sends an early unbond tx request. After waiting for the staking tx to be expired a withdrawal request is then submitted to retrieve the staked BTC.

```shell
$ docker logs -f btc-staker
...
time="2024-06-13T11:22:56Z" level=debug msg="Unbonding transaction received confirmation" confLeft=0 unbondingTxHash=9190dfbb6e8071f05a0abc96ea51f21972f76b86c78e6be0a3002f983e5b2665
time="2024-06-13T11:22:56Z" level=debug msg="Unbonding tx confirmed" blockHash=59a57a822b53679984dae86f8345877f01c6f53f30a1a3f317670b8b270bec6c blockHeight=143 stakingTxHash=da508826931228a1143e66667778d945161c73ebb0222d951a762028f2e94bb0 unbondingTxHash=9190dfbb6e8071f05a0abc96ea51f21972f76b86c78e6be0a3002f983e5b2665
time="2024-06-13T11:26:10Z" level=debug msg="Received staking event" event=SPEND_STAKE_TX_CONFIRMED_ON_BTC eventId=da508826931228a1143e66667778d945161c73ebb0222d951a762028f2e94bb0
time="2024-06-13T11:26:10Z" level=debug msg="Processed staking event" event=SPEND_STAKE_TX_CONFIRMED_ON_BTC eventId=da508826931228a1143e66667778d945161c73ebb0222d951a762028f2e94bb0
...
```
After the transaction is confirmed on BTC simnet, the process of early unbonding staked BTC
tokens is complete.


## Interacting with the BTC Staking Protocol manually

We will now proceed to demonstrate how to perform all the aforementioned
BTC Staking operations that the showcasing script performed in a manual manner.

### Generating a new Finality Provider manually

To achieve this, we need to take a shell into the Finality Provider Docker container
and interact with the daemon through its CLI util, `fpd`.

```shell
# Take shell into the running Finality Provider daemon
$ docker exec -it finality-provider sh
# Create a Finality Provider named `my_finality_provider`. This Finality Provider holds a BTC
# public key (where the staked tokens will be sent to) and a Babylon account
# (where the Babylon reward tokens will be sent to). The public keys of both are
# visible from the command output.
~ fpd create-finality-provider --key-name my_finality_provider
{
    "babylon_pk": "0251259b5c88d6ac79d86615220a8111ebb238047df0689357274f004fba3e5a89",
    "btc_pk": "f6eae95d0e30e790bead4e4359a0ea596f2179a10f96dcedd953f07331918ca7"
}
# Register the Finality Provider with Babylon. Now, the Finality Provider is ready to receive
# delegations. The output contains the hash of the finality provider registration
# Babylon transaction.
~ fpd register-finality-provider --key-name my_finality_provider
{
    "tx_hash": "800AE5BBDADE974C5FA5BD44336C7F1A952FAB9F5F9B43F7D4850BA449319BAA"
}
# List all the Finality Providers managed by the Finality Provider daemon. The `status`
# field can receive the following values:
# - `1`: The Finality Provider is active and has received no delegations yet
# - `2`: The Finality Provider is active and has staked BTC tokens
# - `3`: The Finality Provider is inactive (i.e. had staked BTC tokens in the past but
#   not anymore OR has been slashed)
# The `last_committed_height` field is the Babylon height up to which the
# Finality Provider has committed sufficient EOTS randomness
~ fpd list-finality-providers
{
    "finality-providers": [
        ...
        {
            "babylon_pk_hex": "0251259b5c88d6ac79d86615220a8111ebb238047df0689357274f004fba3e5a89",
            "btc_pk_hex": "f6eae95d0e30e790bead4e4359a0ea596f2179a10f96dcedd953f07331918ca7",
            "last_committed_height": 265,
            "status": 1
        }
    ]
}
```

### Staking BTC tokens manually

Continuing from the previous section, we had already created a Finality Provider
with BTC public key hex
`f6eae95d0e30e790bead4e4359a0ea596f2179a10f96dcedd953f07331918ca7` and Babylon
public key hex
`0251259b5c88d6ac79d86615220a8111ebb238047df0689357274f004fba3e5a89`.

Now, we will stake 1 million Satoshis to this Finality Provider from a funded simnet
BTC address, for 100 Bitcoin blocks. To achieve this, we need to take shell into
the BTC Staker container and interact with the daemon through its CLI utility,
`stakercli`.

```shell
# Take shell into the running BTC Staker daemon
$ docker exec -it btc-staker sh
# Obtain a simnet BTC address from the bitcoind node that BTC Staker daemon is
# currently connected to
~ delegator_btc_addr=$(stakercli dn list-outputs | \
jq -r ".outputs[].address" | shuf -n 1)
# Submit a BTC staking transaction as specified above, using the Finality Provider's
# BTC public key hex
~ stakercli daemon stake --staker-address $delegator_btc_addr \
--staking-amount 1000000 \
--finality-providers-pks f6eae95d0e30e790bead4e4359a0ea596f2179a10f96dcedd953f07331918ca7 \
--staking-time 100
{
    "tx_hash": "35650a6b7d0294f457b6ba3eaed3f04d9c4f07de392729f7051720136e0586fa"
}
```

### Attacking Babylon and extracting BTC private key manually

Continuing from the previous section, we had already created a Finality Provider
with BTC public key hex
`f6eae95d0e30e790bead4e4359a0ea596f2179a10f96dcedd953f07331918ca7` and Babylon
public key hex
`0251259b5c88d6ac79d86615220a8111ebb238047df0689357274f004fba3e5a89`.

Now, we will submit a conflicting finality signature for this Finality Provider, for the
latest Babylon height that they have submitted a finality signature. To achieve
this, we need to take shell into the Finality Provider container and interact with
the daemon through its CLI utility, `fpd`.

```shell
# Take shell into the running Finality Provider daemon
$ docker exec -it finality-provider sh
# Find the latest height for which the Finality Providers have submitted finality
# signatures
~ attackHeight=$(fpd ls | jq -r ".finality_providers[].last_voted_height" | sort -nr | head -n 1)
# Add a signature for a conflicting block using the Finality Provider's Babylon public
# key; the command will by default vote for a predefined conflicting block.
# To override the predefined conflicting block, the flag `--last-commit-hash`
# can be utilized.
~ fpd add-finality-sig --height $attackHeight \
--babylon-pk 0251259b5c88d6ac79d86615220a8111ebb238047df0689357274f004fba3e5a89
{
    "tx_hash": "A7D69335C19C3E7F312A5C4BD71FBFC1DD27B863A13C8AD3CABBCCFDCA218461",
    "extracted_sk_hex": "1b50114c7b7a2982434abe8e4f0c9db578b5e847359aea98bad8212a67aef838",
    "local_sk_hex": "1b50114c7b7a2982434abe8e4f0c9db578b5e847359aea98bad8212a67aef838"
}
```

### Withdraw staked BTC tokens manually

Up to now, we have created a Finality Provider, staked tokens to it and submitted
a conflicting finality signature for it; this led to its slashing. As a result,
we can no longer reuse this Finality Provider.

For this example, the steps from sections
[Generating a new Finality Provider manually](#generating-a-new-finality-provider-manually)
and
[Staking BTC tokens manually](#staking-btc-tokens-manually) should be
repeated. This time, the manual BTC staking request should last for **10 BTC
blocks** - so that it will expire quickly enough for us to unbond its tokens
(in up to 3 minutes, given that our simnet's BTC block creation rate is 10
seconds). After this amount of time has passed, we can now withdraw the BTC
tokens from the expired delegation.

To withdraw the tokens, we need to take shell into the same BTC Staker container
and interact with the daemon through its CLI utility, `stakercli`.

```shell
# Take shell into the running BTC Staker daemon
$ docker exec -it btc-staker sh
# Let's assume that the BTC staking transaction hash that was outputted by
# the `stakercli daemon stake` command is the following
$ btcStkTxHash=2303fa60324ac8d049de1c423073a3f577f64ae5a83b0b054820b2b01735cc09
# Submit a BTC unbonding transaction by re-using this same hash
~ stakercli daemon unstake --staking-transaction-hash $btcStkTxHash
{
    "tx_hash": "2303fa60324ac8d049de1c423073a3f577f64ae5a83b0b054820b2b01735cc09",
    "tx_value": "997500"
}
```
