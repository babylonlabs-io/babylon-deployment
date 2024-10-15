DOCKER := $(shell which docker)
GIT_TOPLEVEL := $(shell git rev-parse --show-toplevel)
NUM_FINALITY_PROVIDERS := 3

build-bitcoindsim:
	$(MAKE) -C $(GIT_TOPLEVEL)/contrib/images bitcoindsim

build-babylond:
	$(MAKE) -C $(GIT_TOPLEVEL)/babylon/contrib/images babylond

build-vigilante:
	$(MAKE) -C $(GIT_TOPLEVEL)/vigilante build-docker

build-btc-staker:
	$(MAKE) -C $(GIT_TOPLEVEL)/btc-staker build-docker

build-finality-provider:
	$(MAKE) -C $(GIT_TOPLEVEL)/finality-provider build-docker

build-covenant-emulator:
	$(MAKE) -C $(GIT_TOPLEVEL)/covenant-emulator build-docker

build-deployment-btcstaking-bitcoind: build-babylond build-bitcoindsim build-vigilante build-btc-staker build-finality-provider build-covenant-emulator

start-deployment-btcstaking-bitcoind: stop-deployment-btcstaking-bitcoind build-deployment-btcstaking-bitcoind
	NUM_FINALITY_PROVIDERS=$(NUM_FINALITY_PROVIDERS) ./pre-deployment.sh
	docker compose -f artifacts/docker-compose.yml up -d
	NUM_FINALITY_PROVIDERS=$(NUM_FINALITY_PROVIDERS) ./post-deployment.sh

start-deployment-btcstaking-bitcoind-demo: start-deployment-btcstaking-bitcoind
	NUM_FINALITY_PROVIDERS=$(NUM_FINALITY_PROVIDERS) ./btcstaking-demo.sh

stop-deployment-btcstaking-bitcoind:
	docker compose -f artifacts/docker-compose.yml down
	rm -rf $(CURDIR)/.testnets
