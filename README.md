# Babylon local deployment

This repository contains all the necessary artifacts and instructions to set up
and run a Babylon network locally, using several different deployment scenarios.

## Prerequisites

1. Install Docker Desktop

    All components are executed as Docker containers on the local machine, so a
    local Docker installation is required. Depending on your operating system,
    you can find relevant instructions [here](https://docs.docker.com/desktop/).

2. Install `make`

    Required to build the service binaries. One tutorial that can be followed
    is [this](https://sp21.datastructur.es/materials/guides/make-install.html).

3. Set up an SSH key to GitHub

    Create a **non passphrase-protected** SSH key and add it to GitHub according
    to the instructions
    [here](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account).

    Export an env var `BBN_PRIV_DEPLOY_KEY` that points to the ssh private key with github access.

    ```shell
    export BBN_PRIV_DEPLOY_KEY=FULL_PATH_TO_PRIVATE_KEY/.ssh/id_ed25519
    ```

    A more detailed explanation can be found [here](babylon-api/README.md#installation).

4. Clone the repository and initialize git submodules

    The aforementioned components are included in the repo as git submodules, so
    they need to be initialized accordingly.

    ```shell
    git clone git@github.com:babylonlabs-io/babylon-deployment.git
    git submodule init && git submodule update
    ```

### Appendix: Babylon API prerequisites

If you're interested in running Babylon API (an in-house blockchain data
aggregator), you need to take the following additional actions.

1. Export an env var containing a CoinMarketCap token (can be obtained from
    [here](https://coinmarketcap.com/academy/article/register-for-coinmarketcap-api))

    ```shell
    export CMC_PRO_API_KEY=XXX
    ```

2. For the standalone [API deployment](deployments/api) that connects to the
    Babylon Devnet, complete the following items:

    - Export env vars containing credentials for the signet BTC node used by
      the Babylon Devnet (can be obtained through
      [here](https://babylon-chain.atlassian.net/wiki/spaces/BABYLON/pages/173081551/Credential+management))
        ```shell
        export BTC_RPC_USER=XXX
        export BTC_RPC_PASS=XXX
        ```

    - Connect to the Babylon Devnet VPN (VPN config can be obtained through
      [here](https://babylon-chain.atlassian.net/wiki/spaces/BABYLON/pages/173081551/Credential+management))

## Deployment scenarios

Every deployment scenario lives under the [deployments](deployments/) directory,
on a dedicated subdirectory.  The following scenarios are currently available:
- [BTC Staking Phase-1 System (BTC backend: bitcoind)](deployments/btcstaking-phase1-bitcoind):
  Spawns a Babylon BTC Staking Phase-1 system showcasing the lifecycle of
  Staking requests, backed by a bitcoind-based BTC simnet
- [BTC Staking (BTC backend: bitcoind)](deployments/btcstaking-bitcoind):
  Spawns a Babylon network showcasing Babylon's BTC Staking and BTC Timestamping protocols, backed by
  a bitcoind-based BTC simnet
- [BTC Timestamping (BTC backend: bitcoind)](deployments/timestamping-bitcoind):
  Spawns a Babylon network featuring Babylon's BTC Timestamping protocol,
  backed by a bitcoind-based BTC simnet
- [BTC Timestamping (BTC backend: btcd)](deployments/timestamping-btcd):
  Spawns a Babylon network featuring Babylon's BTC Timestamping protocol,
  backed by a btcd-based BTC simnet
- [Phase 1 Integration (BTC backend: bitcoind)](deployments/phase1-integration-bitcoind):
  Spawns a Babylon BTC Timestamping network testing Babylon's Phase 1 Integration with a gaiad
  testnet, backed by a bitcoind-based BTC simnet
- [Phase 2 Integration (BTC backend: bitcoind)](deployments/phase2-integration-bitcoind):
  Spawns a Babylon BTC Timestamping network testing Babylon's Phase 2 Integration with a wasmd
  testnet, backed by a bitcoind-based BTC simnet
- [Faucet](deployments/faucet):
  Spawns a Babylon network along with a Discord-based Faucet
- [BTC Discord Faucet](deployments/btc-discord-faucet):
  Spawns a Bitcoin regtest node along with a Discord-based BTC Faucet
- [API](deployments/api):
  Spawns Babylon network APIs along with rpc-poller. Utilise devnet enviroments for gathering babylonchain and BTC data. Write operations from API has no effect

### Subdirectory structure and deployment process

Each deployment scenario subdirectory follows the structure indicated below:

```shell
├── artifacts
│   ├── docker-compose.yml
│   ├── ...
├── Makefile
├── post-deployment.sh
└── pre-deployment.sh
```

The Makefile generally adheres to the following template:

```shell
build-deployment-X:
...

start-deployment-X:
...

stop-deployment-X:
...
```

Initiating a deployment is achieved through `make start-deployment-X`. The
following events will occur automatically:

- Stop any existing deployment (by invoking the `make stop-deployment-X`
  command)
- (Re)Build Docker images for all the underlying services (by invoking the
  `make build-deployment-X` command)
- Execute the `pre-deployment.sh` bash script that will:
  - Create a genesis file used to bootstrap the Babylon network
  - Prepare service configuration originally placed under the `artifacts` folder
- Execute a `docker compose` command that will spin up all the required services
  for the network as Docker containers; the `docker-compose.yml` file is also
  under the `artifacts` folder
- Execute the `post-deployment.sh` bash script (if it exists) that will generate
  funded Babylon keyrings for the services that need to send Babylon
  transactions

## Deploying a Babylon network with a desired deployment scenario

The repository hosts a central [Makefile](Makefile) which places calls to all
the underlying Makefiles. It will be utilized to start deployments directly
from the repo root.

The whole deployment process can take 15-20 minutes, depending on the deployment
scenario and the available computing and networking resources.

Below, we document how to deploy each scenario. The following guidelines should
be followed:
- **For Linux systems, the make commands must be prefixed with `sudo`.**
- After having deployed a deployment scenario `X`, make sure to stop it through
  the corresponding `make` command that will be designated below before
  switching to another deployment scenario `Y`.

### BTC Staking Phase-1 System (BTC backend: bitcoind)

To start the system **along with executing an
[additional post-deployment script](deployments/btcstaking-phase1-bitcoind/README.md#inspecting-the-btc-staking-phase-1-system-demo)
that will showcase the lifecycle of Staking requests inside the Phase-1
system**, execute the following:

```shell
make start-deployment-btcstaking-phase1-bitcoind-demo
```

Alternatively, to just start the system:

```shell
make start-deployment-btcstaking-phase1-bitcoind
```

To stop the system:

```shell
make stop-deployment-btcstaking-phase1-bitcoind
```

### BTC Staking (BTC backend: bitcoind)

To start the network **along with executing an
[additional post-deployment script](deployments/btcstaking-bitcoind/README.md#inspecting-the-btc-staking-protocol-demo)
that will showcase the full lifecycle of Babylon's BTC Staking Protocol**,
execute the following:

```shell
make NUM_FINALITY_PROVIDERS=3 start-deployment-btcstaking-bitcoind-demo
```

where:

- `NUM_FINALITY_PROVIDERS` is the number of Finality Providers that will be
  created and used throughout the demo. We recommend utilizing 3 Finality
  Providers.

Alternatively, to just start the network:

```shell
make start-deployment-btcstaking-bitcoind
```

To stop the network:

```shell
make stop-deployment-btcstaking-bitcoind
```

### BTC Timestamping (BTC backend: bitcoind)

To start the network:

```shell
make start-deployment-timestamping-bitcoind
```

To stop the network:

```shell
make stop-deployment-timestamping-bitcoind
```

### BTC Timestamping (BTC backend: btcd)

To start the network:

```shell
make start-deployment-timestamping-btcd
```

To stop the network:

```shell
make stop-deployment-timestamping-btcd
```

### Phase 1 Integration (BTC backend: bitcoind)

To start the network:

```shell
make start-deployment-phase1-integration-bitcoind
```

To stop the network:

```shell
make stop-deployment-phase1-integration-bitcoind
```

### Phase 2 Integration (BTC backend: bitcoind)

To start the network:

```shell
make start-deployment-phase2-integration-bitcoind
```

To stop the network:

```shell
make stop-deployment-phase2-integration-bitcoind
```

### Faucet

To start the network:

```shell
make start-deployment-faucet
```

To stop the network:

```shell
make stop-deployment-faucet
```

### BTC Discord Faucet

To start the network:

```shell
make start-deployment-btc-discord-faucet
```

To stop the network:

```shell
make stop-deployment-btc-discord-faucet
```

### API

To start the api services:

```shell
make start-deployment-api
```

To stop the api services:

```shell
make stop-deployment-api
```
