# Local Deployment

## Requirements

- [bitcoind](https://bitcoin.org/en/full-node) binaries (on your path)
- [btcd](https://github.com/btcsuite/btcd/tree/master?tab=readme-ov-file#installation) binaries (on your path)
- [jq](https://jqlang.github.io/jq/download/)
- [perl](https://www.perl.org/get.html)

## Start paths

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

## Upgrades

This section cover upgrades tested locally with a single node

### Upgrade vanilla

This upgrade only adds a new finality provider to a the chain, and execute
the following steps:

1. Start single node babylon chain
2. Run upgrade gov prop for software upgrade
3. Vote Yes
4. Wait for upgrade height to be reached
5. Stop the chain
6. Builds new babylond with the expected upgrade code
7. Start the chain with upgrade to apply
8. Check if a new finality provider was added

```shell
make bbn-upgrade-vanilla
```

### Upgrade Signet Launch

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
8. Generates a new file with BTC headers to `babylon/app/upgrades/signetlaunch/data_btc_headers.go`
9. Builds new babylond with the expected upgrade code
10. Start the chain with upgrade to apply
11. Check if the new BTC headers were correctly created

```shell
make bbn-upgrade-signet
```

## Tear down

Kills all the process that were preivously started and deletes the data folder

```shell
make stop-all
```
