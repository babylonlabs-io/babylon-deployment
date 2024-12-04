# Local Deployment

## Requirements

- [bitcoind](https://bitcoin.org/en/full-node) binaries (on your path)
- [btcd](https://github.com/btcsuite/btcd/tree/master?tab=readme-ov-file#installation) binaries (on your path)
- [jq](https://jqlang.github.io/jq/download/)
- [perl](https://www.perl.org/get.html)

## Start paths

The following commands will start a babylond chain locally with hardcoded ports.
Stop any other running chain or docker container before start running commands.

### Babylon Export and Start with BTC Delegations

Starts all the processes necessary to have a btc delegation active, stops the
chain process, export the genesis, setup a new chain with new chain id
copy some data from the exported genesis into the new one and start a new chain
with active btc delegations from start.

```shell
make bbn-start-btc-del-stop-exportgen-start
```

- Wait for the first bbn chain to get a active btc del

```shel
Current active dels: 0, waiting to reach 1
Current active dels: 0, waiting to reach 1
...
```

- When the first active btc del is reached, it kills the bbn chain, exports and starts new one
- You should see a second bbn chain start with active btc del

```shell
babylond q btcstaking btc-delegations active -o json | jq
```

### Single BBN Node with BTC delegation

Starts all the process necessary to have a babylon chain running with active btc delegation.

```shell
make start-bbn-with-btc-delegation
```

- Wait for about a minute and query

```shell
babylond q btcstaking btc-delegations active -o json | jq
```

- You should see a btc delegation active, if nothing is founded check pending btc delegations `babylond q btcstaking btc-delegations pending`

### Stand-alone scripts

#### Start a single-node-chain

Run `./starters/start-babylond-single-node.sh` to create a babylon chain with a single node.

#### Add a new validator

With a running chain, create a new validator by running `./starters/start-babylond-new-validator.sh`,
it creates a new validator by using the checkpoint wrapping create validator transaction
`babylond tx checkpointing create-validator`, it submits the wrapped msg which then
is put into a queue to be run at the end of an epoch, after the epoch is passed, if
everything was successfully processed, you should be able to see a new validator
under `babylond q staking validators`

## Upgrades

This section cover upgrades tested locally with a single node

### Upgrade v1

This upgrade adds BTC headers to the chain, and execute
the following steps:

1. Start bitcoind
2. Start single node babylon chain with base BTC Header
as block zero from bitcoind
3. Run upgrade gov prop for software upgrade
4. Vote Yes
5. Wait for upgrade height to be reached
6. Stop the chain
7. Produces a lot of blocks from bitcoind
8. Generates a new file with BTC headers to `babylon/app/upgrades/v1/data_btc_headers.go`
9. Generates a BTC delegation phase-1 transaction
10. Builds new babylond with the expected upgrade code
11. Start the chain with upgrade to apply
12. Check if the new BTC headers were correctly created
13. Check if the new FPs were correctly inserted

```shell
make bbn-upgrade-v1
```

## Tear down

Kills all the process that were preivously started and deletes the data folder

```shell
make stop-all
```
