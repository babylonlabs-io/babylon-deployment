# BTC Staking deployment (BTC backend: bitcoind)

## Components

The to-be-deployed Babylon network that features Babylon's BTC Staking and BTC
Timestamping protocols comprises the following components:

- 2 **Babylon Finality Provider Nodes** running the base Tendermint consensus and
  producing Tendermint-confirmed Babylon blocks
- 3 **Finality Provider** daemons: Hosts one or more Finality Providers which commit
  public randomness and submit finality signatures for Babylon blocks to Babylon
- **BTC Staker** daemon: Enables the staking of BTC tokens to PoS chains by
  locking BTC tokens on the BTC network and submitting a delegation to a
  dedicated Finality Provider; the daemon connects to a BTC wallet that manages
  multiple private/public keys and performs staking requests from BTC public
  keys to dedicated Finality Providers
- **BTC Covenant Emulation** daemon: Pre-signs the BTC slashing
  transaction to enforce that malicious stakers' stake will be sent to a
  pre-defined burn BTC address in case they attack Babylon
- **Vigilante Monitor** daemon: Detects attacks to Babylon
- **Vigilante Submitter** daemon: Aggregates and checkpoints Babylon epochs (a
  group of `X` Babylon blocks) to the BTC network
- **Vigilante Reporter** daemon: Keeps track of the BTC network's state in
  Babylon and detects Babylon checkpoints that have received a BTC timestamp
  (i.e. have been confirmed in BTC)
- **Vigilante BTC Staking Tracker** daemon: Tracks the state of every BTC delegation
  on the BTC network and reports important events (e.g., activation, unbondings)
  to the Babylon network; also submits slashing transactions in case of
  double-signing offences
- A **BTC simnet** acting as the BTC network, operated through a bitcoind node

### Expected Docker state post-deployment

The following containers should be created as a result of the `make` command
that spins up the network:

```shell
[+] Running 14/14
 ✔ Container eotsmanager          Removed                                                           0.0s 
 ✔ Container vigilante-submitter  Removed                                                           0.0s 
 ✔ Container vigilante-monitor    Removed                                                           0.0s 
 ✔ Container vigilante-bstracker  Removed                                                           0.0s 
 ✔ Container covenant-emulator    Removed                                                           0.0s 
 ✔ Container btc-staker           Removed                                                           0.0s 
 ✔ Container babylondnode1        Removed                                                           0.0s 
 ✔ Container vigilante-reporter   Removed                                                           0.0s 
 ✔ Container finality-provider1   Removed                                                           0.0s 
 ✔ Container finality-provider2   Removed                                                           0.0s 
 ✔ Container finality-provider0   Removed                                                           0.0s 
 ✔ Container bitcoindsim          Removed                                                          10.4s 
 ✔ Container babylondnode0        Removed                                                           0.0s 
 ✔ Network artifacts_localnet     Removed                                                           0.3s
```

## Inspecting the BTC Staking Protocol demo

Deploying the BTC Staking network through the `make` subcommand
`start-deployment-btcstaking-bitcoind-demo` leads to the execution of an
additional post-deployment [script](btcstaking-demo.sh) that showcases the
complete lifecycle of Babylon's BTC Staking protocol.

We will now analyze each step that is executed as part of the BTC
Staking showcasing script - more specifically, how it is performed and its
outcome for the Babylon and the BTC network respectively.

### Creating and registering Finality Providers

The Finality Providers have simnet BTC tokens staked to them. The Finality
Providers that have staked tokens can submit finality signatures.

Through the Finality Provider's daemon logs we can verify the above (only 1
Finality Provider is included in all the example outputs in this section for
simplicity):

```shell
$ docker logs -f finality-provider0
...
2025-01-30T14:14:22.040073Z	info	Successful transaction	{"chain_id": "chain-test", "gas_used": 77319, "fees": "174339ubbn", "fee_payer": "\ufffd$\ufffd\ufffd\ufffdzk\ufffdif\ufffd\u000fcYrl\ufffd\ufffd\ufffd@", "height": 13, "msg_types": ["/babylon.btcstaking.v1.MsgCreateFinalityProvider"], "tx_hash": "188D3A0690E3DEDF078231226586B3AF6730657F04E007DF15226B2066A914B9"}
2025-01-30T14:14:22.040102Z	info	successfully registered finality-provider on babylon	{"btc_pk": "84989a58a91314077679f3529601be9908381803d088e5fb0769af711b7ee49e", "fp_addr": "bbn1nvjwpqw00f46u6txsv8kxktjdjrd96zq64hkup", "txHash": "188D3A0690E3DEDF078231226586B3AF6730657F04E007DF15226B2066A914B9"}
2025-01-30T14:14:22.051044Z	info	successfully saved the finality-provider	{"eots_pk": "84989a58a91314077679f3529601be9908381803d088e5fb0769af711b7ee49e", "addr": "bbn1nvjwpqw00f46u6txsv8kxktjdjrd96zq64hkup"}
2025-01-30T14:14:22.054427Z	info	determined poller starting height	{"pk": "84989a58a91314077679f3529601be9908381803d088e5fb0769af711b7ee49e", "start_height": 39, "finality_activation_height": 39, "last_voted_height": 0, "last_finalized_height": 0, "highest_voted_height": 0}
2025-01-30T14:14:22.054485Z	info	starting the finality provider instance	{"pk": "84989a58a91314077679f3529601be9908381803d088e5fb0769af711b7ee49e", "height": 39}
...
```

As these Finality Providers don't have any BTC tokens staked to them, they
cannot submit finality signatures at this point.


The Finality Providers are now periodically generating and submitting EOTS randomness to
Babylon:

```shell
$ docker logs -f finality-provider0
...
2025-01-30T14:14:27.059040Z	debug	the finality-provider should commit randomness	{"pk": "84989a58a91314077679f3529601be9908381803d088e5fb0769af711b7ee49e", "tip_height": 13, "last_committed_height": 0}
2025-01-30T14:14:32.594667Z	info	successfully committed public randomness to the consumer chain	{"pk": "84989a58a91314077679f3529601be9908381803d088e5fb0769af711b7ee49e", "tx_hash": "FDC9E242D88FAF86214011996129D256930EAFE36A50182407342E1F03421F5F"}
...
```

### Staking BTC tokens

Next, one BTC staking request is sent to each Finality Provider through the BTC
Staker daemon. Each request originates from a different BTC public key, and
a 1-1 mapping between BTC public keys and Finality Providers is maintained.

Each request locks 1 million Satoshis from a simnet BTC address and stakes them
to the Finality Provider, for several simnet BTC blocks (specifically, 500 blocks
for the first 2 BTC public keys, and 10 blocks for the last BTC public key).

The following events are occurring here:
- The BTC Staker daemon creates a BTC staking transaction, signs it and sends it
  to the Babylon network for verification. The daemon also includes pre-signed
  unbonding and slashing transactions.
- The Covenant Emulator queries for delegations pending verification and spots
  this one; it verifies that all the transactions are in accordance with the
  BTC Staking Protocol and submits a verification on-chain
- The BTC Staker detects the verification and sends the staking transaction to
  the BTC Simnet
- The Vigilante BTC Staking Tracker starts tracking the staking transaction;
  it is monitoring the BTC simnet until the staking transaction receives `X`
  confirmations (in our case, `X = 2`)
- The Vigilante BTC Staking Tracker submits the BTC inclusion proof to Babylon
- Babylon marks the BTC delegation as active

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
As attack is defined as a Finality Provider submitting a finality signature for
a Babylon block hash at height X, while they have already submitted a finality
signature for a different (i.e. conflicting) Babylon block hash at the same
height X.

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

Now that the Finality Provider's private key has been exposed, the only
remaining step is activating the BTC slashing transaction. This transaction will
transfer a fraction of the BTC tokens staked to this Finality Provider to a
simnet BTC burn address specified by the BTC Staking Protocol. The Vigilante
BTC Staking Tracker daemon is responsible for this, and through its logs we can
inspect this event:

```shell
$ docker logs -f vigilante-bstracker
...
2025-01-30T14:17:54.832918Z	info	new equivocating babylon finality provider 84989a58a91314077679f3529601be9908381803d088e5fb0769af711b7ee49e to be slashed	{"module": "btcstaking-tracker", "module": "slasher"}
2025-01-30T14:17:54.833054Z	info	slashing finality provider 84989a58a91314077679f3529601be9908381803d088e5fb0769af711b7ee49e	{"module": "btcstaking-tracker", "module": "slasher"}
2025-01-30T14:17:54.833082Z	info	start slashing finality provider 84989a58a91314077679f3529601be9908381803d088e5fb0769af711b7ee49e	{"module": "btcstaking-tracker", "module": "slasher"}
2025-01-30T14:17:54.838431Z	debug	signed and assembled witness for slashing tx of unbonded BTC delegation b9888f79f98fdeefdf5ad2661b3cf2a4ce9c7e4b0cb9dd4026c57ef67bb114b9 under finality provider 84989a58a91314077679f3529601be9908381803d088e5fb0769af711b7ee49e	{"module": "btcstaking-tracker", "module": "slasher"}
2025-01-30T14:17:54.840301Z	info	successfully submitted slashing tx (txHash: c695237f886d8ddc071bae211416e4e8b1f904fb7ab7ca5e3f58d6dab88deec6) for BTC delegation b9888f79f98fdeefdf5ad2661b3cf2a4ce9c7e4b0cb9dd4026c57ef67bb114b9 under finality provider 84989a58a91314077679f3529601be9908381803d088e5fb0769af711b7ee49e	{"module": "btcstaking-tracker", "module": "slasher"}
2025-01-30T14:17:54.841256Z	info	successfully slash BTC delegation with staking tx hash 01000000019ad5af149e570aead3472fb2fe906e79fabad0467951be03331bf8768c539d880100000000ffffffff0240420f00000000002251208f322682bc76ddf09eeb926c3a8d80e97473f91b16932b9212bed59b557436e2cf788b3b00000000160014a2d7a25419c8e0952848c3136e95c8b4cb2e8cf300000000 under finality provider 84989a58a91314077679f3529601be9908381803d088e5fb0769af711b7ee49e	{"module": "btcstaking-tracker", "module": "slasher"}
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

In this scenario, we demonstrate early unbonding and withdrawal of BTC tokens
before the staking period elapses. The script first sends an early unbonding tx
request. After waiting for the staking tx to be expired a withdrawal request is
then submitted to retrieve the staked BTC.

```shell
$ docker logs -f btc-staker
...
time="2024-06-13T11:22:56Z" level=debug msg="Unbonding transaction received confirmation" confLeft=0 unbondingTxHash=9190dfbb6e8071f05a0abc96ea51f21972f76b86c78e6be0a3002f983e5b2665
time="2024-06-13T11:22:56Z" level=debug msg="Unbonding tx confirmed" blockHash=59a57a822b53679984dae86f8345877f01c6f53f30a1a3f317670b8b270bec6c blockHeight=143 stakingTxHash=da508826931228a1143e66667778d945161c73ebb0222d951a762028f2e94bb0 unbondingTxHash=9190dfbb6e8071f05a0abc96ea51f21972f76b86c78e6be0a3002f983e5b2665
time="2024-06-13T11:26:10Z" level=debug msg="Received staking event" event=SPEND_STAKE_TX_CONFIRMED_ON_BTC eventId=da508826931228a1143e66667778d945161c73ebb0222d951a762028f2e94bb0
time="2024-06-13T11:26:10Z" level=debug msg="Processed staking event" event=SPEND_STAKE_TX_CONFIRMED_ON_BTC eventId=da508826931228a1143e66667778d945161c73ebb0222d951a762028f2e94bb0
...
```
After the transaction is confirmed on BTC simnet, the processing of the early
unbonding is finished.
